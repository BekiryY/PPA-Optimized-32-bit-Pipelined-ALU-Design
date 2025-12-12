module MULT32 (
    input logic clk, reset_n,
    input logic [31:0] A,
    input logic [31:0] B,
    output logic [39:0] P_REG,
    output logic [63:0] P
);

    // --- 1. Signal Decomposition ---
    logic [15:0] A_H, A_L, B_H, B_L;

    assign A_H = A[31:16];
    assign A_L = A[15:0];
    assign B_H = B[31:16];
    assign B_L = B[15:0];

    //--------------------STAGE 1--------------------
    // --- 2. Instantiate 16x16 Multipliers (Parallel) ---
    // These modules take 3 clock cycles to produce a valid result.
    logic [31:0] P_HH_raw, P_HL_raw, P_LH_raw, P_LL_raw;

    MULT16 u_hh (.clk(clk), .reset_n(reset_n), .A(A_H), .B(B_H), .P(P_HH_raw));
    MULT16 u_hl (.clk(clk), .reset_n(reset_n), .A(A_H), .B(B_L), .P(P_HL_raw));
    MULT16 u_lh (.clk(clk), .reset_n(reset_n), .A(A_L), .B(B_H), .P(P_LH_raw));
    MULT16 u_ll (.clk(clk), .reset_n(reset_n), .A(A_L), .B(B_L), .P(P_LL_raw));

    // --- 3. Pipeline Stage 3 (Registering 16x16 Outputs) ---
    // Breaking the timing path after the 16x16 adders.
    logic [31:0] P_HH_REG, P_HL_REG, P_LH_REG, P_LL_REG;
    logic [23:0] P_HH_REG_REG;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            P_LL_REG <= 0;
            P_HL_REG <= 0;
            P_LH_REG <= 0;
            P_HH_REG <= 0;
        end
        else begin
            P_LL_REG <= P_LL_raw;
            P_HL_REG <= P_HL_raw;
            P_LH_REG <= P_LH_raw;
            P_HH_REG <= P_HH_raw;
        end
    end
    
    //---------------------STAGE 2----------------------------
    // --- 4. Term Alignment and Summation ---
    
    // Middle Sum: P_HL + P_LH
    // 32-bit + 32-bit = 33-bit result
    logic [32:0] P_MID_SUM;
    logic [8:0] P_MID_SUM_REG;
    assign P_MID_SUM = P_HL_REG + P_LH_REG;

    // --- Final Alignment (The 48-bit Adder) ---
    // P = (P_HH << 32) + (P_MID << 16) + P_LL
    
    // Bits [15:0] are passed directly from P_LL (LSB Bypass)
    assign P[15:0] = P_LL_REG[15:0];

    // Upper Summation (Bits 16 to 63)
    // We sum three terms starting at bit position 16.
    
    // Term 1: Upper half of P_LL (16 bits)
    // Value: P_LL_REG[31:16]
    
    // Term 2: P_MID_SUM (33 bits)
    // Value: P_MID_SUM (Aligned to bit 16)

    // Term 3: P_HH (32 bits)
    // Value: P_HH_REG (Shifted left by 16 relative to this adder's start)
    
    // We use concatenation to align P_HH correctly for the addition.
    // P_HH_REG becomes the top 32 bits, padding the bottom 16 bits with 0.
    
    // The calculation for P[63:16] (48 bits wide):

    logic [24:0] P_first_24;
    logic [24:0] P_first_24_REG;

    assign P_first_24 = P_HH_REG[7:0] + P_MID_SUM[23:0] + P_LL_REG[31:16];

    assign P[39:16] = P_first_24[23:0];

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            P_REG <= 0;
            P_first_24_REG <= 0;
            P_HH_REG_REG <= 0;
            P_MID_SUM_REG <= 0;
        end
        else begin
            P_REG <= P[39:0];
            P_first_24_REG <= P_first_24;
            P_HH_REG_REG <= P_HH_REG[31:8];
            P_MID_SUM_REG <= P_MID_SUM[32:24];
        end
    end

    //---------------------STAGE 3----------------------------
    // --- 5. Final Addition ---

    assign P[63:40] = P_HH_REG_REG + P_MID_SUM_REG + P_first_24_REG[24];

endmodule



