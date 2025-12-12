module ADDER32 (
	input  clk,
	input  reset_n,
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
logic C0_REG;
logic [31:0] A_REG;
logic [31:0] B_REG;
logic [15:0] P_REG; 
logic [15:0] G_REG; 
logic C15_REG; 
logic [15:0] sum_lower_reg;
logic [15:0] sum_lower_comb;

//MODE_SEL = 0 for addition
//MODE_SEL = 1 for subtraction
assign B_XORED = B ^ {32{MODE_SEL}};

PG16 PG16_0 (
.A(A_REG[15:0]),
.B(B_REG[15:0]),
.P(P[15:0]),
.G(G[15:0])
);

PG16 PG16_1 (
.A(A_REG[31:16]),
.B(B_REG[31:16]),
.P(P[31:16]),
.G(G[31:16])
);

always @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		A_REG <= 0;
		B_REG <= 0;
		P_REG <= 0;
		G_REG <= 0;
		C15_REG <= 0;
		C0_REG <= 0;
		sum_lower_reg <= 0;
	end 
	else begin
		A_REG <= A;
		B_REG <= B_XORED;
		P_REG <= P[31:16];
		G_REG <= G[31:16];
		C15_REG <= C[15];
		C0_REG <= C0;
		sum_lower_reg <= sum_lower_comb;
	end
end

CLA4 CLA4_0 (
.P(P[3:0]),
.G(G[3:0]),
.C0(C0_REG),
.C(C[3:0])
);

CLA4 CLA4_1 (
.P(P[7:4]),
.G(G[7:4]),
.C0(C[3]),
.C(C[7:4])
);

CLA4 CLA4_2 (
.P(P[11:8]),
.G(G[11:8]),
.C0(C[7]),
.C(C[11:8])
);

CLA4 CLA4_3 (
.P(P[15:12]),
.G(G[15:12]),
.C0(C[11]),
.C(C[15:12])
);

CLA4 CLA4_4 (
.P(P_REG[3:0]),
.G(G_REG[3:0]),
.C0(C15_REG),
.C(C[19:16])
);

CLA4 CLA4_5 (
.P(P_REG[7:4]),
.G(G_REG[7:4]),
.C0(C[19]),
.C(C[23:20])
);

CLA4 CLA4_6 (
.P(P_REG[11:8]),
.G(G_REG[11:8]),
.C0(C[23]),
.C(C[27:24])
);

CLA4 CLA4_7 (
.P(P_REG[15:12]),
.G(G_REG[15:12]),
.C0(C[27]),
.C(C[31:28])
);

SUM16 SUM16_0 (
.P(P[15:0]),
.C({C[14:0], C0_REG}),
.S(sum_lower_comb)
);

SUM16 SUM16_1 (
.P(P_REG[15:0]),
.C({C[30:16], C15_REG}),
.S(Y[31:16])
);
assign Y[15:0] = sum_lower_reg;
assign Y[32] = C[31];

endmodule

module PG16(
	input [15:0] A,
	input [15:0] B,
	output [15:0] P,
	output [15:0] G
	);
assign G = A & B;
assign	P = A ^ B;
endmodule

module CLA4(
    input [3:0] P,
    input [3:0] G,
    input C0,
    output [3:0] C
    );
// C[0] (Carry-out of stage 0, or C1) = G[0] + P[0] * C0
assign C[0] = G[0] | (P[0] & C0);

// C[1] (Carry-out of stage 1, or C2) = G[1] + P[1]*G[0] + P[1]*P[0]*C0
assign C[1] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & C0);

// C[2] (Carry-out of stage 2, or C3) = G[2] + P[2]*G[1] + P[2]*P[1]*G[0] + P[2]*P[1]*P[0]*C0
assign C[2] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & C0);

// C[3] (Carry-out of stage 3, or C4) = G[3] + P[3]*G[2] + P[3]*P[2]*G[1] + P[3]*P[2]*P[1]*G[0] + P[3]*P[2]*P[1]*P[0]*C0
assign C[3] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]) | (P[3] & P[2] & P[1] & P[0] & C0);
endmodule

module SUM16(
    input [15:0] P,
    input [15:0] C,
    output [15:0] S
    );
assign S = C ^ P;
endmodule
