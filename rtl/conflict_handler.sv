`timescale 1ns / 1ps

module conflict_handler(
    input logic idle,
    input logic valid_mult,
    input logic valid_adder,
    input logic valid_comb,
    input logic [31:0] adder_out,
    input logic [31:0] comb_out,
    
    output logic [31:0] Y_conflict,
    output logic conflict_valid
);

    always_comb begin
        Y_conflict = 32'd0;
        conflict_valid = 1'b0;
        if(!idle) begin
            if (valid_mult) begin
                if (valid_comb) begin
                    // Conflict Mult vs Comb. Comb is least important.
                    Y_conflict = comb_out;
                    conflict_valid = 1'b1;
                end else if (valid_adder) begin
                    // Conflict Mult vs Adder. Adder is least important.
                    Y_conflict = adder_out;
                    conflict_valid = 1'b1;
                end
            end else if (valid_adder) begin
                if (valid_comb) begin
                    // Conflict Adder vs Comb. Comb is least important.
                    Y_conflict = comb_out;
                    conflict_valid = 1'b1;
                end
            end
        end
    end

endmodule
