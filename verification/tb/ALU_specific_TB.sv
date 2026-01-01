`timescale 1ns / 1ps

module ALU_specific_TB;
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
    logic [31:0] Y_conflict; // Added missing ports
    logic conflict_valid;    // Added missing ports
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
        .Y_conflict(Y_conflict),
        .conflict_valid(conflict_valid),
        .flag_reg(flag_reg)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Task to perform an operation and wait for result
    task run_op(input [4:0] cmd_in, input string op_name);
        begin
            //@(posedge clk);
            wait(clk == 0); // Change inputs on negedge or stable low to be safe/clean
            #1;
            
            CMD = cmd_in;
            input_valid = 1;
            
            @(posedge clk); // Drive for one clock edge
            #1;
            input_valid = 0;

            // Wait for output valid
            wait(output_valid);
            
            $display("Time: %0tNs | Op: %s | A: %0d | B: %0d | Result (Y): %0d (0x%h)", $time, op_name, A, B, Y, Y);
            
            @(posedge clk); // Wait one more cycle before potentially next op
        end
    endtask

    initial begin
        // Initialize Inputs
        reset_n = 0;
        A = {28'b0, 4'b1011}; // 11
        B = 32'd5;            // 5
        CMD = 0;
        input_valid = 0;
        idle = 0;
        low_power = 0;

        // Reset Pulse
        #20;
        reset_n = 1;
        #20;

        $display("---------------------------------------------------------------");
        $display("Starting Specific ALU Testbench");
        $display("Input A fixed at: %0d (0x%h)", A, A);
        $display("Input B fixed at: %0d (0x%h)", B, B);
        $display("---------------------------------------------------------------");

        // 1. Addition (CMD = 00000)
        run_op(5'b00000, "ADD");

        // 2. Subtraction (CMD = 00001)
        run_op(5'b00001, "SUB");

        // 3. Multiplication (CMD = 01000)
        run_op(5'b01000, "MUL");

        // 4. Checking Equality (CMD = 11111)
        run_op(5'b11111, "EQ ");

        // 5. Less Than (CMD = 00011)
        run_op(5'b00011, "LT ");

        // 6. SLA - Shift Left Arithmetic (CMD = 10001)
        run_op(5'b10001, "SLA");

        $display("---------------------------------------------------------------");
        $display("Testbench Completed");
        $finish;
    end

endmodule
