`timescale 1ns / 1ps

module ADDER32_FAST_CT;

    // -------------------------------------------------------------------------
    // Signal Declarations
    // -------------------------------------------------------------------------
    logic clk;
    logic reset_n;
    logic MODE_SEL;
    logic C0;
    logic [31:0] A;
    logic [31:0] B;

    // DUT Outputs
    logic [32:0] Y;

    // -------------------------------------------------------------------------
    // Clock Generation
    // -------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz
    end

    // -------------------------------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------------------------------
    ADDER32 uut (
        .clk(clk), 
        .reset_n(reset_n), 
        .MODE_SEL(MODE_SEL), 
        .C0(C0), 
        .A(A), 
        .B(B), 
        .Y(Y) // Connect directly, no artificial delay wire needed
    );

    // -------------------------------------------------------------------------
    // Verification Signals (Sanity Checks)
    // -------------------------------------------------------------------------
    logic [32:0] expected_comb;
    logic [32:0] expected_delayed;
    
    // Combinational expected calculation (Immediate)
    assign expected_comb = A + (B ^ {32{MODE_SEL}}) + C0;

    // Delayed expected result (Matches Pipeline Latency)
    always_ff @(posedge clk) begin
        if (!reset_n) expected_delayed <= '0;
        else          expected_delayed <= expected_comb;
    end

    // -------------------------------------------------------------------------
    // Coverage Group
    // -------------------------------------------------------------------------
    covergroup adder_cg @(posedge clk);
        option.per_instance = 1;

        MODE: coverpoint MODE_SEL {
            bins add = {0};
            bins sub = {1};

        A_VAL: coverpoint A {
            bins val_small = {[0:255]};
            bins val_mid   = {[256:32'hFFFF_FEFF]};
            bins val_large = {[32'hFFFF_FF00:32'hFFFF_FFFF]};
        }

        B_VAL: coverpoint B {
            bins val_small = {[0:255]};
            bins val_large = {[32'hFFFF_FF00:32'hFFFF_FFFF]};
        }
        
        C0_VAL: coverpoint C0;

        // Cross coverage
        MODE_x_C0: cross MODE, C0_VAL;
    endgroup

    adder_cg cg_inst = new();

    // -------------------------------------------------------------------------
    // Test Environment
    // -------------------------------------------------------------------------
    
    int error_count = 0;
    int test_cycles = 1000;

    // Main Stimulus Loop
    initial begin
        // Init
        reset_n = 0;
        A = 0; B = 0; MODE_SEL = 0; C0 = 0;
        
        // Reset
        repeat(5) @(posedge clk);
        reset_n = 1;
        repeat(2) @(posedge clk);

        $display("Starting Randomized Coverage Test (%0d cycles)...", test_cycles);

        // Main Loop
        for (int i = 0; i < test_cycles; i++) begin
            
            // 1. Synchronize to clock edge
            @(posedge clk);

            // 2. Monitor Result (Check previous cycle's computation)
            // At this point (just after posedge), Y and expected_delayed 
            // have both updated to the result derived from the inputs driven in the *previous* cycle.
            // We use a #1 delay to wait for values to settle after the non-blocking update,
            // or we could check at negedge. 
            // To respect "no nasty delays", we can simply check at the end of the step 
            // but we need to ensure we are checking the *updated* values. 
            // However, inside the loop, simpler logic is:
            
            #0.1; // Minimal step to allow non-blocking assignments to update
            
            if (reset_n && (Y !== expected_delayed)) begin
                $error("Mismatch! Time %0t", $time);
                // Note: These inputs A/B are already the *new* ones driven below if we don't watch out.
                // But we haven't driven new ones yet.
                $error("  Expected: %h", expected_delayed);
                $error("  Got:      %h", Y);
                error_count++;
            end

            // 3. Drive New Inputs
            // 3. Drive New Inputs
            // Use std::randomize with 'dist' to ensure we hit the specific coverage bins
            void'(std::randomize(A, B, MODE_SEL, C0) with {
                MODE_SEL inside {[0:1]};
                C0       inside {[0:1]};
                
                // Targets for A: Small, Mid, Large
                A dist {
                    [0:255]                       :/ 5,  // val_small
                    [256:32'hFFFF_FEFF]           :/ 5,  // val_mid
                    [32'hFFFF_FF00:32'hFFFF_FFFF] :/ 5   // val_large
                };

                // Targets for B: Small, Large (and fill the rest randomly)
                B dist {
                    [0:255]                       :/ 5,  // val_small
                    [32'hFFFF_FF00:32'hFFFF_FFFF] :/ 5,  // val_large
                    [256:32'hFFFF_FEFF]           :/ 5   // Random others
                };
            });
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
