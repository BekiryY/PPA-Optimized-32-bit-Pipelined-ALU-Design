`timescale 1ns / 1ps

module ADDER32_TB;

    // Inputs
    logic clk;
    logic reset_n;
    logic C0;
    logic [31:0] A;
    logic [31:0] B;

    // Outputs
    logic [32:0] Y;

    // Instantiate the Unit Under Test (UUT)
    ADDER32 uut (
        .clk(clk), 
        .reset_n(reset_n), 
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
    task drive_inputs(input [31:0] in_a, input [31:0] in_b, input in_c0);
        begin
            @(posedge clk);
            #2; // Hold time
            A = in_a;
            B = in_b;
            C0 = in_c0;
        end
    endtask

    task check_outputs();
        logic [32:0] expected_Y;
        begin
            // Expected for combinational logic (immediate calculation based on current inputs)
            expected_Y = A + B + C0;
            
            // Allow a small delta for combinational propagation if needed, 
            // but since we check after #1 hold time + wait, it should be stable.
            // Actually, let's wait a bit after driving before checking.
            #1; 

            if (Y !== expected_Y) begin
                $error("Mismatch at time %t: A=%h, B=%h, C0=%b -> Expected %h, Got %h", 
                       $time, A, B, C0, expected_Y, Y);
                error_count++;
            end
        end
    endtask

    initial begin
        // Initialize Inputs
        reset_n = 0;
        C0 = 0;
        A = 0;
        B = 0;
        
        // Wait 100 ns for global reset to finish
        #100;
        reset_n = 1;
        
        $display("Starting Sanity Check (Stable Inputs)...");
        
        // Test Case 1: Simple Addition
        drive_inputs(32'h0000_0001, 32'h0000_0001, 0);
        #5; // Wait for propagation
        check_outputs();

        // Test Case 2: Carry propagation across 16-bit boundary
        drive_inputs(32'h0000_FFFF, 32'h0000_0001, 0);
        #5;
        check_outputs();
        
        // Test Case 3: Max Value
        drive_inputs(32'hFFFF_FFFF, 32'h0000_0001, 0);
        #5;
        check_outputs();

        drive_inputs($urandom, $urandom, 0);
        #5;

        $display("Starting Streaming Random Test...");
        
        repeat(100) begin
            drive_inputs($urandom, $urandom, $urandom % 2);
            #5;
            check_outputs();
        end

        if (error_count == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED with %0d errors", error_count);

        $finish;
    end

endmodule