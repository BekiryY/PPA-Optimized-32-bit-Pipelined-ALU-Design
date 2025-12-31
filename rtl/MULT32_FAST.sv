`timescale 1ns / 1ps

module MULT32 (
    input  logic        clk,
    input  logic        reset_n,
    input  logic [31:0] A,
    input  logic [31:0] B,
    output logic [63:0] P_REG
);

    // =========================================================================
    // Signal Decomposition
    // =========================================================================
    logic [15:0] a_hi, a_lo;
    logic [15:0] b_hi, b_lo;

    assign a_hi = A[31:16]; 
    assign a_lo = A[15:0];
    assign b_hi = B[31:16]; 
    assign b_lo = B[15:0];

    // =========================================================================
    // STAGE 1: 16x16 Multipliers description
    // Latency: 4 clock cycles (internal to MULT16)
    // =========================================================================
    logic [31:0] p_hh_comb, p_hl_comb, p_lh_comb, p_ll_comb;

    MULT16 mult16_hh (.clk(clk), .reset_n(reset_n), .A(a_hi), .B(b_hi), .P(p_hh_comb));
    MULT16 mult16_hl (.clk(clk), .reset_n(reset_n), .A(a_hi), .B(b_lo), .P(p_hl_comb));
    MULT16 mult16_lh (.clk(clk), .reset_n(reset_n), .A(a_lo), .B(b_hi), .P(p_lh_comb));
    MULT16 mult16_ll (.clk(clk), .reset_n(reset_n), .A(a_lo), .B(b_lo), .P(p_ll_comb));

    // Pipeline Registers (End of Stage 1)
    logic [31:0] p_hh_reg, p_hl_reg, p_lh_reg, p_ll_reg;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            p_ll_reg <= '0; 
            p_hl_reg <= '0; 
            p_lh_reg <= '0; 
            p_hh_reg <= '0;
        end else begin
            p_ll_reg <= p_ll_comb; 
            p_hl_reg <= p_hl_comb;
            p_lh_reg <= p_lh_comb; 
            p_hh_reg <= p_hh_comb;
        end
    end

    // =========================================================================
    // STAGE 2: Intermediate Addition
    // Latency: 1 clock cycle (Register at end)
    // =========================================================================
    
    // 1. Middle Sum (33 bits): P_HL + P_LH
    logic [32:0] mid_sum_comb;
    assign mid_sum_comb = p_hl_reg + p_lh_reg;

    // Pipeline Registers for Alignment
    logic [32:0] mid_sum_reg;
    logic [31:0] p_hh_reg_d1;
    logic [31:0] p_ll_reg_d1;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            mid_sum_reg <= '0;
            p_hh_reg_d1 <= '0;
            p_ll_reg_d1 <= '0;
        end else begin
            mid_sum_reg <= mid_sum_comb;
            p_hh_reg_d1 <= p_hh_reg;
            p_ll_reg_d1 <= p_ll_reg;
        end
    end

    // =========================================================================
    // STAGE 3: Lower-Middle Addition (First 24 bits)
    // Latency: 1 clock cycle
    // =========================================================================

    // Logic: P_HH[7:0] << 16 + P_MID[23:0] + P_LL[31:16]
    logic [24:0] sum_stage3_comb; // 25 bits to capture carry out
    
    assign sum_stage3_comb = {p_hh_reg_d1[7:0], 16'b0} 
                           + mid_sum_reg[23:0] 
                           + {8'b0, p_ll_reg_d1[31:16]};

    // Pipeline Registers (End of Stage 3)
    logic [24:0] p_first_24_reg;   // Result of the stage 2/3 adder
    logic [23:0] p_hh_upper_reg;   // Pass P_HH[31:8] to next stage
    logic [8:0]  mid_sum_upper_reg;  // Pass P_MID[32:24] to next stage
    logic [15:0] p_ll_final_reg;   // Delayed LSBs

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            p_first_24_reg    <= '0;
            p_hh_upper_reg    <= '0;
            mid_sum_upper_reg <= '0;
            p_ll_final_reg    <= '0;
        end else begin
            p_first_24_reg    <= sum_stage3_comb; 
            // Align signals for the final stage
            p_hh_upper_reg    <= p_hh_reg_d1[31:8];
            mid_sum_upper_reg <= mid_sum_reg[32:24];
            p_ll_final_reg    <= p_ll_reg_d1[15:0]; 
        end
    end

    // =========================================================================
    // STAGE 4: Final Addition and Assembly
    // Combinational logic feeding into Stage 5 Register
    // =========================================================================

    logic [63:0] p_comb; 

    // P[15:0] comes directly from the delayed LSBs
    assign p_comb[15:0]  = p_ll_final_reg;         
    
    // P[39:16] comes from the intermediate adder result
    assign p_comb[39:16] = p_first_24_reg[23:0];   
    
    // P[63:40] Summing:
    // P_HH[31:8] + P_MID[32:24] + Carry from previous stage
    assign p_comb[63:40] = p_hh_upper_reg 
                         + {15'b0, mid_sum_upper_reg} 
                         + {23'b0, p_first_24_reg[24]};

    // =========================================================================
    // STAGE 5: Output Registration
    // =========================================================================

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            P_REG <= '0;
        end else begin 
            P_REG <= p_comb;
        end
    end

endmodule

// =============================================================================
// SUBMODULE: MULT16
// =============================================================================

module MULT16 (
    input  logic        clk,
    input  logic        reset_n,
    input  logic [15:0] A,
    input  logic [15:0] B,
    output logic [31:0] P
);

    // Signal Decomposition
    logic [7:0] a_hi, a_lo;
    logic [7:0] b_hi, b_lo;

    assign a_hi = A[15:8];
    assign a_lo = A[7:0];
    assign b_hi = B[15:8];
    assign b_lo = B[7:0];

    // =========================================================================
    // STAGE 1: 8x8 Multipliers (Parallel)
    // Latency: 2 clock cycles (internal to MULT8)
    // =========================================================================
    logic [15:0] p_hh_comb, p_hl_comb, p_lh_comb, p_ll_comb;

    MULT8 mult8_hh (.clk(clk), .reset_n(reset_n), .A(a_hi), .B(b_hi), .P(p_hh_comb));
    MULT8 mult8_hl (.clk(clk), .reset_n(reset_n), .A(a_hi), .B(b_lo), .P(p_hl_comb));
    MULT8 mult8_lh (.clk(clk), .reset_n(reset_n), .A(a_lo), .B(b_hi), .P(p_lh_comb));
    MULT8 mult8_ll (.clk(clk), .reset_n(reset_n), .A(a_lo), .B(b_lo), .P(p_ll_comb));

    // Pipeline Registers
    logic [15:0] p_hh_reg, p_hl_reg, p_lh_reg, p_ll_reg;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            p_ll_reg <= '0;
            p_hl_reg <= '0;
            p_lh_reg <= '0;
            p_hh_reg <= '0;
        end else begin
            p_ll_reg <= p_ll_comb;
            p_hl_reg <= p_hl_comb;
            p_lh_reg <= p_lh_comb;
            p_hh_reg <= p_hh_comb;
        end 
    end

    // =========================================================================
    // STAGE 2: Term Alignment and Summation
    // Latency: 1 clock cycle
    // =========================================================================

    // Middle Sum: P_HL + P_LH
    logic [16:0] mid_sum_comb;
    assign mid_sum_comb = p_hl_reg + p_lh_reg;

    // Registers for Pipelining
    logic [16:0] mid_sum_reg;
    logic [15:0] p_hh_reg_d1;
    logic [15:0] p_ll_reg_d1;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            mid_sum_reg <= '0;
            p_hh_reg_d1 <= '0;
            p_ll_reg_d1 <= '0;
        end else begin
            mid_sum_reg <= mid_sum_comb;
            p_hh_reg_d1 <= p_hh_reg;
            p_ll_reg_d1 <= p_ll_reg;
        end
    end

    // =========================================================================
    // STAGE 3: Final Addition
    // =========================================================================
    assign P[7:0]  = p_ll_reg_d1[7:0];
    assign P[31:8] = {p_hh_reg_d1, 8'b0} + mid_sum_reg + {16'b0, p_ll_reg_d1[15:8]};

endmodule

// =============================================================================
// SUBMODULE: MULT8
// =============================================================================

module MULT8 (
    input  logic       clk,
    input  logic       reset_n,
    input  logic [7:0] A,
    input  logic [7:0] B,
    output logic [15:0] P
);
    // Signal Decomposition
    logic [3:0] a_hi, a_lo;
    logic [3:0] b_hi, b_lo;

    assign a_hi = A[7:4];
    assign a_lo = A[3:0];
    assign b_hi = B[7:4];
    assign b_lo = B[3:0];

    // =========================================================================
    // STAGE 1: Partial Product Generation (Parallel 4x4)
    // Latency: 1 clock cycle (internal)
    // =========================================================================
    logic [7:0] p_hh, p_hl, p_lh, p_ll;
    
    // Instantiations
    MULT4 mult4_hh (.A(a_hi), .B(b_hi), .P(p_hh));
    MULT4 mult4_hl (.A(a_hi), .B(b_lo), .P(p_hl));
    MULT4 mult4_lh (.A(a_lo), .B(b_hi), .P(p_lh));
    MULT4 mult4_ll (.A(a_lo), .B(b_lo), .P(p_ll));

    // Pipeline Registers
    logic [7:0] p_hh_reg, p_hl_reg, p_lh_reg, p_ll_reg;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            p_ll_reg <= '0;
            p_hl_reg <= '0;
            p_lh_reg <= '0;
            p_hh_reg <= '0;
        end else begin
            p_ll_reg <= p_ll;
            p_hl_reg <= p_hl;
            p_lh_reg <= p_lh;
            p_hh_reg <= p_hh;
        end
    end

    // =========================================================================
    // STAGE 2: Term Alignment and Summation
    // =========================================================================

    logic [8:0] mid_sum_comb;
    assign mid_sum_comb = p_hl_reg + p_lh_reg; 
    
    assign P[3:0]  = p_ll_reg[3:0];
    assign P[15:4] = {p_hh_reg, 4'h0} + mid_sum_comb + p_ll_reg[7:4];

endmodule

// =============================================================================
// SUBMODULE: MULT4
// =============================================================================

module MULT4 (
    input  logic [3:0] A, 
    input  logic [3:0] B,
    output logic [7:0] P
);
    assign P = (A * B);
endmodule
