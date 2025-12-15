// 1. The reusable 32-bit register module
module dffr_32bit (
    input logic clk,
    input logic rst,  // Asynchronous Reset
    input logic [31:0] D,
    output logic [31:0] Q
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            Q <= 32'b0;
        else
            Q <= D;
    end
endmodule
