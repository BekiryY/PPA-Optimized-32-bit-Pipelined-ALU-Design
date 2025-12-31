`timescale 1ns / 1ps

module SHIFTER (
    input  logic        clk,
    input  logic        reset_n,
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
localparam CMD_ROL = 3'b100; // Rotate Left
localparam CMD_ROR = 3'b101; // Rotate Right
localparam CMD_BYT = 3'b110; // Byte Swap

// Stage 1 Registers (Input)
logic [31:0] A_reg;
logic [4:0]  B_reg;
logic [2:0]  CMD_reg;

// Combinational Logic Signals
logic [32:0] temp_res;
logic [31:0] Y_next;
logic        CF_flag_next;

// Stage 2 Registers (Output)
logic [31:0] Y_reg;
logic        CF_flag_reg;

// =========================================================================
// Stage 1: Input Registration ("Very Little Logic")
// =========================================================================
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        A_reg   <= '0;
        B_reg   <= '0;
        CMD_reg <= '0;
    end else begin
        A_reg   <= A;
        B_reg   <= B;
        CMD_reg <= CMD;
    end
end

// =========================================================================
// Logic Cloud ("Heavy Logical Operation")
// =========================================================================
always_comb begin
    case (CMD_reg)
        CMD_SLL: begin
            temp_res = {1'b0, A_reg} << B_reg;
            Y_next = temp_res[31:0];
            CF_flag_next = temp_res[32];
        end
        CMD_SLA: begin
            temp_res = {1'b0, A_reg} <<< B_reg;
            Y_next = temp_res[31:0];
            CF_flag_next = temp_res[32];
        end
        CMD_SRL: begin
            temp_res = {A_reg, 1'b0} >> B_reg;
            Y_next = temp_res[32:1];
            CF_flag_next = temp_res[0];
        end
        CMD_SRA: begin
            temp_res = $signed({A_reg, 1'b0}) >>> B_reg;
            Y_next = temp_res[32:1];
            CF_flag_next = temp_res[0];
        end
        CMD_ROL: begin
            // Rotate Left
            Y_next = (A_reg << B_reg) | (A_reg >> (32 - B_reg));
            CF_flag_next = 0; 
        end
        CMD_ROR: begin
            // Rotate Right
            Y_next = (A_reg >> B_reg) | (A_reg << (32 - B_reg));
            CF_flag_next = 0;
        end
        CMD_BYT: begin
            // Byte Swap (Big Endian <-> Little Endian)
            Y_next = {A_reg[7:0], A_reg[15:8], A_reg[23:16], A_reg[31:24]};
            CF_flag_next = 0;
        end
        default: begin
            Y_next = 32'd0;
            CF_flag_next = 1'b0;
        end
    endcase
end

// =========================================================================
// Stage 2: Output Registration via DFF (+ No Logic Output)
// =========================================================================
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        Y_reg       <= '0;
        CF_flag_reg <= '0;
    end else begin
        Y_reg       <= Y_next;
        CF_flag_reg <= CF_flag_next;
    end
end

assign Y = Y_reg;
assign CF_flag = CF_flag_reg;

endmodule
