`timescale 1ns / 1ps

module MULT32_FAST_TB;

    // Signals
    logic clk;
    logic reset_n;
    logic power_en;
    logic [31:0] A;
    logic [31:0] B;
    logic [63:0] P_REG;
    logic valid_o;
    logic start_i;

    // Instantiate the Unit Under Test (UUT)
    // Note: The module name in MULT32_FAST.sv is MULT32
    MULT32 uut (
        .clk(clk),
        .reset_n(reset_n),
        .power_en(power_en),
        .A(A),
        .B(B),
        .P_REG(P_REG),
        .start_i(start_i),
        .valid_o(valid_o)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Test Sequence
    initial begin
        // Initialize Inputs
        reset_n = 0;
        power_en = 0;
        start_i = 0;
        A = 0;
        B = 0;

        // Apply Reset
        $display("Applying Reset...");
        #20;
        reset_n = 1;
        power_en = 1; // Enable power (though currently unused in RTL)
        #20;

        $display("Starting MULT32_FAST Testbench (Simple Inputs)...");

        // ----------------------------------------------------
        // Test Case 1: Small numbers
        // ----------------------------------------------------
        test_mult(32'd2, 32'd3);

        // ----------------------------------------------------
        // Test Case 2: 10 * 10
        // ----------------------------------------------------
        test_mult(32'd10, 32'd10);
        test_mult(32'd20, 32'd25);
        // ----------------------------------------------------
        // Test Case 3: Identity with 1
        // ----------------------------------------------------
        test_mult(32'd123456, 32'd1);

        // ----------------------------------------------------
        // Test Case 4: Zero Multiplication
        // ----------------------------------------------------
        test_mult(32'd987654321, 32'd0);

        // ----------------------------------------------------
        // Test Case 5: Max 32-bit Value Squared
        // (2^32 - 1) * (2^32 - 1) should be close to 2^64
        // ----------------------------------------------------
        test_mult(32'hFFFFFFFF, 32'hFFFFFFFF);

        // ----------------------------------------------------
        // Test Case 6: Alternating Patterns
        // ----------------------------------------------------
        test_mult(32'hAAAAAAAA, 32'h55555555);

        // ----------------------------------------------------
        // Test Case 7: Random Hardcoded Check
        // ----------------------------------------------------
        test_mult(32'd500, 32'd200); // 100000

        $display("All tests completed.");
        $finish;
    end

    // Task to drive inputs and verify output
    task test_mult(input [31:0] in_a, input [31:0] in_b);
        logic [63:0] expected;
        begin
            // Align with clock to ensure setup times
            @(posedge clk);
            #1.5;
            start_i <= 1'b1;
            A <= in_a; 
            B <= in_b;
            
            // Expected value
            expected = 64'(in_a) * 64'(in_b);

            @(posedge clk);
            #1.5;
            start_i <= 1'b0; // Pulse start_i

            // Wait for remaining pipeline stages
            // We already waited 1 cycle (the start_i pulse cycle).
            // Total latency is 4, so we need to wait 3 more cycles.
            repeat (3) @(posedge clk);
            
            
            // Check usage of non-blocking assignments or wait slightly
            #1; 

            if (P_REG !== expected) begin
                $error("FAIL: A=%0d, B=%0d | Expected P_REG=%0d | Got P=%0d | Valid=%b", in_a, in_b, expected, P_REG, valid_o);
            end else if (!valid_o) begin
                $error("FAIL: Valid signal not asserted!");
            end else begin
                $display("PASS: A=%0d, B=%0d | P_REG=%0d | Valid=%b", in_a, in_b, P_REG, valid_o);
            end
            
            // Hold for visual inspection if needed, then prepare for next
            @(posedge clk);
        end
    endtask

endmodule
