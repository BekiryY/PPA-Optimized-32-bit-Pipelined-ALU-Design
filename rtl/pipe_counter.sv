module pipe_counter (
    input  logic       clk,
    input  logic       reset_n,
    input  logic       input_valid,
    input  logic [4:0] CMD,
    input  logic       low_power,
    input  logic       idle,

    output logic       output_valid,
    output logic       v_add_r,
    output logic       v_mul_r,
    output logic       v_shift_r
);

    // Internal Shift Registers for Valid Signals
    // Adder: 3 stages (Indices 0, 1, 2. Output is [2])
    logic [2:0] add_valid_pipe;
    // Multiplier: 8 stages (Indices 0..7. Output is [7])
    logic [7:0] mul_valid_pipe;
    // Shifter: 2 stages (Indices 0, 1. Output is [1])
    logic [1:0] shift_valid_pipe;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            add_valid_pipe   <= '0;
            mul_valid_pipe   <= '0;
            shift_valid_pipe <= '0;
        end else begin
            // Shift in new valid flags (LSB in, MSB out)
            // LSB is T=1 (next cycle after input_valid)
            // MSB is Output Valid
            if (!idle && !low_power) begin
                // Adder (Opcode 00)
                add_valid_pipe <= {add_valid_pipe[1:0], (input_valid && CMD[4:3] == 2'b00)};
                
                // Multiplier (Opcode 01)
                // 8 Stages total pipeline delay
                mul_valid_pipe <= {mul_valid_pipe[6:0], (input_valid && CMD[4:3] == 2'b01)};
                
                // Shifter (Opcode 10)
                shift_valid_pipe <= {shift_valid_pipe[0], (input_valid && CMD[4:3] == 2'b10)};
            end else begin
                // If idle or low power, flush the pipeline
                add_valid_pipe   <= {add_valid_pipe[1:0], 1'b0};
                mul_valid_pipe   <= {mul_valid_pipe[6:0], 1'b0};
                shift_valid_pipe <= {shift_valid_pipe[0], 1'b0};
            end
        end
    end

    // Assign Outputs (MSB is the result of the full latency)
    assign v_add_r   = add_valid_pipe[2];
    assign v_mul_r   = mul_valid_pipe[7];
    assign v_shift_r = shift_valid_pipe[1];

    // Output Valid Handling
    always_comb begin
        if (low_power) begin
            if(!idle) begin
                output_valid = input_valid; // Combinational in LP
            end else begin 
                output_valid = 1'b0;
            end 
        end else begin
            if(!idle) begin
                // Check valid flags from end of pipeline
                if (v_mul_r)      output_valid = 1'b1;
                else if (v_add_r) output_valid = 1'b1;
                else if (v_shift_r) output_valid = 1'b1;
                
                // Logic Block (Opcode 11) is 0 cycle latency (Combinational)
                else if (CMD[4:3] == 2'b11) output_valid = input_valid; 
                else output_valid = 1'b0;
            end else begin 
                output_valid = 1'b0;
            end
        end
    end

endmodule
