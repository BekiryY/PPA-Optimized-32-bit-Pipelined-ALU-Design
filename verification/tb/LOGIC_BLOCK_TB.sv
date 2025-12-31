`timescale 1ns / 1ps

module LOGIC_BLOCK_TB;
    logic [31:0] A;
    logic [31:0] B;
    logic [3:0] CMD;
    logic [31:0] Y;

    LOGIC_BLOCK uut (
        .A(A),
        .B(B),
        .CMD(CMD),
        .Y(Y)
    );

    initial begin
        A = 0;
        B = 0;
        CMD = 0;
        #20;

        // Test Case 1: AND (via NAND + NOT)
        // CMD = 0011 (Upper=00 -> Y=~Y1, Lower=11 -> Y1=NAND)
        // Y = ~(~(A&B)) = A&B
        A = 32'hFFFF0000;
        B = 32'hAA55AA55;
        CMD = 4'b0011;
        #10; // Wait for register
        #10; // Wait for logic
        if (Y !== (A & B)) $error("AND Test Failed: %h != %h", Y, (A & B));
        else $display("AND Test Passed");

        // Test Case 2: OR (via NOR + NOT)
        // CMD = 0010 (Upper=00 -> Y=~Y1, Lower=10 -> Y1=NOR)
        // Y = ~(~(A|B)) = A|B
        CMD = 4'b0010;
        #20;
        if (Y !== (A | B)) $error("OR Test Failed: %h != %h", Y, (A | B));
        else $display("OR Test Passed");

        // Test Case 3: XOR (via XNOR + NOT)
        // CMD = 0001 (Upper=00 -> Y=~Y1, Lower=01 -> Y1=XNOR)
        // Y = ~(~(A^B)) = A^B
        CMD = 4'b0001;
        #20;
        if (Y !== (A ^ B)) $error("XOR Test Failed: %h != %h", Y, (A ^ B));
        else $display("XOR Test Passed");

        // Test Case 4: NOT B (via B + NOT)
        // CMD = 0000 (Upper=00 -> Y=~Y1, Lower=00 -> Y1=B)
        // Y = ~B
        CMD = 4'b0000;
        #20;
        if (Y !== (~B)) $error("NOT B Test Failed: %h != %h", Y, ~B);
        else $display("NOT B Test Passed");

        // Test Case 5: Direct NAND
        // CMD = 11xx (Upper=11 -> Y=NAND)
        CMD = 4'b1100;
        #20;
        if (Y !== ~(A & B)) $error("NAND Test Failed: %h != %h", Y, ~(A & B));
        else $display("NAND Test Passed");

        // Test Case 6: Direct NOR
        // CMD = 10xx (Upper=10 -> Y=NOR)
        CMD = 4'b1000;
        #20;
        if (Y !== ~(A | B)) $error("NOR Test Failed: %h != %h", Y, ~(A | B));
        else $display("NOR Test Passed");

        // Test Case 7: Direct XNOR
        // CMD = 01xx (Upper=01 -> Y=XNOR)
        CMD = 4'b0100;
        #20;
        if (Y !== ~(A ^ B)) $error("XNOR Test Failed: %h != %h", Y, ~(A ^ B));
        else $display("XNOR Test Passed");

        $display("All tests completed.");
        $finish;
    end

endmodule
