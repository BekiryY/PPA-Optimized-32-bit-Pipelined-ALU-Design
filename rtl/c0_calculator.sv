module c0_calculator (
    input  logic        clk,
    input  logic        reset_n,
    input  logic [2:0]  CMD,
    input  logic        CF_reg,
    output logic        C0,
    output logic        adder_mode
);
    logic CF_reg_delayed;

    assign adder_mode = CMD[0] | CMD[1];
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            CF_reg_delayed <= CF_reg;
        end else begin
            CF_reg_delayed <= CF_reg;
        end
    end

    always_comb begin
        case (CMD)
            3'b000:  C0 = 1'b0;      // ADD
            3'b001:  C0 = 1'b1;      // SUB
            3'b010:  C0 = 1'b1;      // GT
            3'b011:  C0 = 1'b1;      // LT
            3'b100:  C0 = CF_reg_delayed;    // ADDC
            3'b101:  C0 = CF_reg_delayed;    // SUBC
            3'b110:  C0 = 1'b1;    // SUB
            3'b111:  C0 = 1'b1;    // SUB
            default: C0 = 1'b0;
        endcase
    end

endmodule
