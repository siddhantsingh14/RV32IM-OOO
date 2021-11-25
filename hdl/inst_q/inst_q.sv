module inst_q(
    input clk,
    input rst,

    input inst_q_issue,
    input inst_q_commit,

    input logic [31:0] inst_q_datain,

    output logic [31:0] inst_q_dataout,
    output logic [31:0] inst_q_dataout_commit,
    output logic inst_q_full,
    output logic inst_q_empty
);

cir_q inst_q_cir_q (clk, rst, '0, inst_q_issue, inst_q_commit, '0, inst_q_datain, '0, inst_q_dataout, inst_q_dataout_commit, inst_q_full, inst_q_empty);

endmodule : inst_q