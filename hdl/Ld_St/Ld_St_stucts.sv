package Ld_St_structs;

typedef struct packed {
    logic issue;
    logic ld_st;
    logic [31:0] mem_addr;
    logic [4:0] src_rob_mem_addr;
    logic valid_src_mem_addr;
    logic [31:0] write_data;//for store
    logic [4:0] src_rob_write_data;//for store
    logic src_valid_write_data;//for store
    logic [4:0] dest_rob;//for load
    logic [2:0] funct3;
}IQtoLD_ST;

//////////////////////////////////////////////////////////////////////////////////////////////////
typedef struct packed {
    logic issue;
    logic commit;
    logic datain_issue;   // need 1 bit on update and issue
    logic dataout; //data out to regfile on commit
    logic cir_q_empty;
    logic cir_q_full;
} LD_ST_cirq;

typedef struct packed {
    logic issue;
    logic commit;
    logic [31:0] datain_issue;   // need 1 bit on update and issue
    logic [31:0] dataout; //data out to regfile on commit
    logic cir_q_empty;
    logic cir_q_full;
} mem_address_cirq;

typedef struct packed {
    logic issue;
    logic commit;
    logic [7:0] datain_issue;   // need 1 bit on update and issue
    logic [7:0] dataout; //data out to regfile on commit
    logic cir_q_empty;
    logic cir_q_full;
} src_rob_mem_address_cirq;

typedef struct packed {
    logic issue;
    logic commit;
    logic datain_issue;   // need 1 bit on update and issue
    logic dataout; //data out to regfile on commit
    logic cir_q_empty;
    logic cir_q_full;
} valid_mem_address_cirq;

typedef struct packed {
    logic issue;
    logic commit;
    logic [31:0] datain_issue;   // need 1 bit on update and issue
    logic [31:0] dataout; //data out to regfile on commit
    logic cir_q_empty;
    logic cir_q_full;
} write_data_cirq;

typedef struct packed {
    logic issue;
    logic commit;
    logic [7:0] datain_issue;   // need 1 bit on update and issue
    logic [7:0] dataout; //data out to regfile on commit
    logic cir_q_empty;
    logic cir_q_full;
} src_rob_cirq;

typedef struct packed {
    logic issue;
    logic commit;
    logic datain_issue;   // need 1 bit on update and issue
    logic dataout; //data out to regfile on commit
    logic cir_q_empty;
    logic cir_q_full;
} valid_cirq;

typedef struct packed {
    logic issue;
    logic commit;
    logic [7:0] datain_issue;   // need 1 bit on update and issue
    logic [7:0] dataout; //data out to regfile on commit
    logic cir_q_empty;
    logic cir_q_full;
} dest_rob_cirq;

typedef struct packed {
    logic issue;
    logic commit;
    logic [3:0] datain_issue;   // need 1 bit on update and issue
    logic [3:0] dataout; //data out to regfile on commit
    logic cir_q_empty;
    logic cir_q_full;
} funct3_cirq;
//////////////////////////////////////////////////////////////////////////////////////////////////
typedef struct packed {
    logic [31:0] data;
    logic valid;
} buffer_bus;

typedef struct packed {
    logic valid;
    logic [31:0] value;
    logic [4:0] dest_rob;//MASK WHEN WRITING TO THIS VARIABLE
	 logic st;//1 if store
} LD_ST_bus;

//////////////////////////////////////////////////////////////////////////////////////////////////

typedef struct packed {
    logic [7:0] rob_idx;
    logic valid;
} look_up_rob;//SRC ROB FOR STORE

typedef struct packed {
    logic valid;
    logic [31:0] que_write_idx;
} output_look_up_rob;//SRC ROB FOR STORE

typedef struct packed {
    logic value;
    logic valid;
} look_up_valid;//SRC ROB FOR STORE

typedef struct packed {
    logic valid;
    logic [31:0] que_write_idx;
} output_look_up_valid;//SRC ROB FOR STORE

typedef struct packed {
    logic [31:0] que_write_idx;
    logic valid;
    logic [31:0] update_data;
} update_32;//STORE

typedef struct packed {
    logic [31:0] que_write_idx;
    logic valid;
    logic update_data;
} update_1;//STORE


endpackage : Ld_St_structs