package rv_structs;

typedef struct packed {
 logic [4:0] dest_rob;
 logic [2:0] alu_ops;
 logic [4:0] src1_rob;
 logic [31:0] src1_value;
 logic src1_valid;
 logic [4:0] src2_rob;
 logic [31:0] src2_value;
 logic src2_valid;
 logic valid;
 logic [31:0] br_pc_out;
}Reservation_st;


// typedef struct packed {
//  //logic [4:0] dest_rob;
//  logic [2:0] alu_ops;
//  logic [4:0] src1_rob;
//  logic [31:0] src1_value;
//  logic src1_valid;
//  logic [4:0] src2_rob;
//  logic [31:0] src2_value;
//  logic src2_valid;
//  logic valid;
//  logic [31:0] br_pc_out;
// }Reservation_st_br;

typedef struct packed {
 logic [4:0] dest_rob;
 logic [31:0] value;
 logic valid;
}data_bus;

typedef struct packed {
 logic [4:0] dest_rob;
 logic value;
 logic valid;
}data_bus_CMP;

typedef struct packed {
 logic value;
 logic valid;
 logic [31:0] br_pc_out;
 logic [4:0] dest_rob;
}data_bus_CMP_br;

typedef struct packed {
 logic [31:0] value;
 logic valid;
 logic [4:0] dest_rob;
}data_bus_ld_st;


typedef struct packed {
 logic load_RS;
 logic [3:0] RS_sel;
 logic [4:0] dest_rob;
 logic [2:0] alu_ops;
 logic [4:0] src1_rob;
 logic [31:0] src1_value;
 logic src1_valid;
 logic [4:0] src2_rob;
 logic [31:0] src2_value;
 logic src2_valid;
}IQtoRS;


typedef struct packed {
 logic load_RS;
 //logic [3:0] RS_sel;
 logic [4:0] dest_rob;
 logic [2:0] alu_ops;
 logic [4:0] src1_rob;
 logic [31:0] src1_value;
 logic src1_valid;
 logic [4:0] src2_rob;
 logic [31:0] src2_value;
 logic src2_valid;
 logic [31:0] br_pc_out;
}IQtoRS_br;

typedef struct packed {//which rob
 logic ld_alu;
 logic [4:0]rob_idx;
 logic [2:0] alu_op;
 logic [31:0] alu_src1;
 logic [31:0] alu_src2; 
}RStoALU;

typedef struct packed {//which rob
 logic ld_cmp;
 logic [4:0]rob_idx;
 logic [2:0] cmp_op;
 logic [31:0] cmp_src1;
 logic [31:0] cmp_src2; 
}RStoCMP;

typedef struct packed {//which rob
 logic ld_cmp;
 logic [4:0]rob_idx;
 logic [31:0] br_pc_out;
 logic [2:0] cmp_op;
 logic [31:0] cmp_src1;
 logic [31:0] cmp_src2; 
}RStoCMP_br;


typedef struct packed {//which rob
 logic ld_alu;
 logic [4:0]rob_idx;
 logic [2:0] alu_op;
 logic [31:0] alu_src1;
 logic [31:0] alu_src2; 
}RStoALU_ld_st;

typedef struct packed {//which rob
 logic do_evict;
 logic [3:0] evict_idx;
}evict;

endpackage : rv_structs