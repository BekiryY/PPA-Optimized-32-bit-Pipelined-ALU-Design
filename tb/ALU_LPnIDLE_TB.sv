`timescale 1ns / 1ps

module ALU_LPnIDLE_TB;

    // Signals
    logic clk;
    logic reset_n;
    logic [31:0] A;
    logic [31:0] B;
    logic [4:0] CMD;

    // Performance control
    logic idle;
    logic input_valid;
    logic [1:0] branch;
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
        .branch(branch),
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

    // Stimulus
    integer i;
    
    initial begin
        // Initialize Inputs
        reset_n = 0;
        A = 0;
        B = 0;
        CMD = 0;
        input_valid = 0;
        idle = 0;
        branch = 0;
        low_power = 0;

        // Reset Pulse
        #20;
        reset_n = 1;
        #10;

        // ---------------------------------------------------------
        // 1. Test Low Power Mode
        // ---------------------------------------------------------
        $display("Testing Low Power Mode...");
        low_power = 1;
        
        // Test Adder in LP
        $display("  -> Adder (LP)");
        
        branch = 2'b00;       // Set branch 2 cycles early
        repeat(2) @(posedge clk); 
        #1;

        CMD = 5'b00000;       // ADD
        input_valid = 1;
        // branch is already set
        for (i = 0; i < 5; i++) begin
            @(posedge clk);
            #1;
            A = $urandom;
            B = $urandom;
            #1; 
        end

        // Test Multiplier in LP
        $display("  -> Multiplier (LP)");
        
        branch = 2'b01;       // Set branch 2 cycles early
        repeat(2) @(posedge clk); 
        #1;

        CMD = 5'b01000;       // MUL (01xxx)
        input_valid = 1;
        // branch is already set
        for (i = 0; i < 5; i++) begin
            @(posedge clk);
            #1;
            A = $urandom;
            B = $urandom;
            #1;
        end

        // ---------------------------------------------------------
        // Test Shifter in LP (Available in HP and LP)
        // ---------------------------------------------------------
        $display("  -> Shifter (LP)");
        
        branch = 2'b10;       // Set branch for Shifter
        repeat(2) @(posedge clk); 
        #1;

        // Test SLL
        $display("    -> SLL");
        CMD = 5'b10000;       
        input_valid = 1;
        for (i = 0; i < 3; i++) begin
            @(posedge clk);
            #1;
            A = $urandom;
            B = $urandom;
            #1;
        end

        // Test SRL
        $display("    -> SRL");
        CMD = 5'b10010;       
        for (i = 0; i < 3; i++) begin
            @(posedge clk);
            #1;
            A = $urandom;
            B = $urandom;
            #1;
        end

        // ---------------------------------------------------------
        // Test Logic Block in LP (Available in HP and LP)
        // ---------------------------------------------------------
        $display("  -> Logic Block (LP)");
        
        branch = 2'b11;       // Set branch for Logic
        repeat(2) @(posedge clk); 
        #1;

        // Test AND
        $display("    -> AND");
        CMD = 5'b11011;       
        for (i = 0; i < 3; i++) begin
            @(posedge clk);
            #1;
            A = $urandom;
            B = $urandom;
            #1;
        end

        // Test OR
        $display("    -> OR");
        CMD = 5'b11010;       
        for (i = 0; i < 3; i++) begin
            @(posedge clk);
            #1;
            A = $urandom;
            B = $urandom;
            #1;
        end


        low_power = 0; // Disable low power
        #10;

        // ---------------------------------------------------------
        // 2. Test Idle Mode
        // ---------------------------------------------------------
        $display("Testing Idle Mode...");
        idle = 1;
        
        // Randomly toggle inputs during idle to ensure it doesn't break anything
        // and to check if output remains stable or desired behavior occurs
        for (i = 0; i < 10; i++) begin
           @(posedge clk);
           #1;
           input_valid = $urandom & 1;
           A = $urandom; 
           B = $urandom;
           CMD = $urandom;
           branch = CMD[4:3];
           #1;
        end
        idle = 0;

        // Finish simulation
        #20;
        $finish;
    end

endmodule