module MULT16 (
    input logic clk, reset_n,
    input logic [15:0] A,
    input logic [15:0] B,
    output logic [31:0] P
);

    // --- 1. Signal Decomposition ---
    logic [7:0] A_H, A_L, B_H, B_L;

    assign A_H = A[15:8];
    assign A_L = A[7:0];
    assign B_H = B[15:8];
    assign B_L = B[7:0];

    //-------------------STAGE 1--------------------
    // --- 2. Instantiate 8x8 Multipliers (Parallel) ---
    // These modules take 2 clock cycles to produce a valid result.
    logic [15:0] P_HH_raw, P_HL_raw, P_LH_raw, P_LL_raw;

    MULT8 u_hh (.clk(clk), .reset_n(reset_n), .A(A_H), .B(B_H), .P(P_HH_raw));
    MULT8 u_hl (.clk(clk), .reset_n(reset_n), .A(A_H), .B(B_L), .P(P_HL_raw));
    MULT8 u_lh (.clk(clk), .reset_n(reset_n), .A(A_L), .B(B_H), .P(P_LH_raw));
    MULT8 u_ll (.clk(clk), .reset_n(reset_n), .A(A_L), .B(B_L), .P(P_LL_raw));

    // We register the outputs of the 8x8 mults to prevent the 
    // summation logic of 8x8 chaining directly into the summation of 16x16.
    logic [15:0] P_HH_REG, P_HL_REG, P_LH_REG, P_LL_REG;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            P_LL_REG <= 0;
            P_HL_REG <= 0;
            P_LH_REG <= 0;
            P_HH_REG <= 0;
        end
        else begin
            P_LL_REG <= P_LL_raw;
            P_HL_REG <= P_HL_raw;
            P_LH_REG <= P_LH_raw;
            P_HH_REG <= P_HH_raw;
        end
    end

    //--------------------------STAGE 3--------------------------
    // --- 4. Term Alignment and Summation ---

    // --- Final Alignment ---
    // P_LL contributes to bits [15:0]
    // P_MID_SUM contributes to bits [24:8] (Shifted left by 8)
    // P_HH contributes to bits [31:16] (Shifted left by 16)

    // Optimization: LSB Bypass

    // We need to sum three terms in the overlap region.
    
    // Term 1: P_LL upper byte
    logic [7:0] T1;
    assign T1 = P_LL_REG[15:8];

    
    // Middle Sum: P_HL + P_LH
    // 16-bit + 16-bit = 17-bit result
    logic [16:0] P_MID_SUM;
    assign P_MID_SUM = P_HL_REG + P_LH_REG;

    // Term 2: P_MID_SUM (17 bits)
    // This starts at bit 8, so it aligns with T1 at the bottom.
    logic [16:0] T2;
    assign T2 = P_MID_SUM;

    // Term 3: P_HH (16 bits)
    // This starts at bit 16. Relative to bit 8 (our summation start), 
    // it is shifted left by 8.
    logic [23:0] T3;
    assign T3 = {P_HH_REG, 8'b0}; 

    // Calculation:
    // P[31:8] = T3 + T2 + T1
    // (Note: T1 is 8 bits, T2 is 17 bits, T3 is effectively 24 bits relative to this window)
    
    // The addition width is 24 bits (from bit 8 to bit 31).
    assign P[7:0] = P_LL_REG[7:0];
    assign P[31:8] = T3 + T2 + {16'b0, T1};

endmodule


module MULT8 (
    input logic clk, reset_n,
    input logic [7:0] A,
    input logic [7:0] B,
    output logic [15:0] P
);
    // --- Signal Decomposition ---
    logic [3:0] A_H, A_L, B_H, B_L;

    assign A_H = A[7:4];
    assign A_L = A[3:0];
    assign B_H = B[7:4];
    assign B_L = B[3:0];

    //--------------------------STAGE 1--------------------------
    // --- 1. Partial Product (PP) Generation (Parallel 4x4) ---
    // These modules take 1 clock cycle to produce a valid result.
    // All four 4x4 multiplications run in parallel.
    logic [7:0] P_HH, P_HL, P_LH, P_LL; // All are 8-bit products
    logic [7:0] P_HH_REG, P_HL_REG, P_LH_REG, P_LL_REG; // Pipeline registers
    MULT4 u_hh (.A(A_H), .B(B_H), .P(P_HH)); // P_HH: (A_H * B_H)
    MULT4 u_hl (.A(A_H), .B(B_L), .P(P_HL)); // P_HL: (A_H * B_L)
    MULT4 u_lh (.A(A_L), .B(B_H), .P(P_LH)); // P_LH: (A_L * B_H)
    MULT4 u_ll (.A(A_L), .B(B_L), .P(P_LL)); // P_LL: (A_L * B_L)

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            P_LL_REG <= 0;
            P_HL_REG <= 0;
            P_LH_REG <= 0;
            P_HH_REG <= 0;
        end
        else begin
            P_LL_REG <= P_LL;
            P_HL_REG <= P_HL;
            P_LH_REG <= P_LH;
            P_HH_REG <= P_HH;
        end
    end

    //--------------------------STAGE 2--------------------------
    // --- 2. Term Alignment and Summation Reduction ---
    // The critical path is the final 12-bit addition.
 
    // Term 1 (P_LL): 8'h00 | P_LL
    logic [7:0] T1;
    assign T1 = P_LL_REG;

    // Term 2 (P_MID): (P_HL + P_LH) shifted left by 4
    // We must first compute P_HL + P_LH. This requires a fast 9-bit adder.
    logic [8:0] P_MID_SUM;
    assign P_MID_SUM = P_HL_REG + P_LH_REG; 
    logic [8:0] T2;
    assign T2 = P_MID_SUM;

    logic [11:0] T3;
    assign T3 = {P_HH_REG, 4'h0}; // Shift left by 4
    
    // We use the '+' operator, relying on the tool's fastest 16-bit adder.
    assign P[3:0] = T1[3:0];
    assign P[15:4] =  T3 + T2 + T1[7:4];
endmodule

module MULT4 (
    input [3:0] A, [3:0] B,
    output logic [7:0] P
);
    assign P = A * B; 
endmodule






