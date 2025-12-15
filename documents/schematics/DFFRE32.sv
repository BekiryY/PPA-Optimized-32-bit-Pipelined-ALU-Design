// 1. The reusable 32-bit register module
module dffre_32bit (
    input logic clk,
    input logic reset_n,  // Asynchronous Reset
    input logic power_en,
    input logic [31:0] D,
    output logic [31:0] Q
);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            Q <= 32'b0;
        else if (!power_en)
            Q <= 32'b0;
        else
            Q <= D;
    end
endmodule
