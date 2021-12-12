module br_st_q (
    input clk,
    input rst,

    input logic issue_jump,         // Inst. Sched. -> manager
    input logic commit_jump,        // Fetch Unit -> manager
    input logic flush,              // ROB -> manager

    output logic br_st_q_empty,      // manager -> Inst. Sched.
    output logic br_st_q_empty_1,
    output logic br_st_q_full       // manager -> Inst. Sched.
);

logic rst_q;
logic dataout, dataout_commit;

assign rst_q = rst | flush;

cir_q #(.cir_q_offset(1), .cir_q_index(3)) inst_q_br_st_manager (clk, rst_q, 1'b0, issue_jump, commit_jump, 1'b0, 1'b1, 1'b0, dataout, dataout_commit, br_st_q_full, br_st_q_empty, br_st_q_empty_1); 

endmodule : br_st_q