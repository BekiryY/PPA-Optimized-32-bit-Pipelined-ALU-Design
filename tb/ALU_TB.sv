`timescale 1ns / 1ps

module ALU_TB;

    // Signals
    logic clk;
    logic reset_n;
    logic [31:0] A;
    logic [31:0] B;
    logic [4:0] CMD;

    // Performance control
    logic idle;
    logic [1:0] branch;
    logic low_power;
    
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
        .idle(idle),
        .branch(branch),
        .low_power(low_power),
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
        idle = 0;
        branch = 0;
        low_power = 0;
        cmd_counter = 0;

        // Reset Pulse
        #20;
        reset_n = 1;
        #10;

        // ---------------------------------------------------------
        // 1. Sequentially do few additions (CMD = 00000)
        // ---------------------------------------------------------
        CMD = 5'b00000;
        branch = CMD[4:3]; // 00 -> Adder
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
        branch = CMD[4:3]; // 00 -> Adder
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
        
        CMD = 5'd0; 
        
        // Loop enough times to cover opcodes (32 opcodes * 5 cycles = 160 iterations min)
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
            
            // Drive branch based on CMD
            branch = CMD[4:3];

            #1; // wait a bit after clock edge
        end

        // ---------------------------------------------------------
        // 4. Test Low Power Mode
        // ---------------------------------------------------------
        $display("Testing Low Power Mode with Adder...");
        low_power = 1;
        CMD = 5'b00000; // ADD
        branch = CMD[4:3];
        for (i = 0; i < 5; i++) begin
            @(posedge clk);
            #1;
            A = $urandom;
            B = $urandom;
            #1; 
        end
        low_power = 0; // Disable low power

        // ---------------------------------------------------------
        // 5. Test Idle Mode
        // ---------------------------------------------------------
        $display("Testing Idle Mode...");
        idle = 1;
        for (i = 0; i < 10; i++) begin
           @(posedge clk);
           #1;
           // In idle, inputs shouldn't matter as much, checking stabilization
           A = $urandom; 
           B = $urandom;
           #1;
        end
        idle = 0;

        // Finish simulation
        $finish;
    end

endmodule
