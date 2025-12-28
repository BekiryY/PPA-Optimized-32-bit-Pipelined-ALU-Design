module SHIFTER (
    input  logic [31:0] A,          // Operand
    input  logic [4:0]  B,          // Shift Amount
    input  logic [2:0]  CMD,        // Command
    output logic [31:0] Y,          // Result
    output logic        CF_flag
);

    // Operation Codes
    localparam CMD_SLL = 3'b000;
    localparam CMD_SLA = 3'b001; 
    localparam CMD_SRL = 3'b010;
    localparam CMD_SRA = 3'b011;
    localparam CMD_ROL = 3'b100;
    localparam CMD_ROR = 3'b101;
    localparam CMD_BYT = 3'b110;

    // Helper: Bit Reverse Function
    function automatic logic [31:0] reverse(input logic [31:0] in);
        integer i;
        for (i = 0; i < 32; i++) begin
            reverse[i] = in[31-i];
        end
    endfunction

    // -------------------------------------------------------------------------
    // Unified Shifter Logic
    // -------------------------------------------------------------------------
    // Strategy: Map Left Shifts to Right Shifts.
    // Left Shift (A << B) === Reverse( Reverse(A) >> B )
    // Rotation is handled separately or via 64-bit shift extension.
    
    logic is_left_shift;
    logic is_arithmetic;
    logic is_rotate;
    logic is_byte_swap;

    assign is_left_shift = (CMD == CMD_SLL) || (CMD == CMD_SLA); 
    assign is_arithmetic = (CMD == CMD_SRA); // Note: SLA is effectively SLL for 32-bit results usually, unless overflow checked. 
                                             // Standard Verilog <<< matches << for logic/reg types usually.
    assign is_rotate     = (CMD == CMD_ROL) || (CMD == CMD_ROR);
    assign is_byte_swap  = (CMD == CMD_BYT);

    // 1. Prepare Input for Right Shifter
    logic [31:0] shift_in;
    logic [31:0] a_reversed;
    
    assign a_reversed = reverse(A);

    always_comb begin
        if (is_left_shift) 
            shift_in = a_reversed;
        else 
            shift_in = A;
    end

    // 2. Determine Extension Bits (for Arithmetic Shift)
    // SRA extends with A[31]. SLL/SRL/SLA extend with 0.
    logic sign_bit;
    assign sign_bit = is_arithmetic ? A[31] : 1'b0;

    // 3. Perform Shift
    // We use a 33-bit shift to capture the Carry Out (shifted out bit) easily? 
    // Or just 32-bit. 
    // Behavioral >> allows synthesis to choose best Barrel Shifter mux tree.
    // For SRA, we need sign extension: { {32{sign}}, shift_in } >> B
    
    logic [63:0] shift_res_extended;
    
    // We construct a 64-bit value to shift:
    // [63:32] = Extension (Sign or 0)
    // [31:0]  = Operand
    assign shift_res_extended = $signed({ {32{sign_bit}}, shift_in }) >>> B;
    
    logic [31:0] shift_res_raw;
    assign shift_res_raw = shift_res_extended[31:0];

    // 4. Post-process result
    // If it was a Left Shift, we must reverse the result back.
    logic [31:0] shift_final;
    logic [31:0] shift_res_reversed;
    
    assign shift_res_reversed = reverse(shift_res_raw);

    assign shift_final = (is_left_shift) ? shift_res_reversed : shift_res_raw;


    // -------------------------------------------------------------------------
    // Rotate Logic (Parallel optimized path)
    // -------------------------------------------------------------------------
    // ROR: (A >> B) | (A << 32-B)  => {A, A} >> B
    // ROL: (A << B) | (A >> 32-B)  => {A, A} << B => Or ROR (32-B)
    // To avoid subtractor on B, we use {A,A} structure.
    
    logic [63:0] rot_operand;
    logic [63:0] rot_res_extended;
    logic [31:0] rotate_final;

    // For ROL, we can ROR by (32-B). 
    // Optimization: Just implement ROR and ROL separately or accept the subtractor if needed?
    // Actually {A, A} >> B gives ROR. 
    // {A, A} << B gives ROL (taking upper bits).
    
    // Let's stick to {A,A} >> B for ROR.
    // For ROL, use {A,A} >> (32-B) ? No that uses subtractor.
    // Use {A,A} << B.
    
    // To save area, we can map ROL to ROR? 
    // ROL A, B = ROR A, (32-B).
    // If WNS is bad, maybe just implementation of {A,A} is better than sharing.
    
    logic [4:0] rot_amt;
    assign rot_amt = (CMD == CMD_ROL) ? (5'd32 - B) : B; // This subtractor might be the critical path?
    // If B=0, 32-0 = 32. 5-bit = 0. Correct.
    
    assign rot_operand = {A, A};
    assign rot_res_extended = rot_operand >> rot_amt;
    assign rotate_final = rot_res_extended[31:0];


    // -------------------------------------------------------------------------
    // Byte Swap
    // -------------------------------------------------------------------------
    logic [31:0] byt_final;
    assign byt_final = {A[7:0], A[15:8], A[23:16], A[31:24]};


    // -------------------------------------------------------------------------
    // Final Selection
    // -------------------------------------------------------------------------
    always_comb begin
        if (is_byte_swap)
            Y = byt_final;
        else if (is_rotate)
            Y = rotate_final;
        else
            Y = shift_final;
    end

    // -------------------------------------------------------------------------
    // Carry Flag Logic
    // -------------------------------------------------------------------------
    // CF is usually the last bit shifted out.
    // For SLL/SLA: result[32] of (A << B) ie input[32-B].
    // For SRL/SRA: result[-1] of (A >> B) ie input[B-1].
    // Simplified: We can re-use the extended shift result or use a MUX.
    
    // Muxing from input is minimal logic.
    // SLL/SLA: CF = A[32-B]. if B=0 -> A[32]? No. Logic usually 0 for B=0.
    // SRL/SRA: CF = A[B-1]. if B=0 -> A[-1]? No.
    
    always_comb begin
        if (B == 0) begin
            CF_flag = 1'b0;
        end else begin
            case (CMD)
                CMD_SLL, CMD_SLA: CF_flag = A[32-B]; // Note: Synthesis handles this as a MUX
                CMD_SRL, CMD_SRA: CF_flag = A[B-1];
                default:          CF_flag = 1'b0;
            endcase
        end
    end

endmodule
