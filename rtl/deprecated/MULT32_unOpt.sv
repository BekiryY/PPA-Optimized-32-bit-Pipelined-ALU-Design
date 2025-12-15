module MULT32_8x8_Pipe_unOpt (
    input clk, reset_n,
    input [31:0] A,
    input [31:0] B,
    output logic [63:0] Y
);

    // 1. Break inputs into bytes
    logic [7:0] a[3:0]; // a[0] is A[7:0], a[1] is A[15:8]...
    logic [7:0] b[3:0];
    
    assign a[0] = A[7:0],   a[1] = A[15:8],  a[2] = A[23:16], a[3] = A[31:24];
    assign b[0] = B[7:0],   b[1] = B[15:8],  b[2] = B[23:16], b[3] = B[31:24];

    // --- STAGE 1: The 16 Multipliers ---
    // We store the results in a 2D array for easy indexing
    logic [15:0] partials [3:0][3:0]; 
    logic [15:0] partials_reg [3:0][3:0];

    genvar i, j;
    generate
        for (i=0; i<4; i++) begin : ROW
            for (j=0; j<4; j++) begin : COL
                // Combinational 8x8 multiplication
                assign partials[i][j] = a[i] * b[j];
                
                // Pipeline Register 1
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

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            P_LL <= 0; P_LH <= 0; P_HL <= 0; P_HH <= 0;
        end else begin
            // Reconstruct Lower-Lower (A[15:0] * B[15:0])
            // Uses partials[1][1], [1][0], [0][1], [0][0]
            P_LL <= (partials_reg[1][1] << 16) + 
                    ((partials_reg[1][0] + partials_reg[0][1]) << 8) + 
                    partials_reg[0][0];

            // Reconstruct Lower-High (A[15:0] * B[31:16])
            P_LH <= (partials_reg[1][3] << 16) + 
                    ((partials_reg[1][2] + partials_reg[0][3]) << 8) + 
                    partials_reg[0][2];

            // Reconstruct High-Lower (A[31:16] * B[15:0])
            P_HL <= (partials_reg[3][1] << 16) + 
                    ((partials_reg[3][0] + partials_reg[2][1]) << 8) + 
                    partials_reg[2][0];

            // Reconstruct High-High (A[31:16] * B[31:16])
            P_HH <= (partials_reg[3][3] << 16) + 
                    ((partials_reg[3][2] + partials_reg[2][3]) << 8) + 
                    partials_reg[2][2];
        end
    end

    // --- STAGE 3: Final Summation ---
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) Y <= 0;
        else begin
            // Combine the four 32-bit chunks
            Y <= (P_HH << 32) + ((P_HL + P_LH) << 16) + P_LL;
        end
    end

endmodule