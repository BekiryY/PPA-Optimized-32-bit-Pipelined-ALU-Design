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
    input low_power,
    //low power table
    //0 - normal (upto 1.66GHZ)
    //1 - low power (upto 120MHZ)

    //outputs
    output logic [31:0] Y,
    output logic [31:0] result_aux,
    output logic output_valid,
    output logic [31:0] Y_conflict,
    output logic conflict_valid,
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
// 11000	~B	            NOT         Bitwise NOT
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
logic CF_adder;
logic CF_shifter;
logic final_adder_carry;
logic [31:0] final_adder_out;
logic adder_mode;

c0_calculator c0_calc (
    .CMD(CMD[2:0]),
    .CF_reg(CF_reg),
    .C0(C0),
    .adder_mode(adder_mode)
);

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

logic  v_add_r;
logic [6:0] v_mul_r;

//-------------------------------OUTPUT SELECTION-------------------------------
// tristates for output selection
assign final_adder_out   = (low_power) ? adder_lp_out[31:0] : adder_out[31:0];
assign final_adder_carry = (low_power) ? adder_lp_out[32]   : CF_adder;

// Internal Valid Signal Construction
logic valid_mult, valid_adder, valid_comb;
logic [31:0] comb_out;

assign valid_mult = v_mul_r[6] || (low_power && CMD[4:3] == 2'b01 && output_valid);
assign valid_adder = v_add_r || (low_power && CMD[4:3] == 2'b00 && output_valid);
assign valid_comb = ((CMD[4:3] == 2'b10) || (CMD[4:3] == 2'b11)) && output_valid;

assign comb_out = (CMD[4:3] == 2'b10) ? shifter_out : logic_out;

// Priority: MULT32 > ADDER32 > SHIFTER = LOGIC_BLOCK

assign Y = (valid_mult)  ? final_mult_out[31:0] :
           (valid_adder) ? final_adder_out :
           (valid_comb)  ? comb_out : 32'dz;

assign result_aux = (valid_mult) ? final_mult_out[63:32] : 32'dz;

// Conflict Logic
always_comb begin
    Y_conflict = 32'd0;
    conflict_valid = 1'b0;

    if (valid_mult) begin
        if (valid_comb) begin
            // Conflict Mult vs Comb. Comb is least important.
            Y_conflict = comb_out;
            conflict_valid = 1'b1;
        end else if (valid_adder) begin
            // Conflict Mult vs Adder. Adder is least important.
            Y_conflict = final_adder_out;
            conflict_valid = 1'b1;
        end
    end else if (valid_adder) begin
        if (valid_comb) begin
            // Conflict Adder vs Comb. Comb is least important.
            Y_conflict = comb_out;
            conflict_valid = 1'b1;
        end
    end
end

// Even tough these look like spagetthi, tristates are faster than muxes in order of 1-2 logic levels

// Flag Register Update (including CF)
    flag_controller flags (
        .clk(clk),
        .reset_n(reset_n),
        .CMD(CMD),
        .A(A),
        .B(B),
        .Y(Y),
        .adder_mode(adder_mode),
        .CF_shifter(CF_shifter),
        .final_adder_carry(final_adder_carry),
        .flag_reg(flag_reg),
        .CF_reg(CF_reg)
    );


    // Output Valid Handling and Command Pipelining

    
    pipe_counter pipe_cnt (
        .clk(clk),
        .reset_n(reset_n),
        .input_valid(input_valid),
        .CMD(CMD),
        .low_power(low_power),
        .idle(idle),
        .output_valid(output_valid),
        .v_add_r(v_add_r),
        .v_mul_r(v_mul_r)
    );


//counter (NOT used currently but can be used in future)
logic [15:0] count;
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        count <= 0;
    end
    else begin
        count <= count + 1;
    end
end

//-----------------Instantiation of components--------------------------

// Assignments from internal wires
logic [63:0] final_mult_out;
assign final_mult_out = (low_power) ? mult_lp_out : mult_out;

// result_aux assigned above

// LP Enables defined in power_gate_controller
// Fast Enables derived here

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
    .A(A_gated),
    .B(B_gated),
    .MODE_SEL(adder_mode),
    .C0(C0),
    .Y({CF_adder, adder_out})
);
ADDER32_LP adder_lp(

    .MODE_SEL(adder_mode),
    .C0(C0), // Note: C0 logic might need review if it depends on piped signals, but looks combinatorial in ALU_TOP
    .A(A_comb),
    .B(B_comb),
    .Y(adder_lp_out)
);


MULT32 mult(
    .clk(clk),
    .reset_n(reset_n),
    .A(A_gated),
    .B(B_gated),
    .P_REG(mult_out)
);
MULT32_LP mult_lp(
    .A(A_comb),
    .B(B_comb),
    .Y(mult_lp_out)
);

//used for SHL, SHR, SLA, SRA, ROR, ROL, BYT
//7 operations impelemented
SHIFTER shifter(
    .A(A_gated),
    .B(B_gated[4:0]),
    .CMD(CMD[2:0]),
    .Y(shifter_out),
    .CF_flag(CF_shifter)
);

//used for AND, OR, XOR, NOT, NAND, NOR, XNOR, EQ
//8 IMPLEMENTED
LOGIC_BLOCK logic_block(
    .A(A_gated),
    .B(B_gated),
    .CMD(CMD[2:0]), 
    .Y(logic_out)
);

endmodule