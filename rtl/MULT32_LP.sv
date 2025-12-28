module MULT32_LP (
    input [31:0] A,
    input [31:0] B,
    output [63:0] Y
);
    // Purely combinational multiplier for low power/low frequency mode
    assign Y = A * B;
endmodule
