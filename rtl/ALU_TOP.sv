module ALU_TOP(
    input clk,
    input reset_n,

    //operands & opcode
    input [31:0] A,
    input [31:0] B,
    input [4:0] CMD,
    input input_valid,

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
    output logic output_valid,
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


//carry related signals
logic C0;
logic CF_reg;
logic PF_reg;
logic ZF_reg;
logic CF_adder;
logic CF_shifter;

logic final_adder_carry;
logic [31:0] final_adder_out;
logic [31:0] Y_reg;

//flag register
// [7]PF, [6]0, [5]0, [4]0, [3]OF, [2]CF, [1]SF, [0]ZF
logic OF_flag;
logic CF_flag;
logic SF_flag;
//unfortunately pf_reg, zf_reg and cf_reg values are 1 cycle more delayed after Y
assign flag_reg = {PF_reg, 3'b0, OF_flag, CF_reg, SF_flag, ZF_reg};

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

// Internal wires for module outputs
logic [31:0] adder_out;
logic [32:0] adder_lp_out;
logic [63:0] mult_out;
logic [63:0] mult_lp_out;
logic [31:0] shifter_out;
logic [31:0] logic_out;

// Gated inputs
logic [31:0] A_gated, B_gated;
assign A_gated = input_valid ? A : 32'd0;
assign B_gated = input_valid ? B : 32'd0;

// Tristate buffers for output selection
assign final_adder_out = (low_power) ? adder_lp_out[31:0] : adder_out[31:0];
assign final_adder_carry = (low_power) ? adder_lp_out[32] : CF_adder;

//00xxx selects adder32
//01xxx selects mult32
//10xxx selects shifter
//11xxx selects logic_block
assign Y = (v_add_r || (low_power && CMD[4:3] == 2'b00 && output_valid)) ? final_adder_out : 
           (v_mul_r[6] || (low_power && CMD[4:3] == 2'b01 && output_valid)) ? final_mult_out[31:0] :
           (CMD[4:3] == 2'b10 && output_valid) ? shifter_out :
           (CMD[4:3] == 2'b11 && output_valid) ? logic_out : 32'd0;

assign result_aux = (v_mul_r[6] || (low_power && CMD[4:3] == 2'b01 && output_valid)) ? final_mult_out[63:32] : 32'd0;

// Flag Register Update (including CF)
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        PF_reg <= 1'b0;
        OF_flag <= 1'b0; 
        CF_reg <= 1'b0;
        SF_flag <= 1'b0;
        ZF_reg <= 1'b0;
        Y_reg <= 32'h0;
    end
    else begin
        Y_reg <= Y;
        PF_reg <= ^Y_reg;
        ZF_reg <= (Y_reg == 32'h0);
        SF_flag <= Y[31];
        // Standard Overflow: (Operand1_Sign == Operand2_Sign) && (Result_Sign != Operand1_Sign)
        // Operand2_eff is B inverted if subtracting.
        //OF_flag <= (CMD[4:3] == 2'b00) & (A[31] == (B[31] ^ adder_mode)) & (Y[31] != A[31]); 
        OF_flag <= (CMD[4:3] == 2'b00) & (A[31] == (B[31] ^ adder_mode)); 
        CF_reg  <= CF_flag; // Store the carry from Adder
    end
end

//-------------------------------POWER GATING---------------------------------
//handling of idling and power gating dynamically depending on the stage counts

logic power_en_adder, power_en_mult, power_en_shifter, power_en_logic;
//brach prediction comes 2 cycles earlier so 
//the amount of on-cycle is (pipeline stage count + 2)
logic [3:0] sreg_adder;   // 4 cycles
logic [8:0] sreg_mult;    // 9 cycles
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

        // Load if active request and not idle and valid
        if (!idle && input_valid) begin
            if (low_power) begin
                case (branch)
                    2'b00: sreg_adder <= 4'b0111;
                    2'b01: sreg_mult <= 9'b00000111;
                    2'b10: sreg_shifter <= 3'b111;
                    2'b11: sreg_logic <= 3'b111;
                endcase
            end else begin
                case (branch)
                    2'b00: sreg_adder <= 4'b1111;
                    2'b01: sreg_mult <= 9'b111111111;
                    2'b10: sreg_shifter <= 3'b111;
                    2'b11: sreg_logic <= 3'b111;
                endcase
            end
        end
    end
end

//disabling the particular block if staged out or idle

always_comb begin
    power_en_adder = sreg_adder[0]   | ((branch == 2'b00) && !idle && input_valid);
    power_en_mult = (sreg_mult[0]   | ((branch == 2'b01) && !idle && input_valid));
    power_en_shifter = sreg_shifter[0] | ((branch == 2'b10) && !idle && input_valid);
    power_en_logic = sreg_logic[0]   | ((branch == 2'b11) && !idle && input_valid);
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

// Output Valid Handling and Command Pipelining
logic  v_add_r;
logic [6:0] v_mul_r;
logic [1:0] cmd_add_r;      // Delayed CMD for Adder (1 cycle)
logic [13:0] cmd_mul_r;     // Delayed CMD for Mult (7 cycles of 2 bits)

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        v_add_r <= 1'b0;
        v_mul_r <= 7'd0;
        cmd_add_r <= 2'b00;
        cmd_mul_r <= 14'd0;
    end else begin
        // Pipeline valid signals
        v_add_r <=  input_valid & (CMD[4:3] == 2'b00) & !low_power;
        v_mul_r <= {v_mul_r[5:0], input_valid & (CMD[4:3] == 2'b01) & !low_power};
        // Pipeline command bits (CMD[4:3]) to match latency
        // Adder path: 1 cycle delay
        if(input_valid && !low_power) cmd_add_r <= CMD[4:3];
        
        // Multiplier path: 7 cycle delay (shift register for 2 bits)
        if(input_valid && !low_power) begin 
             cmd_mul_r <= {cmd_mul_r[11:0], CMD[4:3]};
        end else begin
             // Keep shifting to propagate the pipeline even if new input isn't valid? 
             // Actually, for a fixed pipeline, we should always shift.
             cmd_mul_r <= {cmd_mul_r[11:0], (input_valid ? CMD[4:3] : 2'b00)}; 
             // Note: If input not valid, pushing 00 is risky if 00 is Adder. 
             // Better to just shift. Realistically, we only care about the value when v_mul_r[6] is 1.
        end
    end
end

// Select signals derived from delayed commands
logic [1:0] cmd_delayed_add;
logic [1:0] cmd_delayed_mul;
assign cmd_delayed_add = cmd_add_r;
assign cmd_delayed_mul = cmd_mul_r[13:12];

always_comb begin
    if (low_power) begin
        output_valid = input_valid; // Combinational in LP
    end else begin
        // Prioritize Multiplier completion if valid, then Adder, etc.
        if (v_mul_r[6]) output_valid = 1'b1;
        else if (v_add_r) output_valid = 1'b1;
        // Only pass input_valid for 0-cycle blocks (Shifter/Logic)
        // Adder (00) and Mult (01) must NOT assert valid here immediately.
        else if (CMD[4:3] == 2'b10 || CMD[4:3] == 2'b11) output_valid = input_valid; 
        else output_valid = 1'b0;
    end
end

//-----------------Instantiation of components--------------------------

// Assignments from internal wires
logic [63:0] final_mult_out;
assign final_mult_out = (low_power) ? mult_lp_out : mult_out;

// result_aux assigned above

assign power_en_adder_lp = power_en_adder && low_power;
assign power_en_mult_lp = power_en_mult && low_power;
assign power_en_adder_fast = power_en_adder && !low_power;
assign power_en_mult_fast = power_en_mult && !low_power;


// Low Power Combinational Multiplier
// Gating inputs to save dynamic power when not in use
logic [31:0] A_comb, B_comb;
always_comb begin
    if (low_power) begin
        A_comb = A_gated;
        B_comb = B_gated;
    end else begin
        A_comb = 0;
        B_comb = 0;
    end
end

//used for <, >, ADD, SUB, ADDC, SUBC
//6 IMPLEMENTED
ADDER32 adder(
    .clk(clk),
    .reset_n(reset_n),
    .power_en(power_en_adder_fast),
    .A(A_gated),
    .B(B_gated),
    .MODE_SEL(adder_mode),
    .C0(C0),
    .Y({CF_adder, adder_out})
);


ADDER32_LP adder_lp(
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
    .A(A_gated),
    .B(B_gated),
    .P_REG(mult_out)
);

MULT32_LP mult_lp(
    .power_en(power_en_mult_lp),
    .A(A_comb),
    .B(B_comb),
    .Y(mult_lp_out)
);

//used for SHL, SHR, SLA, SRA, ROR, ROL, BYT
//7 IMPLEMENTED
SHIFTER shifter(
    .power_en(power_en_shifter),
    .A(A_gated),
    .B(B_gated[4:0]),
    .CMD(CMD[2:0]),
    .Y(shifter_out),
    .CF_flag(CF_shifter)
);

//used for AND, OR, XOR, NOT, NAND, NOR, XNOR, EQ
//8 IMPLEMENTED
LOGIC_BLOCK logic_block(
    .power_en(power_en_logic),
    .A(A_gated),
    .B(B_gated),
    .CMD(CMD[2:0]), 
    .Y(logic_out)
);

endmodule