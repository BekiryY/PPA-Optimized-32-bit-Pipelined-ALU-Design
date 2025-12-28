`timescale 1ns / 1ps

module SHIFTER_CT;

    // -------------------------------------------------------------------------
    // Signals
    // -------------------------------------------------------------------------
    logic [31:0] A;
    logic [4:0]  B;
    logic [2:0]  CMD;
    logic [31:0] Y;
    logic        CF_flag;

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    SHIFTER uut (
        .A(A),
        .B(B),
        .CMD(CMD),
        .Y(Y),
        .CF_flag(CF_flag)
    );

    // -------------------------------------------------------------------------
    // Clock only for Coverage Sampling (Comb Block)
    // -------------------------------------------------------------------------
    logic clk;
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // -------------------------------------------------------------------------
    // Reference Model
    // -------------------------------------------------------------------------
    logic [31:0] expected_Y;
    logic        expected_CF;
    logic [32:0] temp_res;

    function void calc_expected();
        case (CMD)
            3'b000: begin // SLL
                temp_res = {1'b0, A} << B;
                expected_Y = temp_res[31:0];
                expected_CF = temp_res[32];
            end
            3'b001: begin // SLA
                temp_res = {1'b0, A} <<< B;
                expected_Y = temp_res[31:0];
                expected_CF = temp_res[32];
            end
            3'b010: begin // SRL
                temp_res = {A, 1'b0} >> B;
                expected_Y = temp_res[32:1];
                expected_CF = temp_res[0];
            end
            3'b011: begin // SRA
                temp_res = $signed({A, 1'b0}) >>> B;
                expected_Y = temp_res[32:1];
                expected_CF = temp_res[0];
            end
            3'b100: begin // ROL
                expected_Y = (A << B) | (A >> (32 - B));
                expected_CF = 0;
            end
            3'b101: begin // ROR
                expected_Y = (A >> B) | (A << (32 - B));
                expected_CF = 0;
            end
            3'b110: begin // BYT
                expected_Y = {A[7:0], A[15:8], A[23:16], A[31:24]};
                expected_CF = 0;
            end
            default: begin
                expected_Y = 0;
                expected_CF = 0;
            end
        endcase
    endfunction

    // -------------------------------------------------------------------------
    // Coverage
    // -------------------------------------------------------------------------
    covergroup shifter_cg @(posedge clk);
        option.per_instance = 1;

        CMD_CP: coverpoint CMD {
            bins sll = {3'b000};
            bins sla = {3'b001};
            bins srl = {3'b010};
            bins sra = {3'b011};
            bins rol = {3'b100};
            bins ror = {3'b101};
            bins byt = {3'b110};
        }

        A_CP: coverpoint A {
            bins val_zeros = {0};
            bins val_ones  = {32'hFFFFFFFF};
            bins val_small = {[1:255]};
            bins val_large = {[32'hFFFF_FF00:32'hFFFF_FFFF]};
            bins val_misc  = {[256:32'hFFFF_FEFF]};
        }

        B_CP: coverpoint B {
             bins shift_0 = {0};
             bins shift_1 = {1};
             bins shift_max = {31};
             bins shift_mid = {[2:30]};
        }

        // Cross
        CMD_x_B: cross CMD_CP, B_CP;
    endgroup

    shifter_cg cg_inst = new();

    // -------------------------------------------------------------------------
    // Main Test
    // -------------------------------------------------------------------------
    int error_count = 0;
    int test_cycles = 2000;

    initial begin
        $display("Starting SHIFTER Coverage Test...");
        A = 0; B = 0; CMD = 0;
        #10;

        for(int i=0; i<test_cycles; i++) begin
            @(posedge clk);
            
            // Randomize
            void'(std::randomize(A, B, CMD) with {
                CMD inside {[0:6]}; // Only valid commands 0-6
                
                A dist {
                    0                             := 1,
                    32'hFFFFFFFF                  := 1,
                    [1:255]                       :/ 2,
                    [32'hFFFF_FF00:32'hFFFF_FFFF] :/ 2,
                    [256:32'hFFFF_FEFF]           :/ 5
                };

                B dist {
                    0       := 1,
                    1       := 1,
                    31      := 1,
                    [2:30]  :/ 5
                };
            });

            #1; // Allow comb logic to settle
            
            calc_expected();
            
            if (Y !== expected_Y || CF_flag !== expected_CF) begin
                $error("Mismatch at %0t! CMD=%b A=%h B=%d | ExpY=%h GotY=%h | ExpCF=%b GotCF=%b", 
                        $time, CMD, A, B, expected_Y, Y, expected_CF, CF_flag);
                error_count++;
            end
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
