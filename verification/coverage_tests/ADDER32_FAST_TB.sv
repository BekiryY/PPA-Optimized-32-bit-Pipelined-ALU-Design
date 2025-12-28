module ADDER32_FAST_TB ;

    // Inputs
    logic clk;
    logic reset_n;
    logic MODE_SEL; // Added MODE_SEL
    logic C0;
    logic [31:0] A;
    logic [31:0] B;

    // Outputs
    logic [32:0] Y;
    logic [32:0] Y_direct;


    ADDER32 uut (
        .clk(clk), 
        .reset_n(reset_n), 
        .MODE_SEL(MODE_SEL), // Connected MODE_SEL
        .C0(C0), 
        .A(A), 
        .B(B), 
        .Y(Y_direct)
    );

assign #1 Y = Y_direct;


// Inside the testbench
logic [32:0] expected_comb, expected_delayed;

initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns period
end



// 1. Calculate the result immediately (Combinational)
assign expected_comb = (A + (B ^ {32{MODE_SEL}}) + C0);

// 2. Delay the result by 1 clock cycle to match the pipeline stage
always @(posedge clk) begin
    #1;
    expected_delayed <= expected_comb;
end

// 3. Compare the DUT output with the delayed golden result
always @(posedge clk) begin
    #3; // Small delay to avoid race conditions with the clock edge
    if (Y !== expected_delayed) 
        $error("Pipeline Mismatch! Got:%h Exp:%h", Y, expected_delayed);
end

initial begin
    reset_n = 0; #20 reset_n = 1;
    
    repeat (1000) begin // Run 1000 random cycles
        @(posedge clk);
        #1;
        A        <= $urandom();
        B        <= $urandom();
        MODE_SEL <= $urandom_range(0, 1);
        C0       <= $urandom_range(0, 1);
    end
    
    $display("Random testing complete.");
    $finish;
end

covergroup adder_cg @(posedge clk);
    option.per_instance = 1;
    
    // Check if we tested both Add and Subtract
    MODE: coverpoint MODE_SEL;
    
    // Check specific ranges for A and B (Small, Mid, Large)
    A_VAL: coverpoint A {
        bins smalls = {[0:255]};
        bins larges = {[32'hFFFF_FF00:32'hFFFF_FFFF]};
        bins others = default;
    }
    
endgroup

adder_cg cg_inst = new();


endmodule