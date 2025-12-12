`timescale 1ns / 1ps

module MULT32_TB;

    // Parameters
    localparam CLK_PERIOD = 10; // 100 MHz

    // Signals
    logic clk;
    logic reset_n;
    logic [31:0] A;
    logic [31:0] B;
    logic [63:0] Y;

    // ---------------------------------------------------------
    // Reference Signals for Waveform Debugging
    // ---------------------------------------------------------
    
    // 1. Immediate Expected Result (Combinational)
    //    Shows what A * B is RIGHT NOW.
    logic [63:0] expected_Y_comb;
    assign expected_Y_comb = longint'(A) * longint'(B);

    // 2. Aligned Expected Result (Pipelined)
    //    Delayed by 3 clock cycles to match the DUT latency.
    //    Compare 'Y' with 'expected_Y_aligned' in the waveform.
    logic [63:0] expected_Y_aligned;
    logic [63:0] pipe_1, pipe_2, pipe_3;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            pipe_1 <= 0;
            pipe_2 <= 0;
            pipe_3 <= 0;
        end else begin
            pipe_1 <= expected_Y_comb;
            pipe_2 <= pipe_1;
            pipe_3 <= pipe_2;
        end
    end
    assign expected_Y_aligned = pipe_3;

    // ---------------------------------------------------------
    // DUT Instantiation
    // ---------------------------------------------------------
    MULT32_8x8_Pipe dut (
        .clk(clk),
        .reset_n(reset_n),
        .A(A),
        .B(B),
        .Y(Y)
    );

    // ---------------------------------------------------------
    // Clock Generation
    // ---------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // ---------------------------------------------------------
    // Test Procedure
    // ---------------------------------------------------------
    initial begin
        // Initialize Inputs
        reset_n = 0;
        A = 0;
        B = 0;
        
        // Reset Sequence
        repeat(5) @(posedge clk);
        reset_n = 1;
        repeat(2) @(posedge clk);

        $display("Starting Simplified MULT32 Testbench...");

        // 1. Simple Directed Tests
        #2;
        drive_input(32'd2, 32'd3);          // 2 * 3 = 6
        drive_input(32'd10, 32'd10);        // 10 * 10 = 100
        drive_input(32'd100, 32'd200);      // 20000
        
        // 2. Corner Cases
        drive_input(32'hFFFFFFFF, 32'd1);   // Max * 1
        drive_input(32'hFFFFFFFF, 32'hFFFFFFFF); // Max * Max

        // 3. Random Tests
        repeat(20) begin
            drive_input($urandom(), $urandom());
        end

        // Wait for pipeline to empty
        repeat(5) @(posedge clk);
        
        $display("Test Completed. Please check waveforms.");
        $finish;
    end

    // Helper task to drive inputs
    task drive_input(input [31:0] in_A, input [31:0] in_B);
        begin
            A <= in_A;
            B <= in_B;
            @(posedge clk);
        end
    endtask

endmodule
