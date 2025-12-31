module pipe_counter (
    input  logic       clk,
    input  logic       reset_n,
    input  logic       input_valid,
    input  logic [4:0] CMD,
    input  logic       low_power,
    input  logic       idle,

    output logic       output_valid,
    output logic [2:0] v_add_r,
    output logic [6:0] v_mul_r,
    output logic [2:0] v_shift_r
);

    logic [1:0] cmd_add_r;      // Delayed CMD for Adder (1 cycle)
    logic [13:0] cmd_mul_r;     // Delayed CMD for Mult (7 cycles of 2 bits)
    
    logic [1:0] add_delay_line; // 2 bits for intermediate stages
    logic       shift_delay_line; // 1 bit for intermediate stage (Latency=2: Del0 -> v_shift_r)

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            v_add_r         <= 1'b0;
            v_mul_r         <= 7'd0;
            v_shift_r       <= 1'b0;
            cmd_add_r       <= 2'b00;
            cmd_mul_r       <= 14'd0;
            add_delay_line  <= 2'd0;
            shift_delay_line <= 1'b0;
        end else begin
            // Pipeline valid signals
            // Adder Latency = 3 cycles.
            add_delay_line[0] <= input_valid & (CMD[4:3] == 2'b00) & !low_power;
            add_delay_line[1] <= add_delay_line[0];
            v_add_r           <= add_delay_line[1];
            
            // Shifter Latency = 2 cycles.
            // Cycle 1: shift_delay_line
            // Cycle 2: v_shift_r
            shift_delay_line <= input_valid & (CMD[4:3] == 2'b10) & !low_power;
            v_shift_r        <= shift_delay_line;

            v_mul_r <= {v_mul_r[5:0], input_valid & (CMD[4:3] == 2'b01) & !low_power};
            
            // Pipeline command bits (CMD[4:3]) to match latency
            // Adder path: 1 cycle delay
            if(input_valid && !low_power) cmd_add_r <= CMD[4:3];
            
            // Multiplier path: 7 cycle delay (shift register for 2 bits)
            if(input_valid && !low_power) begin 
                 cmd_mul_r <= {cmd_mul_r[11:0], CMD[4:3]};
            end else begin
                 // Keep shifting to propagate the pipeline even if new input isn't valid? 
                 // Actually, for a fixed pipeline, we should always shift.
                 cmd_mul_r <= {cmd_mul_r[11:0], (input_valid ? CMD[4:3] : 2'b00)}; 
                 // Note: If input not valid, pushing 00 is risky if 00 is Adder. 
                 // Better to just shift. Realistically, we only care about the value when v_mul_r[6] is 1.
            end
        end
    end

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
                // Prioritize Multiplier completion if valid, then Adder, etc.
                if (v_mul_r[6]) output_valid = 1'b1;
                else if (v_add_r) output_valid = 1'b1;
                else if (v_shift_r) output_valid = 1'b1; // Shifter Logic (Latency 2)
                
                // Only pass input_valid for 0-cycle blocks (Logic Only: 11)
                else if (CMD[4:3] == 2'b11) output_valid = input_valid; 
                else output_valid = 1'b0;
            end else begin 
                output_valid = 1'b0;
            end
        end
    end

endmodule
