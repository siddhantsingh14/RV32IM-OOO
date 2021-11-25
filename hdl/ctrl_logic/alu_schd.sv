module alu_schd (
    input load_br_ALU,
    input [31:0] br_ALU_a, br_ALU_b,
    output [31:0] br_ALU_out
);

assign br_ALU_out = load_br_ALU ? (br_ALU_a + br_ALU_b) : '0;

endmodule