// 1. The reusable 32-bit register module
module dffre (
    input logic clk,
    input logic reset_n,  // Asynchronous Reset
    input logic power_en,
    input logic D,
    output logic Q
);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            Q <= 1'b0;
        else if (!power_en)
            Q <= 1'b0;
        else
            Q <= D;
    end 
endmodule
