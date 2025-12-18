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
// 00110	A - B	        SUB		    Subtraction 
// 00111	A - B	        SUB		    Subtraction
//
//
//multiplier unit (01xxx)
// 01xxx	A * B	        MUL	        Multiplication
//
//shifter unit (10xxx)
// 10000	A << B	        SLL         Shift Left Logical
// 10001	A <<< B	        SLA         Shift Left Arithmetic
// 10010	A >> B	        SRL         Shift Right Logical
// 10011	A >>> B	        SRA         Shift Right Arithmetic
// 10100	A  B	        ROR         Rotate Right
// 10101	A  B	        ROL         Rotate Left
// 10110    A  B	        BYT         Byte swap
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

logic clk_low; //DUMB SIGNAL FOR EASIER ANALYSIS IN GENUS

//carry related signals
logic C0;
logic CF_reg;
logic CF_adder;
logic CF_shifter;

assign flag_reg = {PF_flag, 3'b0, OF_flag, CF_reg, SF_flag, ZF_flag};

logic adder_mode;

assign CF_flag = (CMD[4:2] == 3'b011) ? CF_shifter : final_adder_carry;

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
        3'b011: C0 = 1'b1;          // SUB
        3'b101: C0 = 1'b1;          // SUB
        default:  C0 = 1'b0;
    endcase
end

//00xxx selects adder32
//01xxx selects mult32
//10xxx selects shifter
//11xxx selects logic_block

// Tristate buffers for output selection
logic [31:0] final_adder_out;
assign final_adder_out = (low_power) ? adder_lp_out[31:0] : adder_out[31:0];
logic final_adder_carry;
assign final_adder_carry = (low_power) ? adder_lp_out[32] : CF_adder;

assign Y = (CMD[4:3] == 2'b00) ? final_adder_out : 32'bz;   //adder32
assign Y = (CMD[4:3] == 2'b01) ? final_mult_out[31:0] : 32'bz;   //mult32 (Lower 32 bits)
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
        PF_flag <= ^Y;
        ZF_flag <= (Y == 32'h0);
        SF_flag <= Y[31];
        // Standard Overflow: (Operand1_Sign == Operand2_Sign) && (Result_Sign != Operand1_Sign)
        // Operand2_eff is B inverted if subtracting.
        OF_flag <= (CMD[4:3] == 2'b00) & (A[31] == (B[31] ^ adder_mode)) & (Y[31] != A[31]); 
        CF_reg  <= CF_flag; // Store the carry from Adder
    end
end

//-------------------------------POWER GATING---------------------------------
//handling of idling and power gating dynamically depending on the stage counts

logic power_en_adder, power_en_mult, power_en_shifter, power_en_logic;
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
            if (low_power) begin
                case (branch)
                    2'b00: sreg_adder <= 4'b0111;
                    2'b01: sreg_mult <= 7'b0000111;
                    2'b10: sreg_shifter <= 3'b111;
                    2'b11: sreg_logic <= 3'b111;
                endcase
            end else begin
                case (branch)
                    2'b00: sreg_adder <= 4'b1111;
                    2'b01: sreg_mult <= 7'b1111111;
                    2'b10: sreg_shifter <= 3'b111;
                    2'b11: sreg_logic <= 3'b111;
                endcase
            end
        end
    end
end

//disabling the particular block if staged out or idle

always_comb begin
    power_en_adder = sreg_adder[0]   | ((branch == 2'b00) && !idle);
    power_en_mult = (sreg_mult[0]   | ((branch == 2'b01) && !idle));
    power_en_shifter = sreg_shifter[0] | ((branch == 2'b10) && !idle);
    power_en_logic = sreg_logic[0]   | ((branch == 2'b11) && !idle);
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
logic [32:0] adder_lp_out;
logic [63:0] mult_out;
logic [63:0] mult_lp_out;
logic [31:0] shifter_out;
logic [31:0] logic_out;

// Assignments from internal wires
logic [63:0] final_mult_out;
assign final_mult_out = (low_power) ? mult_lp_out : mult_out;

assign result_aux = final_mult_out[63:32];

assign power_en_adder_lp = power_en_adder && low_power;
assign power_en_mult_lp = power_en_mult && low_power;
assign power_en_adder_fast = power_en_adder && !low_power;
assign power_en_mult_fast = power_en_mult && !low_power;



//used for <, >, ADD, SUB, ADDC, SUBC
//1 PHYSICAL, 6 IMPLEMENTED
ADDER32 adder(
    .clk(clk),
    .reset_n(reset_n),
    .power_en(power_en_adder_fast),
    .A(A),
    .B(B),
    .MODE_SEL(adder_mode),
    .C0(C0),
    .Y({CF_adder, adder_out})
);

ADDER32_LP adder_lp(
    .clk_low(clk_low),
    .power_en(power_en_adder_lp),
    .MODE_SEL(adder_mode),
    .C0(C0), // Note: C0 logic might need review if it depends on piped signals, but looks combinatorial in ALU_TOP
    .A(A_comb),
    .B(B_comb),
    .Y(adder_lp_out)
);

MULT32 mult(
    .clk(clk),
    .reset_n(reset_n),
    .power_en(power_en_mult_fast),
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

MULT32_LP mult_lp(
    .clk_low(clk_low),
    .power_en(power_en_mult_lp),
    .A(A_comb),
    .B(B_comb),
    .Y(mult_lp_out)
);

//used for SHL, SHR, SLA, SRA, ROR, ROL, BYT
//4 PHYSICAL, 7 IMPLEMENTED
SHIFTER shifter(
    .power_en(power_en_shifter),
    .A(A),
    .B(B[4:0]),
    .CMD(CMD[2:0]),
    .Y(shifter_out),
    .CF_flag(CF_shifter)
);

//used for AND, OR, XOR, NOT, NAND, NOR, XNOR, ==
//4 PHYSICAL, 8 IMPLEMENTED
LOGIC_BLOCK logic_block(
    .power_en(power_en_logic),
    .A(A),
    .B(B),
    .CMD(CMD[2:0]), 
    .Y(logic_out)
);

endmodule