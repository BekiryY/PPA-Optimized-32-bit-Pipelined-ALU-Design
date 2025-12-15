module MULT32_COMB (
    input power_en,
    input [31:0] A,
    input [31:0] B,
    output [63:0] Y
);
    // Purely combinational multiplier for low power/low frequency mode
    assign Y = power_en ? A * B : 64'b0;
endmodule
