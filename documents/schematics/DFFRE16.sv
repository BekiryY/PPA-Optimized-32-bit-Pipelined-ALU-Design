// 1. The reusable 32-bit register module
module dffre_16bit (
    input logic clk,
    input logic reset_n,  // Asynchronous Reset
    input logic power_en,
    input logic [15:0] D,
    output logic [15:0] Q
);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            Q <= 16'b0;
        else if (!power_en)
            Q <= 16'b0;
        else
            Q <= D;
    end 
endmodule
