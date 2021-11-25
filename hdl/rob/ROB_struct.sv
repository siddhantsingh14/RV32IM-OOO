package rob_entry_structs;

typedef struct packed {
    logic [4:0] update_index_0, update_index_1, update_index_2, update_index_3, update_index_4;
    logic [4:0] update_index_cmp, update_index_ld;
    logic issue;
    logic commit;
    logic update_0, update_1, update_2, update_3, update_4;
    logic update_cmp, update_ld;
    logic [7:0] datain_issue;   //total registers are 32, need 5 bits to update the entry size, but extending this to 8 bits to accomadate for parameterization, putting cir_q_offset as 3 for DR_entry
    logic [7:0] datain_update_0, datain_update_1, datain_update_2, datain_update_3, datain_update_4;  //ideally dont need this as DR for entry won't change unless committed or flushed, but need it for port instantiation
    logic [7:0] datain_update_cmp, datain_update_ld;
    logic [7:0] dataout; //data out to regfile on commit
    logic cir_q_empty;
    logic cir_q_full;
    logic [4:0] commit_ptr_rob_idx;
    logic commit_ready;
}rob_dr_entry;//_input;


typedef struct packed {
    logic [4:0] update_index_0, update_index_1, update_index_2, update_index_3, update_index_4;
    logic [4:0] update_index_cmp, update_index_ld;
    logic issue;
    logic commit;
    logic update_0, update_1, update_2, update_3, update_4;
    logic update_cmp, update_ld;
    logic datain_issue;   // need 1 bit on update and issue
    logic datain_update_0, datain_update_1, datain_update_2, datain_update_3, datain_update_4;  //need 1 bit
    logic datain_update_cmp, datain_update_ld;
    logic dataout; //data out to regfile on commit
    logic cir_q_empty;
    logic cir_q_full;
    logic [4:0] commit_ptr_rob_idx;
    logic commit_ready;
}rob_done_entry;//_input;

typedef struct packed {
    logic [4:0] update_index_0, update_index_1, update_index_2, update_index_3, update_index_4;
    logic [4:0] update_index_cmp, update_index_ld;
    logic issue;
    logic commit;
    logic update_0, update_1, update_2, update_3, update_4;
    logic update_cmp, update_ld;
    logic [31:0] datain_issue;   //holds a 32 bit value
    logic [31:0] datain_update_0, datain_update_1, datain_update_2, datain_update_3, datain_update_4;  //32 bits
    logic [31:0] datain_update_cmp, datain_update_ld;
    logic [31:0] dataout; //data out to regfile on commit
    logic cir_q_empty;
    logic cir_q_full;
    logic [4:0] commit_ptr_rob_idx;
    logic commit_ready;
}rob_value_entry;//_input;

typedef struct packed {
    logic [4:0] update_index_0, update_index_1, update_index_2, update_index_3, update_index_4;
    logic [4:0] update_index_cmp, update_index_ld;
    logic issue;
    logic commit;
    logic update_0, update_1, update_2, update_3, update_4;
    logic update_cmp, update_ld;
    logic datain_issue;   // need 1 bit on update and issue
    logic datain_update_0, datain_update_1, datain_update_2, datain_update_3, datain_update_4;  //need 1 bit
    logic datain_update_cmp, datain_update_ld;
    logic dataout; //data out to regfile on commit
    logic cir_q_empty;
    logic cir_q_full;
    logic [4:0] commit_ptr_rob_idx;
    logic commit_ready;
}rob_st_entry;//_input;

typedef struct packed {
    logic valid;    //valid bit for the bus
    logic [31:0] value; //data out to regfile on commit
    logic [4:0] rob_idx;
    logic [4:0] regfile_idx;
}rob_to_regfile;

endpackage
