`timescale 1ns / 1ps

module SHIFTER (
    input logic power_en,
    input  logic [31:0] A,          // Operand
    input  logic [4:0]  B,          // Shift Amount
    input  logic [2:0]  CMD,        // Command: 00=SLL, 01=SLA, 10=SRL, 11=SRA
    output logic [31:0] Y,           // Result
    output logic CF_flag
);

// Operation Codes
localparam CMD_SLL = 3'b000; // Shift Left Logical
localparam CMD_SLA = 3'b001; // Shift Left Arithmetic
localparam CMD_SRL = 3'b010; // Shift Right Logical
localparam CMD_SRA = 3'b011; // Shift Right Arithmetic
localparam CMD_ROL = 3'b100; // Shift Right Logical
localparam CMD_ROR = 3'b101; // Shift Right Arithmetic
localparam CMD_BYT = 3'b111; // Byte Swap

logic [32:0] temp_res;

always_comb begin
    // --- POWER GATING CLAMP/ISOLATION LOGIC ---
    if (!power_en) begin
        Y = 32'h0;      // Clamp output to 0 when sleeping (essential Isolation Cell function)
        CF_flag = 1'b0;
    end 
    else begin
        case (CMD)
            CMD_SLL: begin
                temp_res = {1'b0, A} << B;
                Y = temp_res[31:0];
                CF_flag = temp_res[32];
            end
            CMD_SLA: begin
                temp_res = {1'b0, A} <<< B;
                Y = temp_res[31:0];
                CF_flag = temp_res[32];
            end
            CMD_SRL: begin
                temp_res = {A, 1'b0} >> B;
                Y = temp_res[32:1];
                CF_flag = temp_res[0];
            end
            CMD_SRA: begin
                temp_res = $signed({A, 1'b0}) >>> B;
                Y = temp_res[32:1];
                CF_flag = temp_res[0];
            end
            
            CMD_ROL: begin
                // Rotate Left
                Y = (A << B) | (A >> (32 - B));
                // CF for rotate usually undefined or last bit shifted out. 
                // Maintaining 0 for simplicity unless specific arch required.
                CF_flag = 0; 
            end
            CMD_ROR: begin
                // Rotate Right
                Y = (A >> B) | (A << (32 - B));
                CF_flag = 0;
            end
            CMD_BYT: begin
                // Byte Swap (Big Endian <-> Little Endian)
                Y = {A[7:0], A[15:8], A[23:16], A[31:24]};
                CF_flag = 0;
            end
            default: begin
                Y = 32'd0;
                CF_flag = 1'b0;
            end
        endcase
    end
end

endmodule
