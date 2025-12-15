module ADDER32 (
	input  clk,
	input  reset_n,
	input  MODE_SEL,
    input  C0,
    input  [31:0] A,
    input  [31:0] B,
    output logic [32:0] Y
);


logic [31:0] A_REG;
logic [31:0] B_REG;
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        A_REG <= 0;
        B_REG <= 0;
    end
    else begin
        A_REG <= A;
        B_REG <= B;
    end
end

assign Y = A_REG + B_REG + C0;


endmodule
