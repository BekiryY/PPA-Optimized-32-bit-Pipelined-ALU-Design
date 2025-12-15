module MULT32_Karatsuba_Pipe (
    input clk, reset_n,
    input [31:0] A,
    input [31:0] B,
    output logic [63:0] Y
);



    // --- STAGE 1: Pre-Addition & Setup ---
    logic [15:0] A_L_reg, A_H_reg, B_L_reg, B_H_reg;
    logic [16:0] Sum_A_reg, Sum_B_reg; // 17 bits to catch overflow!

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            A_L_reg <= 0; A_H_reg <= 0; B_L_reg <= 0; B_H_reg <= 0;
            Sum_A_reg <= 0; Sum_B_reg <= 0;
        end else begin
            A_L_reg <= A[15:0];
            A_H_reg <= A[31:16];
            B_L_reg <= B[15:0];
            B_H_reg <= B[31:16];
            // The Karatsuba Pre-Adders
            Sum_A_reg <= A[15:0] + A[31:16]; 
            Sum_B_reg <= B[15:0] + B[31:16];
        end
    end

    // --- STAGE 2: The Three Multiplications ---
    // Note: Z1 is 17x17, so result is 34 bits
    logic [31:0] Z0, Z2; 
    logic [33:0] Z1; 

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

    // In a real ASIC/FPGA flow, you might instantiate specific sub-modules here
    // to ensure these finish in time. For readability, I use *
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            Z0 <= 0; Z1 <= 0; Z2 <= 0;
        end else begin
            Z0 <= A_L_reg * B_L_reg;         // Low part
            Z2 <= A_H_reg * B_H_reg;         // High part
            Z1 <= Sum_A_reg * Sum_B_reg;     // Middle part (17x17)
        end
    end

    // --- STAGE 3: Reconstruction (Subtract & Shift) ---
    // Karatsuba Formula: Middle_Term = Z1 - Z2 - Z0
    // Result = (Z2 << 32) + (Middle_Term << 16) + Z0
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) Y <= 0;
        else begin
            // We combine the subtraction and shifting into one logic block
            // to help synthesis optimize the carry chains.
            // Note: We use 64 bits to prevent overflow during intermediate sums
            logic [63:0] middle_term;
            
            // Calculate (Z1 - Z2 - Z0)
            // Note: This subtraction can result in a "negative" if treated as signed,
            // but in unsigned modular arithmetic, it works out correctly when added back.
            middle_term = Z1 - Z2 - Z0; 
            
            Y <= (Z2 << 32) + (middle_term << 16) + Z0;
        end
    end

endmodule