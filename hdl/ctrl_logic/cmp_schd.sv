import sched_structs::*;

module cmp_schd (
    input logic load,
    input sched_structs::branch_funct3_t branch_funct3,
    input [31:0] a, b,

    output logic br_en
);

always_comb begin
	 br_en = '0;
	 
    if (load) begin
    unique case (branch_funct3)
        beq     :       br_en = a == b;
        bne     :       br_en = a != b;
        blt     :       br_en = $signed(a) < $signed(b);
        bge     :       br_en = $signed(a) >= $signed(b);
        bltu    :       br_en = a < b;
        bgeu    :       br_en = a >= b;
    endcase
    end
end

endmodule : cmp_schd


