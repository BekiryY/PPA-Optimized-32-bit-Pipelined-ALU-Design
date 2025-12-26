module flag_controller (
    input  logic        clk,
    input  logic        reset_n,
    input  logic [4:0]  CMD,
    input  logic [31:0] A,
    input  logic [31:0] B,
    input  logic [31:0] Y,
    input  logic        adder_mode,
    input  logic        CF_shifter,
    input  logic        final_adder_carry,
    
    //flag register
    // [7]PF, [6]0, [5]0, [4]0, [3]OF, [2]CF, [1]SF, [0]ZF
    output logic [7:0]  flag_reg,
    output logic        CF_reg
);

    logic PF_reg;
    logic OF_flag;
    logic SF_flag;
    logic ZF_reg;
    logic CF_flag;
    logic [31:0] Y_reg;
    
    // CF Flag Selection
    assign CF_flag = (CMD[4:2] == 3'b011) ? CF_shifter : final_adder_carry;

    // Flag Register Output
    assign flag_reg = {PF_reg, 3'b0, OF_flag, CF_reg, SF_flag, ZF_reg};

    // Flag Register Update
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            PF_reg  <= 1'b0;
            OF_flag <= 1'b0; 
            CF_reg  <= 1'b0;
            SF_flag <= 1'b0;
            ZF_reg  <= 1'b0;
            Y_reg   <= 32'h0;
        end
        else begin
            Y_reg   <= Y;
            PF_reg  <= ^Y_reg;
            ZF_reg  <= (Y_reg == 32'h0);
            SF_flag <= Y[31];
            // Standard Overflow: (Operand1_Sign == Operand2_Sign) && (Result_Sign != Operand1_Sign)
            // Note: Preserving existing logic which seems incomplete but requested to move "as is"
            OF_flag <= (CMD[4:3] == 2'b00) & (A[31] == (B[31] ^ adder_mode)); 
            CF_reg  <= CF_flag;
        end
    end

endmodule
