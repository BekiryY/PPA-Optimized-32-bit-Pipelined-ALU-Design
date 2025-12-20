module MULT32 (
    input logic clk, reset_n,
    input logic power_en,
    
    //Inputs
    input logic [31:0] A,
    input logic [31:0] B,
    
    //Outputs
    output logic [63:0] P_REG,
);

    // --- 1. Signal Decomposition ---
    logic [15:0] A_H, A_L, B_H, B_L;
    assign A_H = A[31:16]; assign A_L = A[15:0];
    assign B_H = B[31:16]; assign B_L = B[15:0];

    //--------------------STAGE 1--------------------
    // Instantiating 16x16 Multipliers
    // These modules takes 4 clock cycles to complete
    logic [31:0] P_HH_raw, P_HL_raw, P_LH_raw, P_LL_raw;

    MULT16 MULT16_HH (.clk(clk), .reset_n(reset_n), .power_en(power_en), .A(A_H), .B(B_H), .P(P_HH_raw));
    MULT16 MULT16_HL (.clk(clk), .reset_n(reset_n), .power_en(power_en), .A(A_H), .B(B_L), .P(P_HL_raw));
    MULT16 MULT16_LH (.clk(clk), .reset_n(reset_n), .power_en(power_en), .A(A_L), .B(B_H), .P(P_LH_raw));
    MULT16 MULT16_LL (.clk(clk), .reset_n(reset_n), .power_en(power_en), .A(A_L), .B(B_L), .P(P_LL_raw));

    // Pipeline Registers (End of Stage 1)
    logic [31:0] P_HH_REG, P_HL_REG, P_LH_REG, P_LL_REG;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            P_LL_REG <= 0; 
            P_HL_REG <= 0; 
            P_LH_REG <= 0; 
            P_HH_REG <= 0;
        end else if (power_en) begin
            P_LL_REG <= P_LL_raw; 
            P_HL_REG <= P_HL_raw;
            P_LH_REG <= P_LH_raw; 
            P_HH_REG <= P_HH_raw;
        end else begin
            P_LL_REG <= 0; 
            P_HL_REG <= 0; 
            P_LH_REG <= 0; 
            P_HH_REG <= 0;
        end
    end

    //---------------------STAGE 2----------------------------
    // 32bit intermediate addition Calculate Middle Sum and Lower-Middle Addition
    // this will take 1 clock cycles to complete
    
    // 1. Middle Sum (33 bits)
    logic [32:0] P_MID_SUM;
    assign P_MID_SUM = P_HL_REG + P_LH_REG;

    // 2. The "First 24" Adder (Bits 16 to 39)
    // FIX 1: Alignment Correction
    // We are summing terms valid for bits [39:16].
    // - P_LL[31:16]:  Aligned to LSB of this adder (Bit 16)
    // - P_MID[23:0]:  Aligned to LSB of this adder (Bit 16)
    // - P_HH[7:0]:    Starts at Bit 32. Relative to Bit 16, this is +16.
    // Pipeline Registers for Alignment (Stage 2 Split)
    logic [32:0] P_MID_SUM_REG;
    logic [31:0] P_HH_REG_d1;
    logic [31:0] P_LL_REG_d1;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            P_MID_SUM_REG <= 0;
            P_HH_REG_d1 <= 0;
            P_LL_REG_d1 <= 0;
        end else if (power_en) begin
            P_MID_SUM_REG <= P_MID_SUM;
            P_HH_REG_d1 <= P_HH_REG;
            P_LL_REG_d1 <= P_LL_REG;
        end else begin
            P_MID_SUM_REG <= 0;
            P_HH_REG_d1 <= 0;
            P_LL_REG_d1 <= 0;
        end
    end

    //---------------------STAGE 3----------------------------
    // 24bit final addition P[40:17]
    // this will take 1 clock cycles to complete

    logic [24:0] P_first_24_comb; // 25 bits to capture carry out
    
    assign P_first_24_comb = {P_HH_REG_d1[7:0], 16'b0}  // Shifted high!
                           + P_MID_SUM_REG[23:0] 
                           + {8'b0, P_LL_REG_d1[31:16]};

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
        end else if (power_en) begin
            P_first_24_REG  <= P_first_24_comb; 
            // Use delayed versions to align with P_first_24_REG (which is now T+2 aligned)
            P_HH_UPPER_REG  <= P_HH_REG_d1[31:8];
            P_MID_UPPER_REG <= P_MID_SUM_REG[32:24];
            P_LL_FINAL_REG  <= P_LL_REG_d1[15:0]; 
        end else begin
            P_first_24_REG  <= 0;
            P_HH_UPPER_REG  <= 0;
            P_MID_UPPER_REG <= 0;
            P_LL_FINAL_REG  <= 0;
        end
    end

    //---------------------STAGE 4----------------------------
    // Final 24bit Addition and Output Assembly
    // this will take 1 clock cycle to complete

    // 1. Final Upper Addition (Bits 40 to 63)
    // Inputs: P_HH upper part, P_MID upper part, and Carry from Stage 2.
    logic [23:0] P_upper_sum;
    
    // 2. Assemble Final Output
    // All parts are now aligned to the same clock cycle (Stage 3).
    
    logic [63:0] P; // combinational result
    assign P[15:0]  = P_LL_FINAL_REG;         // Delayed LSBs
    assign P[39:16] = P_first_24_REG[23:0];   // Middle result
    assign P[63:40] = P_HH_UPPER_REG 
                       + {15'b0, P_MID_UPPER_REG} 
                       + {23'b0, P_first_24_REG[24]}; // Add Carry

    //---------------------STAGE 5----------------------------
    //registerin the output (wasting a cycle for accounting for non optimal output delay)

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            P_REG <= 0;
        end else if (power_en) begin
            P_REG <= P;
        end else begin
            P_REG <= 0;
        end
    end
endmodule

module MULT16 (
    input logic clk, reset_n,
    input logic power_en,
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

    MULT8 MULT8_HH (.clk(clk), .reset_n(reset_n), .power_en(power_en), .A(A_H), .B(B_H), .P(P_HH_raw));
    MULT8 MULT8_HL (.clk(clk), .reset_n(reset_n), .power_en(power_en), .A(A_H), .B(B_L), .P(P_HL_raw));
    MULT8 MULT8_LH (.clk(clk), .reset_n(reset_n), .power_en(power_en), .A(A_L), .B(B_H), .P(P_LH_raw));
    MULT8 MULT8_LL (.clk(clk), .reset_n(reset_n), .power_en(power_en), .A(A_L), .B(B_L), .P(P_LL_raw));

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
        else if (power_en) begin
            P_LL_REG <= P_LL_raw;
            P_HL_REG <= P_HL_raw;
            P_LH_REG <= P_LH_raw;
            P_HH_REG <= P_HH_raw;
        end else begin
            P_LL_REG <= 0;
            P_HL_REG <= 0;
            P_LH_REG <= 0;
            P_HH_REG <= 0;
        end
    end

    //--------------------------STAGE 2--------------------------
    // --- 2.    Term Alignment and Summation ---
    // here will take 1 clock cycle to complete

    // --- Final Alignment ---
    // P_LL contributes to bits [15:0]
    // P_MID_SUM contributes to bits [24:8] (Shifted left by 8)
    // P_HH contributes to bits [31:16] (Shifted left by 16)

    // Optimization: LSB Bypass

    // We need to sum three terms in the overlap region.
    
    // Middle Sum: P_HL + P_LH
    // 16-bit + 16-bit = 17-bit result
    logic [16:0] P_MID_SUM;
    assign P_MID_SUM = P_HL_REG + P_LH_REG;

    // Calculation:
    // The addition width is 24 bits (from bit 8 to bit 31).
    // Registers for Pipelining Middle Sum
    logic [16:0] P_MID_SUM_REG;
    logic [15:0] P_HH_REG_d1;
    logic [15:0] P_LL_REG_d1;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            P_MID_SUM_REG <= 0;
            P_HH_REG_d1 <= 0;
            P_LL_REG_d1 <= 0;
        end else if (power_en) begin
            P_MID_SUM_REG <= P_MID_SUM;
            P_HH_REG_d1 <= P_HH_REG;
            P_LL_REG_d1 <= P_LL_REG;
        end else begin
            P_MID_SUM_REG <= 0;
            P_HH_REG_d1 <= 0;
            P_LL_REG_d1 <= 0;
        end
    end
    //--------------------------STAGE 3--------------------------
    // final 24bit addition
    // here will take 1 clock cycle to complete

    always_comb begin
        if (!power_en) begin
            P = 32'h00000000;
        end else begin
            P[7:0] = P_LL_REG_d1[7:0];
            P[31:8] = {P_HH_REG_d1, 8'b0} + P_MID_SUM_REG + {16'b0, P_LL_REG_d1[15:8]};
        end
    end

endmodule

module MULT8 (
    input logic clk, reset_n,
    input logic power_en,
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
    MULT4 MULT4_HH (.power_en(power_en), .A(A_H), .B(B_H), .P(P_HH)); // P_HH: (A_H * B_H)
    MULT4 MULT4_HL (.power_en(power_en), .A(A_H), .B(B_L), .P(P_HL)); // P_HL: (A_H * B_L)
    MULT4 MULT4_LH (.power_en(power_en), .A(A_L), .B(B_H), .P(P_LH)); // P_LH: (A_L * B_H)
    MULT4 MULT4_LL (.power_en(power_en), .A(A_L), .B(B_L), .P(P_LL)); // P_LL: (A_L * B_L)

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            P_LL_REG <= 0;
            P_HL_REG <= 0;
            P_LH_REG <= 0;
            P_HH_REG <= 0;
        end
        else if (power_en) begin
            P_LL_REG <= P_LL;
            P_HL_REG <= P_HL;
            P_LH_REG <= P_LH;
            P_HH_REG <= P_HH;
        end else begin
            P_LL_REG <= 0;
            P_HL_REG <= 0;
            P_LH_REG <= 0;
            P_HH_REG <= 0;
        end
    end

    //--------------------------STAGE 2--------------------------
    // --- 2. Term Alignment and Summation Reduction ---
    // The critical path is the final 12-bit addition.

    // We must first compute P_HL + P_LH. This requires a fast 9-bit adder.
    logic [8:0] P_MID_SUM;
    assign P_MID_SUM = P_HL_REG + P_LH_REG; 
    
    always_comb begin
        if (!power_en) begin
            P = 16'h0000;
        end else begin
            P[3:0] = P_LL_REG[3:0];
            P[15:4] =  {P_HH_REG, 8'h00} + {P_MID_SUM[8:0], 4'h00} + {P_LL_REG[7:4], 4'h00};
        end
    end

endmodule

module MULT4 (
    input [3:0] A, [3:0] B,
    input logic power_en,
    output logic [7:0] P
);
    // Explicit Operand Isolation
    // When power_en is 0, inputs to the multiplier logic are forced to 0.
    // This prevents dynamic switching power in the multiplier logic.
    assign P = power_en ? A * B: 8'h00;

endmodule
