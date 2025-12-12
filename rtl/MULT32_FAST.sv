module MULT32 (
    input clk, reset_n,
    input [31:0] A,
    input [31:0] B,
    output logic [63:0] Y
);






module MULT_8x8 (
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

    // --- 1. Partial Product (PP) Generation (Parallel 4x4) ---
    // All four 4x4 multiplications run in parallel.

    logic [7:0] P_HH, P_HL, P_LH, P_LL; // All are 8-bit products

    MULT_4x4 u_hh (.A(A_H), .B(B_H), .P(P_HH)); // P_HH: (A_H * B_H)
    MULT_4x4 u_hl (.A(A_H), .B(B_L), .P(P_HL)); // P_HL: (A_H * B_L)
    MULT_4x4 u_lh (.A(A_L), .B(B_H), .P(P_LH)); // P_LH: (A_L * B_H)
    MULT_4x4 u_ll (.A(A_L), .B(B_L), .P(P_LL)); // P_LL: (A_L * B_L)

    // --- 2. Term Alignment and Summation Reduction ---
    // The critical path is the final 16-bit addition.
 
    // Term 1 (P_LL): 8'h00 | P_LL
    logic [7:0] Term_LL;
    assign Term_LL = P_LL};

    // Term 2 (P_MID): (P_HL + P_LH) shifted left by 4
    // We must first compute P_HL + P_LH. This requires a fast 9-bit adder.
    logic [8:0] P_MID_SUM;
    assign P_MID_SUM = P_HL + P_LH; 
    logic [8:0] Term_MID;
    assign Term_MID = P_MID_SUM

    logic [11:0] Term_HH;
    assign Term_HH = P_HH << 4; // Shift left by 4
    
    // We use the '+' operator, relying on the tool's fastest 16-bit adder.
    assign P[4:0] = Term_LL[4:0];
    assign P[15:4] =  Term_HH + Term_MID + Term_LL[7:4] ;
endmodule


module MULT_4x4 (
    input [3:0] A, [3:0] B,
    output logic [7:0] P
);
    assign P = A * B; 
endmodule











endmodule