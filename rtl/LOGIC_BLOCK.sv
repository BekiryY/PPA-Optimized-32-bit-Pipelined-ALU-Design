module LOGIC_BLOCK(
    input logic power_en,
    input [31:0] A,
    input [31:0] B,
    input [2:0] CMD,
    output logic [31:0] Y
    );

logic [31:0] NAND_o;
logic [31:0] NOR_o;
logic [31:0] XNOR_o;
logic [31:0] Y1;
logic [31:0] Y2;
logic [1:0] mux1_sel;
logic [1:0] mux2_sel;

// == operation simply XOR
always @(*) begin
    if(CMD == 3'b111) begin
        mux1_sel = 2'b01;
        mux2_sel = 2'b00;
    end 
    else begin
        mux1_sel = CMD[1:0];
        mux2_sel = (CMD[2]) ? (CMD[1:0] + 2'b01) : 2'b00;
    end
end
//000 NOT
//001 XOR
//010 OR
//011 AND
//100 XNOR
//101 NOR
//110 NAND
//111 EQ/XOR
assign NAND_o = ~(A & B); //NAND
assign NOR_o = ~(A | B); //NOR
assign XNOR_o = ~(A ^ B); //XNOR


//4-1 MUX (32BITWIDE) FIRST_MUX
always @(*) begin
    case (mux1_sel)
        2'b00: Y1 = B;
        2'b01: Y1 = XNOR_o;
        2'b10: Y1 = NOR_o;
        2'b11: Y1 = NAND_o;
    endcase
end

assign Y2 = ~Y1;
//4-1 MUX (32BITWIDE) SECOND_MUX
always @(*) begin
    if(!power_en) begin
        Y = 32'b0;
    end
    else begin
        case (mux2_sel)
            2'b00: Y = Y2;
            2'b01: Y = XNOR_o;
            2'b10: Y = NOR_o;
            2'b11: Y = NAND_o;
        endcase
    end
end

endmodule