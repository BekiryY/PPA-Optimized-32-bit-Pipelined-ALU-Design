`timescale 1ns / 1ps

module SHIFTER_TB;

    // Inputs
    logic clk;
    logic reset_n;
    logic [31:0] A;
    logic [4:0]  B;
    logic [2:0]  CMD;

    // Outputs
    logic [31:0] Y;
    logic CF_flag;

    // Instantiate the Unit Under Test (UUT)
    SHIFTER uut (
        .clk(clk),
        .reset_n(reset_n),
        .A(A),
        .B(B),
        .CMD(CMD),
        .Y(Y),
        .CF_flag(CF_flag)
    );

    // Constants for Commands
    localparam CMD_SLL = 3'b000;
    localparam CMD_SLA = 3'b001;
    localparam CMD_SRL = 3'b010;
    localparam CMD_SRA = 3'b011;
    localparam CMD_ROL = 3'b100;
    localparam CMD_ROR = 3'b101;
    localparam CMD_BYT = 3'b110; // Note: Corrected to 110 based on RTL

    // Variables for self-checking
    logic [32:0] expected_temp;
    logic [31:0] expected_Y;
    logic expected_CF;
    integer i;
    
    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Task to drive inputs
    task drive_stimulus(input [31:0] in_A, input [4:0] in_B, input [2:0] in_CMD);
        begin
            @(posedge clk);
            #1;
            A = in_A;
            B = in_B;
            CMD = in_CMD;
        end
    endtask

    initial begin
        // Initialize Inputs
        A = 0;
        B = 0;
        CMD = 0;
        reset_n = 0;

        // Reset
        #20;
        reset_n = 1;
        #20;

        $display("Starting SHIFTER Testbench...");

        // ---------------------------------------------
        // Test 2: Shift Left Logical (SLL)
        // ---------------------------------------------
        $display("Test 2: Shift Left Logical (SLL)");
        for (i = 0; i < 20; i++) begin
            logic [31:0] t_a = $urandom();
            logic [4:0] t_b = $urandom_range(0, 31);
            
            drive_stimulus(t_a, t_b, CMD_SLL);
            
            // Expected
            expected_temp = {1'b0, t_a} << t_b; 
            expected_Y = expected_temp[31:0];
            expected_CF = expected_temp[32];
            
            // Wait Latency (2 cycles) + Check
            repeat(2) @(posedge clk); #2; 
            check_result("SLL", t_a, t_b);
        end

        // ---------------------------------------------
        // Test 3: Shift Left Arithmetic (SLA)
        // ---------------------------------------------
        $display("Test 3: Shift Left Arithmetic (SLA)");
        for (i = 0; i < 20; i++) begin
            logic [31:0] t_a = $urandom();
            logic [4:0] t_b = $urandom_range(0, 31);
            
            drive_stimulus(t_a, t_b, CMD_SLA);
            
            expected_temp = {1'b0, t_a} <<< t_b;
            expected_Y = expected_temp[31:0];
            expected_CF = expected_temp[32];
            
            repeat(2) @(posedge clk); #2; 
            check_result("SLA", t_a, t_b);
        end

        // ---------------------------------------------
        // Test 4: Shift Right Logical (SRL)
        // ---------------------------------------------
        $display("Test 4: Shift Right Logical (SRL)");
        for (i = 0; i < 20; i++) begin
            logic [31:0] t_a = $urandom();
            logic [4:0] t_b = $urandom_range(0, 31);
            
            drive_stimulus(t_a, t_b, CMD_SRL);
            
            expected_temp = {t_a, 1'b0} >> t_b;
            expected_Y = expected_temp[32:1];
            expected_CF = expected_temp[0];
            
            repeat(2) @(posedge clk); #2; 
            check_result("SRL", t_a, t_b);
        end

        // ---------------------------------------------
        // Test 5: Shift Right Arithmetic (SRA)
        // ---------------------------------------------
        $display("Test 5: Shift Right Arithmetic (SRA)");
        for (i = 0; i < 20; i++) begin
            logic [31:0] t_a = $urandom();
            logic [4:0] t_b = $urandom_range(0, 31);
            
            drive_stimulus(t_a, t_b, CMD_SRA);
            
            expected_temp = $signed({t_a, 1'b0}) >>> t_b;
            expected_Y = expected_temp[32:1];
            expected_CF = expected_temp[0]; // LSB before shift is what shifts out? 
            // Correct SRA CF check based on RTL:
            // SLL/SLA CF = temp[32] (Carry Out)
            // SRL/SRA CF = temp[0] (Bit shifted out)

            repeat(2) @(posedge clk); #2; 
            check_result("SRA", t_a, t_b);
        end

        // ---------------------------------------------
        // Test 6: Rotate Left (ROL)
        // ---------------------------------------------
        $display("Test 6: Rotate Left (ROL)");
        for (i = 0; i < 20; i++) begin
            logic [31:0] t_a = $urandom();
            logic [4:0] t_b = $urandom_range(0, 31);
            
            drive_stimulus(t_a, t_b, CMD_ROL);
            
            expected_Y = (t_a << t_b) | (t_a >> (32 - t_b));
            expected_CF = 0;
            
            repeat(2) @(posedge clk); #2; 
            check_result("ROL", t_a, t_b);
        end

        // ---------------------------------------------
        // Test 7: Rotate Right (ROR)
        // ---------------------------------------------
        $display("Test 7: Rotate Right (ROR)");
        for (i = 0; i < 20; i++) begin
            logic [31:0] t_a = $urandom();
            logic [4:0] t_b = $urandom_range(0, 31);
            
            drive_stimulus(t_a, t_b, CMD_ROR);
            
            expected_Y = (t_a >> t_b) | (t_a << (32 - t_b));
            expected_CF = 0;
            
            repeat(2) @(posedge clk); #2; 
            check_result("ROR", t_a, t_b);
        end

        // ---------------------------------------------
        // Test 8: Byte Swap (BYT)
        // ---------------------------------------------
        $display("Test 8: Byte Swap (BYT)");
        for (i = 0; i < 5; i++) begin
            logic [31:0] t_a = $urandom();
            logic [4:0] t_b = 0;
            
            drive_stimulus(t_a, t_b, CMD_BYT);
            
            expected_Y = {t_a[7:0], t_a[15:8], t_a[23:16], t_a[31:24]};
            expected_CF = 0;
            
            repeat(2) @(posedge clk); #2; 
            check_result("BYT", t_a, t_b);
        end

        $display("SHIFTER Testbench Completed Successfully!");
        $finish;
    end

    // Helper task to check results
    task check_result;
        input string op_name;
        input [31:0] in_a;
        input [4:0] in_b;
        begin
            if (Y !== expected_Y || CF_flag !== expected_CF) begin
                $error("FAILURE: %s. A=%h, B=%d. Expected Y=%h, CF=%b. Got Y=%h, CF=%b", 
                        op_name, in_a, in_b, expected_Y, expected_CF, Y, CF_flag);
            end
        end
    endtask

endmodule
