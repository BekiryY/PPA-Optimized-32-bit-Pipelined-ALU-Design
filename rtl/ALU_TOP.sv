module ALU_TOP(
    input clk,
    input reset_n,

    //operands & opcode
    input [31:0] A,
    input [31:0] B,
    input [4:0] CMD,

    //performance control
    input idle,
    input [1:0] branch,
    input low_power,
    //low power table
    //0 - normal (upto 1.66GHZ)
    //1 - low power (upto 120MHZ)

    //outputs
    output wire [31:0] Y,
    output logic [31:0] result_aux,
    output logic [7:0] flag_reg
);
//SHIFTER + LOGIC BLOCK + MULT32 + ADDER32
//   7    +      8      +   1    +   6    TOTAL OF 22FUNCS

//-------------------INSTRUCTION TABLE---------------------------
//Opcode	Operation	Instruction	    Description  
//adder32 unit (00xxx)
// 00000	A + B	        ADD	        Addition
// 00001	A - B	        SUB	        Subtraction
// 00010	A > B	        GT	        Greater than
// 00011	A < B	        LT	        Less than
// 00100	A + B + C	    ADDC	    Addition with carry
// 00101	A - B - C	    SUBC	    Subtraction with borrow
//
//multiplier unit (01xxx)
// 01000	A * B	        MUL	        Multiplication
//
//shifter unit (10xxx)
// 10000	A << B	        SLL         Shift Left Logical
// 10001	A <<< B	        SLA         Shift Left Arithmetic
// 10010	A >> B	        SRL         Shift Right Logical
// 10011	A >>> B	        SRA         Shift Right Arithmetic
// 10100	A  B	        ROR         Rotate Right
// 10101	A  B	        ROL         Rotate Left
// 10111    A  B	        BYT         Byte swap
//
//logic unit (11xxx)
// 11000	~A	            NOT         Bitwise NOT
// 11001	A ^ B	        XOR         Bitwise XOR
// 11010	A | B	        OR          Bitwise OR
// 11011	A & B	        AND         Bitwise AND
// 11100	~(A ^ B)	    XNOR        Bitwise XNOR
// 11101	~(A | B)	    NOR         Bitwise NOR
// 11110	~(A & B)	    NAND        Bitwise NAND
// 11111	A == B	        EQ          Equality check
//

//flag register
// [7]PF, [6]0, [5]0, [4]0, [3]OF, [2]CF, [1]SF, [0]ZF
logic PF_flag;
logic OF_flag;
logic CF_flag;
logic SF_flag;
logic ZF_flag;

//carry related signals
logic C0;
logic CF_reg;
logic CF_adder;
logic CF_shifter;

