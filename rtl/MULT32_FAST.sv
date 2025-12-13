module MULT32 (
    input logic clk, reset_n,
    input logic power_en,
    
    //Inputs
    input logic start_i,
    input logic [31:0] A,
    input logic [31:0] B,
    
    //Outputs
    output logic [63:0] P_REG,
    output logic valid_o
);

    // --- 1. Signal Decomposition ---
    logic [15:0] A_H, A_L, B_H, B_L;
    assign A_H = A[31:16]; assign A_L = A[15:0];
    assign B_H = B[31:16]; assign B_L = B[15:0];

    //--------------------STAGE 1--------------------
    // Instantiating 16x16 Multipliers
    logic [31:0] P_HH_raw, P_HL_raw, P_LH_raw, P_LL_raw;

    MULT16 u_hh (.clk(clk), .reset_n(reset_n), .A(A_H), .B(B_H), .P(P_HH_raw));
    MULT16 u_hl (.clk(clk), .reset_n(reset_n), .A(A_H), .B(B_L), .P(P_HL_raw));
    MULT16 u_lh (.clk(clk), .reset_n(reset_n), .A(A_L), .B(B_H), .P(P_LH_raw));
    MULT16 u_ll (.clk(clk), .reset_n(reset_n), .A(A_L), .B(B_L), .P(P_LL_raw));

    // Pipeline Registers (End of Stage 1)
    logic [31:0] P_HH_REG, P_HL_REG, P_LH_REG, P_LL_REG;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            P_LL_REG <= 0; 
            P_HL_REG <= 0; 
            P_LH_REG <= 0; 
            P_HH_REG <= 0;
        end else begin
            P_LL_REG <= P_LL_raw; 
            P_HL_REG <= P_HL_raw;
            P_LH_REG <= P_LH_raw; 
            P_HH_REG <= P_HH_raw;
        end
    end

    //---------------------STAGE 2----------------------------
    // Logic: Calculate Middle Sum and Lower-Middle Addition
    
    // 1. Middle Sum (33 bits)
    logic [32:0] P_MID_SUM;
    assign P_MID_SUM = P_HL_REG + P_LH_REG;

    // 2. The "First 24" Adder (Bits 16 to 39)
    // FIX 1: Alignment Correction
    // We are summing terms valid for bits [39:16].
    // - P_LL[31:16]:  Aligned to LSB of this adder (Bit 16)
    // - P_MID[23:0]:  Aligned to LSB of this adder (Bit 16)
    // - P_HH[7:0]:    Starts at Bit 32. Relative to Bit 16, this is +16.
    
    logic [24:0] P_first_24_comb; // 25 bits to capture carry out
    
    assign P_first_24_comb = {P_HH_REG[7:0], 16'b0}  // Shifted high!
                           + P_MID_SUM[23:0] 
                           + {8'b0, P_LL_REG[31:16]};

    // Pipeline Registers (End of Stage 2)
    // We must pass EVERYTHING needed for the final stage through registers.
    logic [24:0] P_first_24_REG;   // Result of the stage 2 adder
    logic [23:0] P_HH_UPPER_REG;   // Pass P_HH[31:8] to next stage
    logic [8:0]  P_MID_UPPER_REG;  // Pass P_MID[32:24] to next stage
    logic [15:0] P_LL_FINAL_REG;   // FIX 2: Delay LSBs to match timing!

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            P_first_24_REG  <= 0;
            P_HH_UPPER_REG  <= 0;
            P_MID_UPPER_REG <= 0;
            P_LL_FINAL_REG  <= 0;
        end else begin
            P_first_24_REG  <= P_first_24_comb;
            P_HH_UPPER_REG  <= P_HH_REG[31:8];
            P_MID_UPPER_REG <= P_MID_SUM[32:24];
            P_LL_FINAL_REG  <= P_LL_REG[15:0]; // Delaying LSBs
        end
    end

    //---------------------STAGE 3----------------------------
    // Final Addition and Output Assembly
    
    // 1. Final Upper Addition (Bits 40 to 63)
    // Inputs: P_HH upper part, P_MID upper part, and Carry from Stage 2.
    logic [23:0] P_upper_sum;
    

    
    // 2. Assemble Final Output
    // All parts are now aligned to the same clock cycle (Stage 3).
    assign P[15:0]  = P_LL_FINAL_REG;         // Delayed LSBs
    assign P[39:16] = P_first_24_REG[23:0];   // Middle result
    assign P[63:40] = P_HH_UPPER_REG 
                       + {15'b0, P_MID_UPPER_REG} 
                       + {23'b0, P_first_24_REG[24]}; // Add Carry

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            P_REG <= 0;
        end else begin
            P_REG <= P;
        end
    end

    // Valid Signal Pipeline (Depth = 4)
    logic [3:0] valid_pipe;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) 
            valid_pipe <= 4'd0;
        else 
            valid_pipe <= {valid_pipe[2:0], start_i & power_en};
    end
    assign valid_o = valid_pipe[3];

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






