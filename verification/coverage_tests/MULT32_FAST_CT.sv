`timescale 1ns / 1ps

module MULT32_FAST_CT;
    
    // -------------------------------------------------------------------------
    // Inputs and Outputs
    // -------------------------------------------------------------------------
    logic clk;
    logic reset_n;
    logic [31:0] A;
    logic [31:0] B;
    logic [63:0] P_REG; // Output

    // -------------------------------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------------------------------
    MULT32 uut (
        .clk(clk),
        .reset_n(reset_n),
        .A(A),
        .B(B),
        .P_REG(P_REG)
    );

    // -------------------------------------------------------------------------
    // Clock Generation
    // -------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // -------------------------------------------------------------------------
    // Verification Signals
    // -------------------------------------------------------------------------
    logic [63:0] expected_comb;
    assign expected_comb = 64'(A) * 64'(B);
    
    // Pipeline for expected values (Depth 7 for 7-cycle latency)
    // 0 -> Latched at T1
    // ...
    // 6 -> Latched at T7 (Matches P_REG)
    logic [63:0] expected_pipe [0:7];
    logic [63:0] expected_delayed;
    
    always_ff @(posedge clk) begin
        if (!reset_n) begin
             for(int k=0; k<=7; k++) expected_pipe[k] <= 0;
        end else begin
             // Shift the pipeline
             for(int k=7; k>0; k--) expected_pipe[k] <= expected_pipe[k-1];
             
             // Capture current expected value
             expected_pipe[0] <= expected_comb;
        end
    end
    
    assign expected_delayed = expected_pipe[6];

    // -------------------------------------------------------------------------
    // Coverage
    // -------------------------------------------------------------------------
    covergroup mult_cg @(posedge clk);
        option.per_instance = 1;

        A_VAL: coverpoint A {
            bins val_zeros = {0};
            bins val_small = {[1:255]};
            bins val_mid   = {[256:32'h0000_FFFF]}; 
            bins val_large = {[32'hFFFF_0000:32'hFFFF_FFFF]};
        }
        B_VAL: coverpoint B {
            bins val_zeros = {0};
            bins val_small = {[1:255]};
            bins val_large = {[32'hFFFF_0000:32'hFFFF_FFFF]};
        }
    endgroup

    mult_cg cg_inst = new();

    // -------------------------------------------------------------------------
    // Test Control
    // -------------------------------------------------------------------------
    int error_count = 0;
    int test_cycles = 1000;

    initial begin
        reset_n = 0; A = 0; B = 0;
        repeat(5) @(posedge clk);
        reset_n = 1;
        repeat(5) @(posedge clk); 
        
        $display("Starting MULT32_FAST Coverage Test (%0d cycles)...", test_cycles);

        for(int i=0; i<test_cycles; i++) begin
            @(posedge clk);
            
            // Check Output (after settling)
            #0.1;
            
            // Since pipeline latency is 7, we skip checking the first 7 cycles 
            // where result is propagating (or undefined/reset).
            if (i >= 8) begin
                if (P_REG !== expected_delayed) begin
                    $error("Mismatch at %0t! Exp=%h Got=%h", $time, expected_delayed, P_REG);
                    error_count++;
                end
            end
            
            // Drive Inputs
            A <= $urandom();
            B <= $urandom();
        end
        
        // Wait for pipeline flush and check validity
        repeat(8) @(posedge clk);
        #0.1; 
        if (P_REG !== expected_delayed) begin
            $error("Final Flush Mismatch! Exp=%h Got=%h", expected_delayed, P_REG);
            error_count++;
        end

        // Final Report
        if (error_count == 0) begin
            $display("---------------------------------------------------");
            $display(" TEST PASSED");
            $display(" Coverage: %0.2f%%", cg_inst.get_coverage());
            $display("---------------------------------------------------");
        end else begin
            $display("---------------------------------------------------");
            $display(" TEST FAILED with %0d errors", error_count);
            $display("---------------------------------------------------");
        end
        
        $finish;
    end
endmodule
