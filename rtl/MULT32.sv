module MULT32_8x8_Pipe (
    input clk, reset_n,
    input [31:0] A,
    input [31:0] B,
    output logic [63:0] Y
);

    // 1. Break inputs into bytes
    logic [7:0] a[3:0]; // a[0] is A[7:0], a[1] is A[15:8]...
    logic [7:0] b[3:0];
    logic [31:0] A_REG;
    logic [31:0] B_REG;
    
    assign a[0] = A_REG[7:0],   a[1] = A_REG[15:8],  a[2] = A_REG[23:16], a[3] = A_REG[31:24];
    assign b[0] = B_REG[7:0],   b[1] = B_REG[15:8],  b[2] = B_REG[23:16], b[3] = B_REG[31:24];

    // --- STAGE 1: The 16 Multipliers ---
    // We store the results in a 2D array for easy indexing
    logic [15:0] partials [3:0][3:0]; 
    logic [15:0] partials_reg [3:0][3:0]; 

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

    genvar i, j;
    generate
        for (i=0; i<4; i++) begin : ROW
            for (j=0; j<4; j++) begin : COL
                // Combinational 8x8 multiplication
                assign partials[i][j] = a[i] * b[j];
                always @(posedge clk or negedge reset_n) begin
                    if (!reset_n) partials_reg[i][j] <= 0;
                    else partials_reg[i][j] <= partials[i][j]; 
                end
            end
        end
    endgenerate

    // --- STAGE 2: Reconstruct 16x16 Blocks ---
    // We need to form 4 "Mega Products" (16x16 equivalents)
    // Each 16x16 is made of 4 small partials: (HiHi, HiLo, LoHi, LoLo)
    logic [31:0] P_LL, P_LH, P_HL, P_HH;

 // --- STAGE 2: Reconstruct 16x16 Blocks (Optimized) ---
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            P_LL <= 0; P_LH <= 0; P_HL <= 0; P_HH <= 0;
        end else begin
            // ---------------------------------------------------------
            // 1. Reconstruct P_LL (A[15:0] * B[15:0])
            // ---------------------------------------------------------
            // Bits [7:0] are free (come only from partials[0][0])
            P_LL[7:0]  <= partials_reg[0][0][7:0];
            
            // Bits [31:8] require addition. 
            // We sum: Upper half of [0][0] + Middle terms + (Top term shifted)
            P_LL[31:8] <= partials_reg[0][0][15:8] + 
                          partials_reg[1][0] + 
                          partials_reg[0][1] + 
                          (partials_reg[1][1] << 8);

            // ---------------------------------------------------------
            // 2. Reconstruct P_LH (A[15:0] * B[31:16])
            // ---------------------------------------------------------
            // Uses indices: [0][2], [0][3], [1][2], [1][3]
            P_LH[7:0]  <= partials_reg[0][2][7:0];
            
            P_LH[31:8] <= partials_reg[0][2][15:8] + 
                          partials_reg[1][2] + 
                          partials_reg[0][3] + 
                          (partials_reg[1][3] << 8);

            // ---------------------------------------------------------
            // 3. Reconstruct P_HL (A[31:16] * B[15:0])
            // ---------------------------------------------------------
            // Uses indices: [2][0], [2][1], [3][0], [3][1]
            P_HL[7:0]  <= partials_reg[2][0][7:0];
            
            P_HL[31:8] <= partials_reg[2][0][15:8] + 
                          partials_reg[3][0] + 
                          partials_reg[2][1] + 
                          (partials_reg[3][1] << 8);

            // ---------------------------------------------------------
            // 4. Reconstruct P_HH (A[31:16] * B[31:16])
            // ---------------------------------------------------------
            // Uses indices: [2][2], [2][3], [3][2], [3][3]
            P_HH[7:0]  <= partials_reg[2][2][7:0];
            
            P_HH[31:8] <= partials_reg[2][2][15:8] + 
                          partials_reg[3][2] + 
                          partials_reg[2][3] + 
                          (partials_reg[3][3] << 8);
        end
    end

// --- STAGE 3: Final Summation (Optimized) ---
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) Y <= 0;
        else begin
            // 1. The Lower 16 bits are "free" (No adder logic needed)
            Y[15:0] <= P_LL[15:0];

            // 2. The Upper 48 bits need an adder
            //    We calculate Y[63:16]. 
            //    To align the math, we look at what lives at bit 16 and above:
            //    - P_HH starts at bit 32 (which is bit 16 of this upper slice) -> Shift left 16
            //    - P_HL and P_LH start at bit 16 (bit 0 of this upper slice) -> No Shift
            //    - P_LL's upper half is at bit 16 (bit 0 of this upper slice) -> No Shift
            
            Y[63:16] <= (P_HH << 16) + P_HL + P_LH + P_LL[31:16];
        end
    end

endmodule