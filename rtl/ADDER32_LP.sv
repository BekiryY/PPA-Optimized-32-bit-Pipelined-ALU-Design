module ADDER32_LP (
    input MODE_SEL,
    input C0,
    input [31:0] A,
    input [31:0] B,
    output logic [32:0] Y
);

    logic [31:0] B_mux;

    // Handle 2's complement inversion for subtraction
    assign B_mux = B ^ {32{MODE_SEL}};

    // Simple behavioral addition - synthesis will optimize for low power/area at low freq
    assign Y = {1'b0, A} + {1'b0, B_mux} + {32'b0, C0};
endmodule
