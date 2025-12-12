`timescale 1ns / 1ps

module ALU_TB;

    // Signals
    logic clk;
    logic reset_n;
    logic [31:0] A;
    logic [31:0] B;
    logic [4:0] CMD;
    
    // Outputs
    logic [31:0] Y;
    logic [31:0] result_aux;
    logic [7:0] flag_reg;

    // Instantiate the Device Under Test (DUT)
    ALU_TOP dut (
        .clk(clk),
        .reset_n(reset_n),
        .A(A),
        .B(B),
        .CMD(CMD),
        .Y(Y),
        .result_aux(result_aux),
        .flag_reg(flag_reg)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Stimulus
    integer i;
    integer cmd_counter;
    
    initial begin
        // Initialize Inputs
        reset_n = 0;
        A = 0;
        B = 0;
        CMD = 0;
        cmd_counter = 0;

        // Reset Pulse
        #20;
        reset_n = 1;
        #10;

        // ---------------------------------------------------------
        // 1. Sequentially do few additions (CMD = 00000)
        // ---------------------------------------------------------
        CMD = 5'b00000;
        for (i = 0; i < 5; i++) begin
            @(posedge clk);
            #1;
            A = $urandom;
            B = $urandom;
            #1; // Hold inputs stable
        end

        // ---------------------------------------------------------
        // 2. Then do few subtractions (CMD = 00001)
        // ---------------------------------------------------------
        CMD = 5'b00001;
        for (i = 0; i < 5; i++) begin
            @(posedge clk);
            #1;
            A = $urandom;
            B = $urandom;
            #1;
        end

        // ---------------------------------------------------------
        // 3. Then do the corresponding process
        // Increase opcode by 1 every N=5 cycles, random data
        // ---------------------------------------------------------
        
        // Start from opcode 0 again, or continue? 
        // Request says "increase the opcode by 1", likely implies starting from 0 or current.
        // Let's start from 0 to sweep all operations.
        CMD = 5'd0; 
        
        // Loop enough times to cover opcodes (32 opcodes * 5 cycles = 160 iterations min)
        // Let's do 200 iterations
        for (i = 0; i < 200; i++) begin
            @(posedge clk);
            #1;
            // Randomize inputs
            A = $urandom;
            B = $urandom;
            
            // Handle Opcode Increment every 5 cycles
            if (cmd_counter == 4) begin
                CMD = CMD + 1;
                cmd_counter = 0;
            end else begin
                cmd_counter = cmd_counter + 1;
            end
            
            #1; // wait a bit after clock edge
        end

        // Finish simulation
        $finish;
    end

endmodule
