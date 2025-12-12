module ALU_TOP(
    input clk,
    input reset_n,

    //operands & opcode
    input [31:0] A,
    input [31:0] B,
    input [4:0] CMD,

    //performance control
    input [1:0] branch,
    input [2:0] low_power,

    //outputs
    output wire [31:0] Y,
    output logic [31:0] result_aux,
    output logic [7:0] flag_reg
);
//flag register
// [7]PF, [6]0, [5]0, [4]0, [3]OF, [2]CF, [1]SF, [0]ZF
logic PF_flag;
logic OF_flag;
logic CF_flag;
logic SF_flag;
logic ZF_flag;

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
//nop (110xx)
// 110xx    NOP             NOP         No Operation
//
//future (111xx)
// 111x    FUTURE          FUTURE      Reserved for Future

//for testing
//logic [63:0]total;
//assign total = {result_aux, MUX_i[1]}; 

logic C0;
logic CF_reg;
logic CF_adder;
logic CF_shifter;

logic adder_mode;

assign flag_reg = {PF_flag, 3'b0, OF_flag, CF_reg, SF_flag, ZF_flag};

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
assign Y = (CMD[4:3] == 2'b00) ? adder.Y : 32'bz;   //adder32
assign Y = (CMD[4:3] == 2'b01) ? mult.Y : 32'bz;   //mult32
assign Y = (CMD[4:3] == 2'b10) ? shifter.Y : 32'bz;   //shifter
assign Y = (CMD[4:3] == 2'b11) ? logic_block.Y : 32'bz;   //logic_block

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


logic [31:0] count;
//counter
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        count <= 0;
    end
    else begin
        count <= count + 1;
    end
end

//-----------------Instantiation of components--------------------------

//used for <, >, ADD, SUB, ADDC, SUBC
//1 PHYSICAL, 6 IMPLEMENTED
ADDER32 adder(
    .clk(clk),
    .reset_n(reset_n),
    .A(A),
    .B(B),
    .MODE_SEL(adder_mode),
    .C0(C0),
    .Y({CF_adder, MUX_i[0]})
);

MULT32 mult(
    .clk(clk),
    .reset_n(reset_n),
    .A(A),
    .B(B),
    .Y({result_aux, MUX_i[1]})
);

//used for SHL, SHR, SLA, SRA
//4 PHYSICAL, 4 IMPLEMENTED
SHIFTER shifter(
    .clk(clk),
    .reset_n(reset_n),
    .A(A),
    .B(B[4:0]),
    .CMD(CMD[1:0]),
    .Y(MUX_i[3]),
    .CF_flag(CF_shifter)
);

//used for AND, OR, XOR, NOT, NAND, NOR, XNOR, ==
//4 PHYSICAL, 8 IMPLEMENTED
LOGIC_BLOCK logic_block(
    .clk(clk),
    .reset_n(reset_n),
    .A(A),
    .B(B),
    .CMD(CMD[2:0]), 
    .Y(MUX_i[2])
);

endmodule