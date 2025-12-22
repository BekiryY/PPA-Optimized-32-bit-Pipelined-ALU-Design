`timescale 1ns / 1ps

module ADDER32_TB;

    // Inputs
    logic clk;
    logic reset_n;
    logic power_en; // Added power_en to control power gating
    logic MODE_SEL; // Added MODE_SEL
    logic C0;
    logic [31:0] A;
    logic [31:0] B;

    // Outputs
    logic [32:0] Y;

    // Internal storage for pipelined inputs
    logic [31:0] A_q;
    logic [31:0] B_q;
    logic C0_q;
    logic MODE_SEL_q;

    // Instantiate the Unit Under Test (UUT)
    ADDER32 uut (
        .clk(clk), 
        .reset_n(reset_n), 
        .power_en(power_en), // Connected power_en
        .MODE_SEL(MODE_SEL), // Connected MODE_SEL
        .C0(C0), 
        .A(A), 
        .B(B), 
        .Y(Y)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Test variables
    int error_count = 0;

    // Task to drive inputs
    task drive_inputs(input [31:0] in_a, input [31:0] in_b, input in_c0, input in_mode_sel);
        begin
            @(posedge clk);
            #1; // Hold time
            A = in_a;
            B = in_b;
            C0 = in_c0;
            MODE_SEL = in_mode_sel;

            // Store inputs for next cycle's check
            A_q = in_a;
            B_q = in_b;
            C0_q = in_c0;
            MODE_SEL_q = in_mode_sel;
        end
    endtask

    task check_outputs();
        logic [32:0] expected_Y;
        begin
            // Expected for combinational logic
            // Hardware implements A + (MODE_SEL ? ~B : B) + C0
            if (MODE_SEL_q) 
                 expected_Y = A_q + ~B_q + C0_q; // Subtraction: A - B - 1 + C0
            else
                 expected_Y = A_q + B_q + C0_q;  // Addition: A + B + C0
            
            // Allow a small delta for combinational propagation if needed, 
            // but since we check after #1 hold time + wait, it should be stable.
            // Actually, let's wait a bit after driving before checking.
            #1; 

            if (Y !== expected_Y) begin
                $error("Mismatch at time %t: A_q=%h, B_q=%h, C0_q=%b, MODE_SEL_q=%b -> Expected %h, Got %h", 
                       $time, A_q, B_q, C0_q, MODE_SEL_q, expected_Y, Y);
                error_count++;
            end
        end
    endtask

    initial begin
        // Initialize Inputs
        reset_n = 0;
        power_en = 1; // Enable power by default
        MODE_SEL = 0; // Set to ADD
        C0 = 0;
        A = 0;
        B = 0;
        
        // Initialize pipeline registers
        A_q = 0;
        B_q = 0;
        C0_q = 0;
        MODE_SEL_q = 0;

        // Wait 100 ns for global reset to finish
        #100;
        reset_n = 1;
        
        $display("Starting Sanity Check (Stable Inputs)...");
        
        // Test Case 1: Simple Addition
        drive_inputs(32'h0000_0001, 32'h0000_0001, 0, 0);
        @(posedge clk); #5; // Wait one pipe stage
        check_outputs();

        // Test Case 2: Carry propagation across 16-bit boundary
        drive_inputs(32'h0000_FFFF, 32'h0000_0001, 0, 0);
        @(posedge clk); #5;
        check_outputs();
        
        // Test Case 3: Max Value
        drive_inputs(32'hFFFF_FFFF, 32'h0000_0001, 0, 0);
        @(posedge clk); #5;
        check_outputs();

        // Test Case 4: Simple Subtraction (A - B) -> C0=1
        drive_inputs(32'h0000_0005, 32'h0000_0002, 1, 1);
        @(posedge clk); #5;
        check_outputs();

        // Test Case 5: Subtraction with borrow (A - B) -> C0=1
        drive_inputs(32'h0000_0001, 32'h0000_0002, 1, 1);
        @(posedge clk); #5;
        check_outputs();

        drive_inputs($urandom, $urandom, 0, 0); // Random addition
        @(posedge clk); #5;
        check_outputs();

        $display("Starting Streaming Random Test...");
        
        repeat(100) begin
            logic rand_mode_sel = $urandom % 2;
            drive_inputs($urandom, $urandom, $urandom % 2, rand_mode_sel);
            #5;
            check_outputs();
        end

        if (error_count == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED with %0d errors", error_count);

        $finish;
    end


    initial begin
        $dumpfile("adder32_tb.vcd");
        $dumpvars(0, ADDER32_TB);
    end

endmodule