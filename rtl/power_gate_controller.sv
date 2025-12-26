module power_gate_controller (
    input  logic       clk,
    input  logic       reset_n,
    input  logic       idle,
    input  logic       input_valid,
    input  logic       low_power,
    input  logic [1:0] branch,

    output logic       power_en_adder,
    output logic       power_en_mult,
    output logic       power_en_shifter,
    output logic       power_en_logic,
    output logic       power_en_adder_lp,
    output logic       power_en_mult_lp
);

    logic [3:0] sreg_adder;   // 4 cycles
    logic [8:0] sreg_mult;    // 9 cycles
    logic [2:0] sreg_shifter; // 3 cycles
    logic [2:0] sreg_logic;   // 3 cycles

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sreg_adder   <= 4'd0;
            sreg_mult    <= 9'd0;
            sreg_shifter <= 3'd0;
            sreg_logic   <= 3'd0;
        end else begin
            // Default: Shift right
            sreg_adder   <= sreg_adder >> 1;
            sreg_mult    <= sreg_mult >> 1;
            sreg_shifter <= sreg_shifter >> 1;
            sreg_logic   <= sreg_logic >> 1;

            // Load if active request and not idle and valid
            if (!idle && input_valid) begin
                if (low_power) begin
                    case (branch)
                        2'b00: sreg_adder   <= 4'b0111;
                        2'b01: sreg_mult    <= 9'b00000111;
                        2'b10: sreg_shifter <= 3'b111;
                        2'b11: sreg_logic   <= 3'b111;
                    endcase
                end else begin
                    case (branch)
                        2'b00: sreg_adder   <= 4'b1111;
                        2'b01: sreg_mult    <= 9'b111111111;
                        2'b10: sreg_shifter <= 3'b111;
                        2'b11: sreg_logic   <= 3'b111;
                    endcase
                end
            end
        end
    end

    // Disabling the particular block if staged out or idle
    always_comb begin
        power_en_adder   = sreg_adder[0]   | ((branch == 2'b00) && !idle && input_valid);
        power_en_mult    = sreg_mult[0]    | ((branch == 2'b01) && !idle && input_valid);
        power_en_shifter = sreg_shifter[0] | ((branch == 2'b10) && !idle && input_valid);
        power_en_logic   = sreg_logic[0]   | ((branch == 2'b11) && !idle && input_valid);
        
        power_en_adder_lp = power_en_adder && low_power;
        power_en_mult_lp  = power_en_mult  && low_power;
    end

endmodule
