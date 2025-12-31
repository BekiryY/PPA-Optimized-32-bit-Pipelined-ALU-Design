`timescale 1ns / 1ps

module ADDER32 (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        MODE_SEL,
    input  logic        C0,
    input  logic [31:0] A,
    input  logic [31:0] B,
    output logic [32:0] Y
);

    // =========================================================================
    // Internal Signals
    // =========================================================================
    logic [31:0] B_XORED;
    logic [31:0] C;
    logic [31:0] P;
    logic [31:0] G;


    // Pipeline Registers
    logic [15:0] P_REG;
    logic [15:0] G_REG;
    logic [15:0] P_lower_REG;    // Register for lower P bits to align with C_REG
    logic        C0_REG;         // C0 register (Carry-in)
    logic [14:0] C_REG;          // C[14:0] register
    logic        C15_REG;        // C[15] register explicitly defined

    // =========================================================================
    // Logic Implementation
    // =========================================================================

    // MODE_SEL = 0 for addition
    // MODE_SEL = 1 for subtraction
    assign B_XORED = B ^ {32{MODE_SEL}};

    // -------------------------------------------------------------------------
    // Propagate/Generate Logic
    // -------------------------------------------------------------------------
    PG16 PG16_0 (
        //.power_en (power_en), // Unused in original
        .A        (A[15:0]),
        .B        (B_XORED[15:0]),
        .P        (P[15:0]),
        .G        (G[15:0])
    );

    PG16 PG16_1 (
        //.power_en (power_en), // Unused in original
        .A        (A[31:16]),
        .B        (B_XORED[31:16]),
        .P        (P[31:16]),
        .G        (G[31:16])
    );

    // -------------------------------------------------------------------------
    // Pipeline Registers
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            P_REG       <= '0;
            G_REG       <= '0;
            P_lower_REG <= '0;
            C0_REG      <= '0;
            C_REG       <= '0;
            C15_REG     <= '0;
        end else begin
            P_REG       <= P[31:16];
            G_REG       <= G[31:16];
            P_lower_REG <= P[15:0]; // Capture P[15:0] for next stage
            C0_REG      <= C0;
            C_REG       <= C[14:0];
            C15_REG     <= C[15];
        end
    end

    // -------------------------------------------------------------------------
    // Carry Look Ahead Logic
    // -------------------------------------------------------------------------
    
    // CLA16 Instance for Lower 16 bits
    CLA16 CLA16_0 (

        .P        (P[15:0]),
        .G        (G[15:0]),
        .C0       (C0),
        .C        (C[15:0]),
        .Pg       (), // Open
        .Gg       ()  // Open
    );

    // CLA16 Instance for Upper 16 bits
    CLA16 CLA16_1 (

        .P        (P_REG[15:0]),
        .G        (G_REG[15:0]),
        .C0       (C15_REG),
        .C        (C[31:16]),
        .Pg       (), // Open
        .Gg       ()  // Open
    );

    // -------------------------------------------------------------------------
    // Sum Logic
    // -------------------------------------------------------------------------
    
    SUM16 SUM16_0 (
        .P        (P_lower_REG),            // Use registered P to match C_REG timing
        .C        ({C_REG[14:0], C0_REG}),
        .S        (Y[15:0])
    );

    SUM16 SUM16_1 (
        .P        (P_REG[15:0]),
        .C        ({C[30:16], C15_REG}),
        .S        (Y[31:16])
    );

    // -------------------------------------------------------------------------
    // Output Logic
    // -------------------------------------------------------------------------
    assign Y[32] = C[31]; // Carry out of the ADDER

endmodule

// =============================================================================
// Submodules
// =============================================================================

module PG16 (
    input  logic [15:0] A,
    input  logic [15:0] B,
    output logic [15:0] P,
    output logic [15:0] G
);
    assign G = A & B;
    assign P = A ^ B;
endmodule

module carry_calculator (
    input  logic [3:0] P,     // Group Propagate
    input  logic [3:0] G,     // Group Generate
    input  logic       C0,
    output logic [2:0] C_int  // Looks ahead for C1, C2, C3
);
    assign C_int[0] = (G[0] | (P[0] & C0));
    assign C_int[1] = (G[1] | (P[1] & G[0]) | (P[1] & P[0] & C0));
    assign C_int[2] = (G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & C0));
endmodule

module CLA16 (

    input  logic [15:0] P,
    input  logic [15:0] G,
    input  logic        C0,
    output logic [15:0] C,
    output logic        Pg,
    output logic        Gg
);
    logic [3:0] Pg_int;
    logic [3:0] Gg_int;
    logic [2:0] C_int; // Internal carries between CLA4 blocks

    // Block 0
    assign Pg_int[0] = &P[3:0];
    assign Gg_int[0] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]);

    // Block 1
    assign Pg_int[1] = &P[7:4];
    assign Gg_int[1] = G[7] | (P[7] & G[6]) | (P[7] & P[6] & G[5]) | (P[7] & P[6] & P[5] & G[4]);

    // Block 2
    assign Pg_int[2] = &P[11:8];
    assign Gg_int[2] = G[11] | (P[11] & G[10]) | (P[11] & P[10] & G[9]) | (P[11] & P[10] & P[9] & G[8]);

    // Block 3
    assign Pg_int[3] = &P[15:12];
    assign Gg_int[3] = G[15] | (P[15] & G[14]) | (P[15] & P[14] & G[13]) | (P[15] & P[14] & P[13] & G[12]);

    // Use carry_calculator for C_int
    carry_calculator cc_inst (

        .P        (Pg_int),
        .G        (Gg_int),
        .C0       (C0),
        .C_int    (C_int)
    );

    // Group Propagate and Generate for CLA16
    assign Pg = &Pg_int;
    assign Gg = Gg_int[3] | (Pg_int[3] & Gg_int[2]) | (Pg_int[3] & Pg_int[2] & Gg_int[1]) | (Pg_int[3] & Pg_int[2] & Pg_int[1] & Gg_int[0]);

    CLA4 CLA4_0 (

        .P        (P[3:0]), 
        .G        (G[3:0]), 
        .C0       (C0),
        .C        (C[3:0])
    );

    CLA4 CLA4_1 (

        .P        (P[7:4]), 
        .G        (G[7:4]), 
        .C0       (C_int[0]),
        .C        (C[7:4])
    );

    CLA4 CLA4_2 (

        .P        (P[11:8]), 
        .G        (G[11:8]), 
        .C0       (C_int[1]),
        .C        (C[11:8])
    );

    CLA4 CLA4_3 (

        .P        (P[15:12]), 
        .G        (G[15:12]), 
        .C0       (C_int[2]),
        .C        (C[15:12])
    );
endmodule

module CLA4 (
    input  logic [3:0] P,
    input  logic [3:0] G,
    input  logic       C0,
    output logic [3:0] C
);
    // C[0] (Carry-out of stage 0, or C1)
    assign C[0] = (G[0] | (P[0] & C0));

    // C[1] (Carry-out of stage 1, or C2)
    assign C[1] = (G[1] | (P[1] & G[0]) | (P[1] & P[0] & C0));

    // C[2] (Carry-out of stage 2, or C3)
    assign C[2] = (G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & C0));

    // C[3] (Carry-out of stage 3, or C4)
    assign C[3] = (G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]) | (P[3] & P[2] & P[1] & P[0] & C0));
endmodule

module SUM16 (
    input  logic [15:0] P,
    input  logic [15:0] C,
    output logic [15:0] S
);
    assign S = (C ^ P);
endmodule
