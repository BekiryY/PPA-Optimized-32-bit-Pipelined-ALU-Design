module ADDER32 (
	input  clk, reset_n,
    input logic power_en,
	input  MODE_SEL,
    input  C0,
    input  [31:0] A,
    input  [31:0] B,
    output logic [32:0] Y
);

logic [31:0] B_XORED;
logic [31:0] C;
logic [31:0] P;
logic [31:0] G;
logic [32:0] Y_intermediate; //for power_en 

//Registered values for pipeline
logic [15:0] P_REG; 
logic [15:0] G_REG;
logic [15:0] P_lower_REG; // ADDED: Register for lower P bits to align with C_REG
logic C0_REG;       //C0 register (Carry-in) (different than C[0])
logic [14:0] C_REG; //C[15] explicitly defined as C15_REG
logic C15_REG; 	 	//C15 register 

//MODE_SEL = 0 for addition
//MODE_SEL = 1 for subtraction
assign B_XORED = B ^ {32{MODE_SEL}};

PG16 PG16_0 (
.A(A[15:0]),
.B(B_XORED[15:0]),
.P(P[15:0]),
.G(G[15:0])
);

PG16 PG16_1 (
.A(A[31:16]),
.B(B_XORED[31:16]),
.P(P[31:16]),
.G(G[31:16])
);

always @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		P_REG <= 0;
		G_REG <= 0;
        P_lower_REG <= 0; // Reset new register
		C0_REG <= 0;
		C_REG <= 0;
		C15_REG <= 0;
	end 
	else begin
        if (!power_en) begin
            P_REG <= 0;
            G_REG <= 0;
            P_lower_REG <= 0; // Reset new register
            C0_REG <= 0;
            C_REG <= 0;
            C15_REG <= 0;
        end else begin
            P_REG <= P[31:16];
            G_REG <= G[31:16];
            P_lower_REG <= P[15:0]; // Capture P[15:0] for next stage
            C0_REG <= C0;
            C_REG <= C[14:0];
            C15_REG <= C[15];
    	end
    end
end

// CLA16 Instance for Lower 16 bits
CLA16 CLA16_0 (
    .power_en(power_en),
    .P(P[15:0]),
    .G(G[15:0]),
    .C0(C0),
    .C(C[15:0])
);

// CLA16 Instance for Upper 16 bits
CLA16 CLA16_1 (
    .power_en(power_en),
    .P(P_REG[15:0]),
    .G(G_REG[15:0]),
    .C0(C15_REG),
    .C(C[31:16])
);

SUM16 SUM16_0 (
.power_en(power_en),
.P(P_lower_REG), // Use registered P to match C_REG timing
.C({C_REG[14:0], C0_REG}),
.S(Y_intermediate[15:0])
);

SUM16 SUM16_1 (
.power_en(power_en),
.P(P_REG[15:0]),
.C({C[30:16], C15_REG}),
.S(Y_intermediate[31:16])
);

always_comb begin
    // --- POWER GATING CLAMP/ISOLATION LOGIC ---
    if (!power_en) begin
        Y = 32'h0;      // Clamp outpuwt to 0 when sleeping (essential Isolation Cell function)
    end 
    else begin
        Y[31:0] = Y_intermediate[31:0];
        Y[32] = C[31];      //Carry out of the ADDER
    end
end

endmodule

module PG16(
    input power_en,
	input [15:0] A,
	input [15:0] B,
	output [15:0] P,
	output [15:0] G
	);
assign G = A & B;
assign	P = A ^ B;
endmodule

module carry_calculator(
    input power_en,
    input [3:0] P, // Group Propagate
    input [3:0] G, // Group Generate
    input C0,
    output [2:0] C_int // Looks ahead for C1, C2, C3 (block inputs)
);
    assign C_int[0] = power_en ? (G[0] | (P[0] & C0)) : 1'b0;
    assign C_int[1] = power_en ? (G[1] | (P[1] & G[0]) | (P[1] & P[0] & C0)) : 1'b0;
    assign C_int[2] = power_en ? (G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & C0)) : 1'b0;
endmodule

module CLA16(
    input power_en,
    input [15:0] P,
    input [15:0] G,
    input C0,
    output [15:0] C,
    output Pg,
    output Gg
);
    logic [3:0] Pg_int;
    logic [3:0] Gg_int;
    logic [2:0] C_int; // Internal carries between CLA4 blocks

    // Internal generation of Pg/Gg for blocks, since removed from CLA4
    
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
        .power_en(power_en),
        .P(Pg_int),
        .G(Gg_int),
        .C0(C0),
        .C_int(C_int)
    );

    // Group Propagate and Generate for CLA16
    assign Pg = &Pg_int;
    assign Gg = Gg_int[3] | (Pg_int[3] & Gg_int[2]) | (Pg_int[3] & Pg_int[2] & Gg_int[1]) | (Pg_int[3] & Pg_int[2] & Pg_int[1] & Gg_int[0]);

    CLA4 CLA4_0 (
        .power_en(power_en),
        .P(P[3:0]), .G(G[3:0]), .C0(C0),
        .C(C[3:0])
    );

    CLA4 CLA4_1 (
        .power_en(power_en),
        .P(P[7:4]), .G(G[7:4]), .C0(C_int[0]),
        .C(C[7:4])
    );

    CLA4 CLA4_2 (
        .power_en(power_en),
        .P(P[11:8]), .G(G[11:8]), .C0(C_int[1]),
        .C(C[11:8])
    );

    CLA4 CLA4_3 (
        .power_en(power_en),
        .P(P[15:12]), .G(G[15:12]), .C0(C_int[2]),
        .C(C[15:12])
    );
endmodule

module CLA4(
    input power_en,
    input [3:0] P,
    input [3:0] G,
    input C0,
    output [3:0] C
    );
    
    // C[0] (Carry-out of stage 0, or C1) = G[0] + P[0] * C0
    assign C[0] = power_en ? (G[0] | (P[0] & C0)) : 1'b0;

    // C[1] (Carry-out of stage 1, or C2) = G[1] + P[1]*G[0] + P[1]*P[0]*C0
    assign C[1] = power_en ? (G[1] | (P[1] & G[0]) | (P[1] & P[0] & C0)) : 1'b0;

    // C[2] (Carry-out of stage 2, or C3) = G[2] + P[2]*G[1] + P[2]*P[1]*G[0] + P[2]*P[1]*P[0]*C0
    assign C[2] = power_en ? (G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & C0)) : 1'b0;

    // C[3] (Carry-out of stage 3, or C4) = G[3] + P[3]*G[2] + P[3]*P[2]*G[1] + P[3]*P[2]*P[1]*G[0] + P[3]*P[2]*P[1]*P[0]*C0
    assign C[3] = power_en ? (G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]) | (P[3] & P[2] & P[1] & P[0] & C0)) : 1'b0;
endmodule

module SUM16(
    input power_en,
    input [15:0] P,
    input [15:0] C,
    output [15:0] S
    );
    
assign S = power_en ? (C ^ P) : 16'b0;
endmodule
