`timescale 1ns / 1ps

module SHIFTER (
    input clk,
    input reset_n,
    input  logic [31:0] A,          // Operand
    input  logic [4:0]  B,          // Shift Amount
    input  logic [1:0]  CMD,        // Command: 00=SLL, 01=SLA, 10=SRL, 11=SRA
    output logic [31:0] Y,           // Result
    output logic CF_flag
);
logic [31:0] A_REG;
logic [4:0] B_REG;

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        A_REG <= 0;
        B_REG <= 0;
    end 
    else begin
        A_REG <= A;
        B_REG <= B;
    end
end

// Operation Codes
localparam CMD_SLL = 2'b00; // Shift Left Logical
localparam CMD_SLA = 2'b01; // Shift Left Arithmetic
localparam CMD_SRL = 2'b10; // Shift Right Logical
localparam CMD_SRA = 2'b11; // Shift Right Arithmetic

    logic [32:0] temp_res;

    always_comb begin
        case (CMD)
            CMD_SLL: begin
                temp_res = {1'b0, A_REG} << B_REG;
                Y = temp_res[31:0];
                CF_flag = temp_res[32];
            end
            CMD_SLA: begin
                temp_res = {1'b0, A_REG} <<< B_REG;
                Y = temp_res[31:0];
                CF_flag = temp_res[32];
            end
            CMD_SRL: begin
                temp_res = {A_REG, 1'b0} >> B_REG;
                Y = temp_res[32:1];
                CF_flag = temp_res[0];
            end
            CMD_SRA: begin
                temp_res = $signed({A_REG, 1'b0}) >>> B_REG;
                Y = temp_res[32:1];
                CF_flag = temp_res[0];
            end
            default: begin
                Y = 32'd0;
                CF_flag = 1'b0;
            end
        endcase
    end

endmodule
