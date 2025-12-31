`timescale 1ns / 1ps

module ALU_SHOWOFF_TB;

    // Signals
    logic clk;
    logic reset_n;
    logic [31:0] A;
    logic [31:0] B;
    logic [4:0] CMD;
    logic input_valid;

    // Performance control
    logic idle;
    logic low_power;
    
    // Outputs
    logic [31:0] Y;
    logic [31:0] result_aux;
    logic output_valid;
    logic [7:0] flag_reg;

    // Instantiate the Device Under Test (DUT)
    ALU_TOP dut (
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
        .flag_reg(flag_reg)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Task to execute single operation with correct timing and valid control
    task execute_op(input [4:0] t_cmd, input [31:0] t_a, input [31:0] t_b);
        integer latency;
    begin
        // Determine latency
        // Mult (01xxx) -> 7 cycles wait
        // Adder (00xxx) -> 1 cycle wait
        // Others -> 1 cycle wait (safe margin)
        if (t_cmd[4:3] == 2'b01) latency = 7;
        else 
        if (t_cmd[4:3] == 2'b01) latency = 2;
        else latency = 1;

        // Drive inputs
        @(posedge clk);
        #1;
        CMD = t_cmd;
        A = t_a;
        B = t_b;
        input_valid = 1;
        
        // Pulse valid for 1 cycle
        @(posedge clk);
        #1;
        input_valid = 0;
        CMD = 0; // Clear inputs for clean waves
        A = 0;
        B = 0;

        // Wait for operation to complete
        repeat(latency - 1) @(posedge clk);
        #1;
    end
    endtask

    integer i, k;
    logic [4:0] op_code;

    initial begin
        // Initialize Inputs
        reset_n = 0;
        A = 0;
        B = 0;
        CMD = 0;
        input_valid = 0;
        idle = 0;
        low_power = 0;

        // Reset Pulse
        #20;
        reset_n = 1;
        #20;

        // ----------------------------------------------------
        // Test Sequence
        // 1. Normal Power Mode
        // 2. Low Power Mode
        // ----------------------------------------------------
        for (k = 0; k < 2; k++) begin
            low_power = k;
            $display("---------------------------------------------------");
            if (low_power) $display("STARTING LOW POWER MODE TESTS (k=%0d)", k);
            else $display("STARTING NORMAL MODE TESTS (k=%0d)", k);
            $display("---------------------------------------------------");

            // Loop through all 32 Opcodes
            for (i = 0; i < 32; i++) begin
                op_code = i[4:0];
                
                // Op 1: Max Values (Edge Case)
                execute_op(op_code, 32'hFFFFFFFF, 32'hFFFFFFFF);
                
                // Op 2: Max Positive / Max Negative (Edge Case)
                execute_op(op_code, 32'h7FFFFFFF, 32'h80000000);

            end
            
            // Wait a bit before switching power mode
            #50;
        end

        // Finish
        #100;
        $display("---------------------------------------------------");
        $display("SIMULATION FINISHED");
        $display("---------------------------------------------------");
        $finish;
    end

    // Watchdog
    initial begin
        #100000;
        $display("ERROR: Simulation timed out!");
        $finish;
    end

endmodule
