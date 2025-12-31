`timescale 1ns / 1ps

module SHIFTER_TB;

    // Inputs
    logic [31:0] A;
    logic [4:0]  B;
    logic [2:0]  CMD;

    // Outputs
    logic [31:0] Y;
    logic CF_flag;

    // Instantiate the Unit Under Test (UUT)
    SHIFTER uut (
        .A(A),
        .B(B),
        .CMD(CMD),
        .Y(Y),
        .CF_flag(CF_flag)
    );

    // Constants for Commands
    localparam CMD_SLL = 3'b000; // Shift Left Logical
    localparam CMD_SLA = 3'b001; // Shift Left Arithmetic
    localparam CMD_SRL = 3'b010; // Shift Right Logical
    localparam CMD_SRA = 3'b011; // Shift Right Arithmetic
    localparam CMD_ROL = 3'b100; // Rotate Left
    localparam CMD_ROR = 3'b101; // Rotate Right
    localparam CMD_BYT = 3'b111; // Byte Swap

    // Variables for self-checking
    logic [32:0] expected_temp;
    logic [31:0] expected_Y;
    logic expected_CF;
    integer i;

    initial begin
        // Initialize Inputs
        A = 0;
        B = 0;
        CMD = 0;

        // Wait for global reset to finish
        #100;

        $display("Starting SHIFTER Testbench...");

        // ---------------------------------------------
        // Test 2: Shift Left Logical (SLL)
        // ---------------------------------------------
        $display("Test 2: Shift Left Logical (SLL)");
        CMD = CMD_SLL;
        for (i = 0; i < 20; i++) begin
            A = $urandom();
            B = $urandom_range(0, 31);
            #10;
            
            // Expected Logic for SLL
            // Implementation: temp_res = {1'b0, A} << B; Y = temp_res[31:0]; CF_flag = temp_res[32];
            expected_temp = {1'b0, A} << B; 
            expected_Y = expected_temp[31:0];
            expected_CF = expected_temp[32];
            
            check_result("SLL");
        end

        // ---------------------------------------------
        // Test 3: Shift Left Arithmetic (SLA)
        // ---------------------------------------------
        $display("Test 3: Shift Left Arithmetic (SLA)");
        CMD = CMD_SLA;
        for (i = 0; i < 20; i++) begin
            A = $urandom();
            B = $urandom_range(0, 31);
            #10;
            
            // Expected Logic for SLA
            // Implementation: temp_res = {1'b0, A} <<< B; Y = temp_res[31:0]; CF_flag = temp_res[32];
            // Note: On unsigned inputs, <<< behaves like <<.
            expected_temp = {1'b0, A} <<< B;
            expected_Y = expected_temp[31:0];
            expected_CF = expected_temp[32];
            
            check_result("SLA");
        end

        // ---------------------------------------------
        // Test 4: Shift Right Logical (SRL)
        // ---------------------------------------------
        $display("Test 4: Shift Right Logical (SRL)");
        CMD = CMD_SRL;
        for (i = 0; i < 20; i++) begin
            A = $urandom();
            B = $urandom_range(0, 31);
            #10;
            
            // Expected Logic for SRL
            // Implementation: temp_res = {A, 1'b0} >> B; Y = temp_res[32:1]; CF_flag = temp_res[0];
            expected_temp = {A, 1'b0} >> B;
            expected_Y = expected_temp[32:1];
            expected_CF = expected_temp[0];
            
            check_result("SRL");
        end

        // ---------------------------------------------
        // Test 5: Shift Right Arithmetic (SRA)
        // ---------------------------------------------
        $display("Test 5: Shift Right Arithmetic (SRA)");
        CMD = CMD_SRA;
        for (i = 0; i < 20; i++) begin
            A = $urandom();
            B = $urandom_range(0, 31);
            #10;
            
            // Expected Logic for SRA
            // Implementation: temp_res = $signed({A, 1'b0}) >>> B; Y = temp_res[32:1]; CF_flag = temp_res[0];
            expected_temp = $signed({A, 1'b0}) >>> B;
            expected_Y = expected_temp[32:1];
            expected_CF = expected_temp[0];

            check_result("SRA");
        end

        // ---------------------------------------------
        // Test 6: Rotate Left (ROL)
        // ---------------------------------------------
        $display("Test 6: Rotate Left (ROL)");
        CMD = CMD_ROL;
        for (i = 0; i < 20; i++) begin
            A = $urandom();
            B = $urandom_range(0, 31);
            #10;
            
            // Expected Logic for ROL
            // Implementation: Y = (A << B) | (A >> (32 - B)); CF_flag = 0;
            expected_Y = (A << B) | (A >> (32 - B));
            expected_CF = 0;
            
            check_result("ROL");
        end

        // ---------------------------------------------
        // Test 7: Rotate Right (ROR)
        // ---------------------------------------------
        $display("Test 7: Rotate Right (ROR)");
        CMD = CMD_ROR;
        for (i = 0; i < 20; i++) begin
            A = $urandom();
            B = $urandom_range(0, 31);
            #10;
            
            // Expected Logic for ROR
            // Implementation: Y = (A >> B) | (A << (32 - B)); CF_flag = 0;
            expected_Y = (A >> B) | (A << (32 - B));
            expected_CF = 0;
            
            check_result("ROR");
        end

        // ---------------------------------------------
        // Test 8: Byte Swap (BYT)
        // ---------------------------------------------
        $display("Test 8: Byte Swap (BYT)");
        CMD = CMD_BYT;
        for (i = 0; i < 5; i++) begin
            A = $urandom();
            B = $urandom_range(0, 31); // B is don't care
            #10;
            
            // Expected Logic for BYT
            // Implementation: Y = {A[7:0], A[15:8], A[23:16], A[31:24]}; CF_flag = 0;
            expected_Y = {A[7:0], A[15:8], A[23:16], A[31:24]};
            expected_CF = 0;
            
            check_result("BYT");
        end

        $display("SHIFTER Testbench Completed Successfully!");
        $finish;
    end

    // Helper task to check results
    task check_result;
        input string op_name;
        begin
            if (Y !== expected_Y || CF_flag !== expected_CF) begin
                $error("FAILURE: %s. A=%h, B=%d. Expected Y=%h, CF=%b. Got Y=%h, CF=%b", 
                        op_name, A, B, expected_Y, expected_CF, Y, CF_flag);
            end
        end
    endtask

endmodule