assign flag_reg = {PF_flag, 3'b0, OF_flag, CF_reg, SF_flag, ZF_flag};

logic adder_mode;

assign CF_flag = (CMD[4:2] == 3'b011) ? CF_shifter : CF_adder;

assign adder_mode = CMD[0] | CMD[1];

// C0 Control Logic
always_comb begin
    case (CMD[2:0])
        3'b000: C0 = 1'b0;          // ADD
        3'b001: C0 = 1'b1;          // SUB
        3'b010: C0 = 1'b1;          // GT (assuming subtraction)
        3'b011: C0 = 1'b1;          // LT (assuming subtraction)
        3'b100: C0 = CF_reg;        // ADDC
        3'b101: C0 = CF_reg;        // SUBC
        default:  C0 = 1'b0;
    endcase
end

//00xxx selects adder32
//01xxx selects mult32
//10xxx selects shifter
//11xxx selects logic_block

// Tristate buffers for output selection
assign Y = (CMD[4:3] == 2'b00) ? adder_out[31:0] : 32'bz;   //adder32
assign Y = (CMD[4:3] == 2'b01) ? mult_out[31:0] : 32'bz;   //mult32 (Lower 32 bits)
assign Y = (CMD[4:3] == 2'b10) ? shifter_out : 32'bz;   //shifter
assign Y = (CMD[4:3] == 2'b11) ? logic_out : 32'bz;   //logic_block

// Flag Register Update (including CF)
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        PF_flag <= 1'b0;
        OF_flag <= 1'b0; 
        CF_reg <= 1'b0;
        SF_flag <= 1'b0;
        ZF_flag <= 1'b0;
    end
    else begin
        PF_flag <= |Y;
        ZF_flag <= (Y == 32'h0);
        SF_flag <= Y[31];
        OF_flag <= (Y[31] ^ Y[30]) & (Y[29] ^ Y[28]); // Basic OF check
        CF_reg  <= CF_flag; // Store the carry from Adder
    end
end

//-------------------------------POWER GATING---------------------------------
//handling of idling and power gating dynamically depending on the stage counts

logic [3:0] power_en;
logic [3:0] sreg_adder;   // 4 cycles
logic [6:0] sreg_mult;    // 7 cycles
logic [2:0] sreg_shifter; // 3 cycles
logic [2:0] sreg_logic;   // 3 cycles

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        sreg_adder <= 0;
        sreg_mult <= 0;
        sreg_shifter <= 0;
        sreg_logic <= 0;
    end else begin
        // Default: Shift right
        sreg_adder <= sreg_adder >> 1;
        sreg_mult <= sreg_mult >> 1;
        sreg_shifter <= sreg_shifter >> 1;
        sreg_logic <= sreg_logic >> 1;

        // Load if active request and not idle
        if (!idle) begin
            case (branch)
                2'b00: sreg_adder <= 4'b1111;
                2'b01: sreg_mult <= 7'b1111111;
                2'b10: sreg_shifter <= 3'b111;
                2'b11: sreg_logic <= 3'b111;
            endcase
        end
    end
end

//disabling the particular block if staged out or idle
always_comb begin
    power_en[0] = sreg_adder[0]   | ((branch == 2'b00) && !idle);
    power_en[1] = (sreg_mult[0]   | ((branch == 2'b01) && !idle)) && (low_power < 2); // Disable pipelined mult in low power
    power_en[2] = sreg_shifter[0] | ((branch == 2'b10) && !idle);
    power_en[3] = sreg_logic[0]   | ((branch == 2'b11) && !idle);
end


//counter
logic [31:0] count;
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        count <= 0;
    end
    else begin
        count <= count + 1;
    end
end

//-----------------Instantiation of components--------------------------

// Internal wires for module outputs
logic [31:0] adder_out;
logic [63:0] mult_out;
logic [31:0] shifter_out;
logic [31:0] logic_out;

// Assignments from internal wires
assign result_aux = mult_out[63:32];

//used for <, >, ADD, SUB, ADDC, SUBC
//1 PHYSICAL, 6 IMPLEMENTED
ADDER32 adder(
    .clk(clk),
    .reset_n(reset_n),
    .power_en(power_en[0]),
    .A(A),
    .B(B),
    .MODE_SEL(adder_mode),
    .C0(C0),
    .Y({CF_adder, adder_out})
);

MULT32 mult(
    .clk(clk),
    .reset_n(reset_n),
    .power_en(power_en[1] && !low_power),
    .start_i(branch == 2'b01),
    .A(A),
    .B(B),
    .P_REG(mult_out),
    .valid_o()
);

// Low Power Combinational Multiplier
// Gating inputs to save dynamic power when not in use
logic [31:0] A_comb, B_comb;
always_comb begin
    if (low_power) begin
        A_comb = A;
        B_comb = B;
    end else begin
        A_comb = 0;
        B_comb = 0;
    end
end

MULT32_COMB mult_low_power(
    .power_en(power_en[1] && low_power),
    .A(A_comb),
    .B(B_comb),
    .Y(mult_comb_out)
);

//used for SHL, SHR, SLA, SRA, ROR, ROL, BYT
//4 PHYSICAL, 7 IMPLEMENTED
SHIFTER shifter(
    .clk(clk),
    .reset_n(reset_n),
    .power_en(power_en[2]),
    .A(A),
    .B(B[4:0]),
    .CMD(CMD[2:0]),
    .Y(shifter_out),
    .CF_flag(CF_shifter)
);

//used for AND, OR, XOR, NOT, NAND, NOR, XNOR, ==
//4 PHYSICAL, 8 IMPLEMENTED
LOGIC_BLOCK logic_block(
    .clk(clk),
    .reset_n(reset_n),
    .power_en(power_en[3]),
    .A(A),
    .B(B),
    .CMD(CMD[2:0]), 
    .Y(logic_out)
);

endmodule