`timescale 1ns / 1ps

module ALU_FAST_TB;

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

    // Stimulus
    integer i;
    integer cmd_counter;
    logic [4:0] gen_cmd;

    // Queues for 2-cycle delay 
    logic [4:0] cmd_q[$];
    logic [31:0] a_q[$];
    logic [31:0] b_q[$];

    // Task to drive signals with correct branch prediction timing
    task drive_stimulus(input [4:0] t_cmd, input [31:0] t_a, input [31:0] t_b);
    begin
        // Match previous indentation/logic removal
        // Branch removed
        
        // Push stimulus to pipeline
        cmd_q.push_back(t_cmd);
        a_q.push_back(t_a);
        b_q.push_back(t_b);
        
        // Drive DUT input pins from pipeline (2 cycles delayed)
        if(cmd_q.size() > 2) begin
            CMD = cmd_q.pop_front();
            A = a_q.pop_front();
            B = b_q.pop_front();
        end
    end
    endtask
    
    initial begin
        // Initialize Inputs
        reset_n = 0;
        A = 0;
        B = 0;
        CMD = 0;
        input_valid = 0;
        idle = 0;
        low_power = 0;
        cmd_counter = 0;

        // Clear queues
        cmd_q.delete();
        a_q.delete();
        b_q.delete();

        // Reset Pulse
        #20;
        reset_n = 1;
        #10;
        
        input_valid = 1; // Enable input validity for testing

        // ---------------------------------------------------------
        // 1. Sequentially do few additions (CMD = 00000)
        // ---------------------------------------------------------
        gen_cmd = 5'b00000;
        for (i = 0; i < 5; i++) begin
            @(posedge clk);
            #1;
            drive_stimulus(gen_cmd, $urandom, $urandom);
            #1; 
        end

        // ---------------------------------------------------------
        // 2. Then do few subtractions (CMD = 00001)
        // ---------------------------------------------------------
        gen_cmd = 5'b00001;
        for (i = 0; i < 5; i++) begin
            @(posedge clk);
            #1;
            drive_stimulus(gen_cmd, $urandom, $urandom);
            #1;
        end

        // ---------------------------------------------------------
        // 3. Then do the corresponding process
        // Increase opcode by 1 every N=5 cycles, random data
        // ---------------------------------------------------------
        
        gen_cmd = 5'd0; 
        cmd_counter = 0;
        
        // Loop enough times to cover opcodes (32 opcodes * 5 cycles = 160 iterations min)
        for (i = 0; i < 200; i++) begin
            @(posedge clk);
            #1;
            if (i % 20 == 0) $display("Loop 3 Iteration: %0d / 200 at time %0t", i, $time);
            
            // Handle Opcode Increment every 5 cycles
            // We verify the counter BEFORE incrementing, consistent with previous logic
            if (cmd_counter == 4) begin
                gen_cmd = gen_cmd + 1;
                cmd_counter = 0;
            end else begin
                cmd_counter = cmd_counter + 1;
            end
            
            drive_stimulus(gen_cmd, $urandom, $urandom);

            #1; // wait a bit after clock edge
        end

        // Flush pipeline (drive remaining items)
        repeat(3) begin
             @(posedge clk);
            #1;
            // Feed dummy data to push last valid commands out
            drive_stimulus(0, 0, 0); 
            #1;
        end

        // Finish simulation
        $finish;
    end

    // Watchdog to prevent infinite loops
    initial begin
        #50000;
        $display("ERROR: Simulation timed out!");
        $finish;
    end

endmodule
