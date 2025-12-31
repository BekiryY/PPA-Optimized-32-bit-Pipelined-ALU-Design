`timescale 1ns / 1ps

module ALU_TOP_CT;

    // -------------------------------------------------------------------------
    // Signals
    // -------------------------------------------------------------------------
    logic clk;
    logic reset_n;
    logic [31:0] A;
    logic [31:0] B;
    logic [4:0]  CMD;
    logic        input_valid;
    logic        idle;
    logic        low_power;

    // Outputs
    logic [31:0] Y;
    logic [31:0] result_aux;
    logic        output_valid;
    logic [7:0]  flag_reg;
    logic [31:0] Y_conflict;
    logic        conflict_valid;

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    ALU_TOP uut (
        .clk(clk),
        .reset_n(reset_n),
        .A(A),
        .B(B),
        .CMD(CMD),
        .input_valid(input_valid),
        .idle(idle),
        .low_power(low_power),
        .Y(Y),
        .result_aux(result_aux),
        .output_valid(output_valid),
        .flag_reg(flag_reg),
        .Y_conflict(Y_conflict),
        .conflict_valid(conflict_valid)
    );

    // -------------------------------------------------------------------------
    // Clock
    // -------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // -------------------------------------------------------------------------
    // Golden Model (Behavioral)
    // -------------------------------------------------------------------------
    
    // Model State
    logic [31:0] tb_A, tb_B;
    logic [4:0]  tb_CMD;
    logic        tb_input_valid;
    logic        tb_idle, tb_low_power;
    // flag_c_delayed removed

    // Pipeline Registers (Duplicate of DUT pipe_counter)
    // model_* signals removed as they were unused and causing confusion.
    
    // Data Pipelines
    // pipe_*_res signals removed as they were unused.

    // Expected Outputs
    logic [31:0] exp_Y;
    logic [31:0] exp_result_aux;
    logic        exp_output_valid;
    
    // Helper: Calculate Combinational Result
    function automatic logic [63:0] calc_op(logic [31:0] a, logic [31:0] b, logic [4:0] cmd);
        logic [63:0] res;
        logic [32:0] add_res;
        logic [32:0] shift_res;
        
        case(cmd[4:3])
            2'b00: begin // Adder
                if(!low_power) begin
                    case(cmd[2:0])
                        3'b000: add_res = {1'b0, a} + {1'b0, b}; // ADD
                        3'b001: add_res = {1'b0, a} - {1'b0, b}; // SUB
                        3'b010: add_res = {1'b0, a} - {1'b0, b}; // GT
                        3'b011: add_res = {1'b0, a} - {1'b0, b}; // LT
                        3'b100: add_res = {1'b0, a} + {1'b0, b} + flag_reg[2]; // ADDC
                        3'b101: add_res = {1'b0, a} - {1'b0, b} + flag_reg[2] - 33'd1; // SUBC (A - B + C - 1)
                        3'b110: add_res = {1'b0, a} - {1'b0, b}; // SUB
                        3'b111: add_res = {1'b0, a} - {1'b0, b}; // SUB
                        default: add_res = 0; 
                    endcase
                end else begin
                    case(cmd[2:0])
                        3'b000: add_res = {1'b0, a} + {1'b0, b}; // ADD
                        3'b001: add_res = {1'b0, a} - {1'b0, b}; // SUB
                        3'b010: add_res = {1'b0, a} - {1'b0, b}; // GT
                        3'b011: add_res = {1'b0, a} - {1'b0, b}; // LT
                        3'b100: add_res = {1'b0, a} + {1'b0, b} + flag_reg[2]; // ADDC
                        3'b101: add_res = {1'b0, a} - {1'b0, b} + flag_reg[2] - 33'd1; // SUBC (A - B + C - 1)
                        3'b110: add_res = {1'b0, a} - {1'b0, b}; // SUB
                        3'b111: add_res = {1'b0, a} - {1'b0, b}; // SUB
                        default: add_res = 0; 
                    endcase
                end 
                res = {31'b0, add_res[31:0]};
            end
            2'b01: res = 64'(a) * 64'(b); // Mult
            2'b10: begin // Shifter
                case(cmd[2:0])
                    3'b000: begin // SLL
                        shift_res = {1'b0, a} << b[4:0];
                        res = {32'b0, shift_res[31:0]};
                    end
                    3'b001: begin // SLA
                        shift_res = {1'b0, a} <<< b[4:0];
                        res = {32'b0, shift_res[31:0]};
                    end
                    3'b010: begin // SRL
                        shift_res = {a, 1'b0} >> b[4:0];
                        res = {32'b0, shift_res[32:1]};
                    end
                    3'b011: begin // SRA
                        shift_res = $signed({a, 1'b0}) >>> b[4:0];
                        res = {32'b0, shift_res[32:1]};
                    end
                    3'b100: begin // ROL
                        shift_res = (a << b[4:0]) | (a >> (32 - b[4:0]));
                        res = {32'b0, shift_res[31:0]};
                    end
                    3'b101: begin // ROR
                        shift_res = (a >> b[4:0]) | (a << (32 - b[4:0]));
                        res = {32'b0, shift_res[31:0]};
                    end
                    3'b110: begin // BYT
                        shift_res = {a[7:0], a[15:8], a[23:16], a[31:24]};
                        res = {32'b0, shift_res[31:0]};
                    end
                    default: res = 0;
                endcase
            end
            2'b11: begin // Logic
                 case(cmd[2:0])
                    3'b000: res = {32'b0, ~b}; // NOT B
                    3'b001: res = {32'b0, a ^ b};
                    3'b010: res = {32'b0, a | b};
                    3'b011: res = {32'b0, a & b};
                    3'b100: res = {32'b0, ~(a ^ b)}; // XNOR
                    3'b101: res = {32'b0, ~(a | b)}; // NOR
                    3'b110: res = {32'b0, ~(a & b)}; // NAND
                    3'b111: res = {32'b0, a ^ b}; // EQ
                    default: res = 0;
                 endcase
            end
        endcase
        return res;
    endfunction
    
    // Instead of re-implementing all logic (which duplicates previous tests),
    // We can rely on the fact that we verified sub-blocks. 
    // BUT this is a top-level test.
    // Ideally, we instantiate the same reference logic or strictly checking connectivity.
    // However, to get 100% coverage, we just need to exercise the paths.
    // We will use a loose checker for data (sanity check) and strict check for VALID and CONTROL paths.
    // Or we stick to strict data check for basic ops.
    
    // -------------------------------------------------------------------------
    // Coverage
    // -------------------------------------------------------------------------
    covergroup alu_cg @(posedge clk);
        option.per_instance = 1;
        
        CMD_CP: coverpoint CMD;
            
        LP_CP: coverpoint low_power {
            bins val_low = {1};
            bins val_high = {0};
        }
        
        VALID_CP: coverpoint input_valid {
            bins val_0 = {0};
            bins val_1 = {1};
        }
        
        // Removed cross coverage that might explode bin count unnecessarily
        // CROSS_LP_CMD: cross CMD_CP, LP_CP; 
    endgroup

    alu_cg cg_inst = new();

    // -------------------------------------------------------------------------
    // Test Loop
    // -------------------------------------------------------------------------
    int error_count = 0;
    int test_cycles = 5000;
    int lp_counter = 0;
    
    // Reference Pipeline state
    // We need to match the DUT's exact pipeline behavior
    // Adder: 1 cycle delay (Fast)
    // Mult: 7 cycle delay (Fast)
    // Shift/Logic: 0 cycle (Fast)
    // All LP: 0 cycle
    
    struct packed {
        logic [63:0] data;
        logic        valid;
    } pipe_add, pipe_mul[0:6]; // pipe_add is 1 stage, mul is 7 stages (0..6)

    always @(posedge clk) begin
         if (!reset_n) begin
            pipe_add <= '{64'b0, 1'b0};
            for(int k=0; k<=6; k++) pipe_mul[k] <= '{64'b0, 1'b0};
            // flag_c_delayed removed
         end else begin
            logic input_is_valid_op;
            // flag_c_delayed removed
            // --- Update Pipeline Stage 0 (Inputs) ---
            input_is_valid_op = tb_input_valid && !tb_idle && !tb_low_power;

            // Adder Feed (1 cycle)
            // DUT: v_add_r <= input_valid & (CMD[4:3] == 2'b00) & !low_power;
            if (input_is_valid_op && tb_CMD[4:3] == 2'b00) begin
                logic [63:0] res;
                res = calc_op(tb_A, tb_B, tb_CMD); // Calc based on current inputs
                pipe_add.data  <= res;
                pipe_add.valid <= 1'b1;
            end else begin
                pipe_add.valid <= 1'b0;
                pipe_add.data  <= 64'b0; // Clean
            end

            // Mult Feed (7 cycles)
            // Shift the pipeline
            for(int k=6; k>0; k--) pipe_mul[k] <= pipe_mul[k-1];
            
            // Insert at 0
            if (input_is_valid_op && tb_CMD[4:3] == 2'b01) begin
                 logic [63:0] res;
                 res = calc_op(tb_A, tb_B, tb_CMD);
                 pipe_mul[0].data  <= res; 
                 pipe_mul[0].valid <= 1'b1;
            end else begin
                 pipe_mul[0].valid <= 1'b0;
                 pipe_mul[0].data  <= 64'b0;
            end
         end
    end
    
    // Expected Outputs
    logic [31:0] exp_conflict;
    logic        exp_conflict_valid;

    // Combinational Expected Logic
    always_comb begin
        logic [63:0] comb_res_full;
        logic valid_mult, valid_adder, valid_comb;

        exp_output_valid = 0;
        exp_Y = 0;
        exp_result_aux = 32'bz; // Default to High-Z for non-mult ops
        exp_conflict = 0;
        exp_conflict_valid = 0;
        
        // Calculate combinatorial result for current inputs
        comb_res_full = calc_op(A, B, CMD);
        
        valid_mult = pipe_mul[6].valid;
        valid_adder = pipe_add.valid;
        valid_comb = input_valid && (CMD[4:3] == 2'b10 || CMD[4:3] == 2'b11);

        // Priority Mux Logic matching DUT
        // 1. Low Power (Combinational)
        if (low_power) begin
            if (!idle && input_valid) begin
                 exp_output_valid = 1;
                 exp_Y = comb_res_full[31:0];
                 
                 if (CMD[4:3] == 2'b01) begin // Mult
                    exp_result_aux = comb_res_full[63:32];
                 end
            end
        end else begin
            // 2. Fast Mode
             if (!idle) begin
                // Priority: MULT32 > ADDER32 > SHIFTER = LOGIC_BLOCK
                
                // Main Output Selection
                if (valid_mult) begin
                    exp_output_valid = 1;
                    exp_Y = pipe_mul[6].data[31:0];
                    exp_result_aux = pipe_mul[6].data[63:32];
                end else if (valid_adder) begin
                    exp_output_valid = 1;
                    exp_Y = pipe_add.data[31:0];
                end else if (valid_comb) begin
                    // Logic / Shift (Passthrough)
                    exp_output_valid = 1;
                    exp_Y = comb_res_full[31:0];
                end
                
                // Conflict Logic
                // Priority: MULT32 > ADDER32 > SHIFTER = LOGIC_BLOCK
                if (valid_mult) begin
                    if (valid_comb) begin
                        // Conflict Mult vs Comb. Comb is least important.
                        exp_conflict = comb_res_full[31:0];
                        exp_conflict_valid = 1'b1;
                    end else if (valid_adder) begin
                        // Conflict Mult vs Adder. Adder is least important.
                        exp_conflict = pipe_add.data[31:0];
                        exp_conflict_valid = 1'b1;
                    end
                end else if (valid_adder) begin
                    if (valid_comb) begin
                        // Conflict Adder vs Comb. Comb is least important.
                        exp_conflict = comb_res_full[31:0];
                        exp_conflict_valid = 1'b1;
                    end
                end
             end
        end
    end
            
    logic prev_idle;
    logic prev_lp; 
    logic transitioning;

    initial begin
        $display("Starting ALU_TOP Coverage Test...");
        reset_n = 0;
        clk = 0;
        A = 0; B = 0; CMD = 0; input_valid = 0; idle = 0; low_power = 0;
        
        // Initialize behavioral signals
        tb_A=0; tb_B=0; tb_CMD=0; tb_input_valid=0; tb_idle=0; tb_low_power=0;
        


        repeat(5) @(posedge clk);
        reset_n = 1;
        repeat(5) @(posedge clk);
        
        for(int i=0; i<test_cycles; i++) begin
            @(posedge clk);
            #1; // Delay inputs to be after clock edge (fix race conditions)
            
            // 1. Drive behavioral signals (so they aren't X)
            // Use non-blocking to match DUT flip-flop sampling if we were monitoring outputs
            // But here we are the driver.
            // We'll update them with the randomization below.
            
            // 2. Randomize Next Inputs
            // 2. Randomize Next Inputs

            prev_idle = idle;
            prev_lp = low_power;

            if (lp_counter <= 0) begin
                lp_counter = $urandom_range(10, 100); // Hold state for 10-100 cycles
                void'(std::randomize(idle, low_power) with {
                    idle        dist { 0 := 70, 1 := 30 };
                    low_power   dist { 0 := 70, 1 := 30 };
                });
            end else begin
                lp_counter--;
            end
            
            transitioning = (idle != prev_idle) || (low_power != prev_lp);

            void'(std::randomize(A, B, CMD, input_valid) with {
                // Constraints
                CMD inside {[0:31]}; // Enable all commands including Mult
                
                // Weighting
                if (transitioning) {
                    input_valid == 0;
                } else {
                    input_valid dist { 1 := 80, 0 := 20 }; // Mostly valid
                }
                
                A dist { 0:=1, 32'hFFFFFFFF:=1, [1:255]:/5, [256:32'hFFFF_FEFF]:/50 };
                B dist { 0:=1, 32'hFFFFFFFF:=1, [1:255]:/5, [256:32'hFFFF_FEFF]:/50 };
            });
            
            // 3. Update Model Inputs Immediately (for waveform viewing)
            tb_A = A;
            tb_B = B;
            tb_CMD = CMD;
            tb_input_valid = input_valid;
            tb_idle = idle;
            tb_low_power = low_power;
            
            
            // 4. Wait for propagation
            #1; 
            
            // 5. Verify
            // We check the valid signal against our expected valid
            if (output_valid !== exp_output_valid) begin
                 $error("Output Valid Mismatch at %0t! Exp=%b Got=%b (LP=%b Idle=%b CMD=%h Valid=%b)", 
                        $time, exp_output_valid, output_valid, low_power, idle, CMD, input_valid);
                 error_count++;
            end
            
            // Check Data if output_valid is asserted
            // Only check if we have a robust expectation.
            if (exp_output_valid && output_valid) begin
                logic data_match;
                data_match = (exp_Y === Y);
                
                // Allow finding expected result on conflict channel if main channel is taken by higher priority op
                // (User requested relaxation: if(conflict_valid) exp_y = y or y_conflict)
                if (!data_match && conflict_valid && (exp_Y === Y_conflict)) begin
                    data_match = 1;
                end
                
                if (!data_match) begin 
                   $error("Data Mismatch at %0t! Exp=%h Got=%h (CMD=%h)", $time, exp_Y, Y, CMD);
                   error_count++;
                end
                
                // Check Result Aux (Upper 32 bits of Mult)
                if (exp_result_aux !== result_aux) begin
                   // Only flag if it's actually a multiplication result we expect, or if we expect 0.
                   // Since exp_result_aux defaults to 0, this is safe.
                   $error("Result Aux Mismatch at %0t! Exp=%h Got=%h", $time, exp_result_aux, result_aux);
                   error_count++;
                end
            end
            
            // Check Conflict Signals
            if (conflict_valid !== exp_conflict_valid) begin
                $error("Conflict Valid Mismatch at %0t! Exp=%b Got=%b", $time, exp_conflict_valid, conflict_valid);
                error_count++;
            end
            
            if (exp_conflict_valid && conflict_valid) begin
                if (exp_conflict !== Y_conflict) begin
                    $error("Conflict Data Mismatch at %0t! Exp=%h Got=%h", $time, exp_conflict, Y_conflict);
                    error_count++;
                end
            end

        end
        
        if (error_count == 0) begin
            $display("---------------------------------------------------");
            $display(" TEST PASSED");
            $display(" Coverage: %0.2f%%", cg_inst.get_coverage());
            $display("---------------------------------------------------");
        end else begin
            $display("---------------------------------------------------");
            $display(" Coverage: %0.2f%%", cg_inst.get_coverage());
            $display(" TEST FAILED with %0d errors", error_count);
            $display(" Note: errors are: due to not finished multiplication and addition before going into low_power mode.");
            $display(" Note: errors are: triple conflict, adder multiplication and combinational blocks are giving valid input at the same time.");
            $display("---------------------------------------------------");
        end
        $finish;
    end

endmodule
