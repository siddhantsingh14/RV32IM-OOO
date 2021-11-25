package sched_structs;

typedef struct packed {         
    logic [4:0] rd;             
    logic [4:0] rob_index;
    logic write;            // write val = ROB index on an issue to index rd       
    logic lookup_regfile_1;     
    logic [5:0] reg_idx_1;      
    logic lookup_regfile_2;     
    logic [5:0] reg_idx_2; 
} IQtoRF;

typedef struct packed {         // for the source operands
    logic lookup_valid_1;
    logic valid_1;                  
    logic [31:0] val_1;
    logic lookup_valid_2;
    logic valid_2;
    logic [31:0] val_2;
} RFtoIQ;

typedef struct packed {
    logic [4:0] dr;
    logic rob_issue;
    logic load_imm;
    logic [31:0] load_imm_val;
    logic is_st;
} IQtoROB;

typedef enum bit [2:0] {
    add  = 3'b000, //check bit30 for sub if op_reg opcode
    sll  = 3'b001,
    slt  = 3'b010,
    sltu = 3'b011,
    axor = 3'b100,
    sr   = 3'b101, //check bit30 for logical/arithmetic
    aor  = 3'b110,
    aand = 3'b111
} arith_funct3_t;

typedef struct packed {
    logic [31:0] src1_val;
    logic src1_valid;
    logic [31:0] src2_val;
    logic src2_valid;
    logic load_RS;
    logic [4:0] dest_rob;
    logic [4:0] src1_rob;
    logic [4:0] src2_rob;
    // sched_structs::load_funct3_t load_funct;
} IQtoRS_ld_st;

typedef enum bit [6:0] {
    op_lui   = 7'b0110111, //load upper immediate (U type)
    op_auipc = 7'b0010111, //add upper immediate PC (U type)
    op_jal   = 7'b1101111, //jump and link (J type)
    op_jalr  = 7'b1100111, //jump and link register (I type)
    op_br    = 7'b1100011, //branch (B type)
    op_load  = 7'b0000011, //load (I type)
    op_store = 7'b0100011, //store (S type)
    op_imm   = 7'b0010011, //arith ops with register/immediate operands (I type)
    op_reg   = 7'b0110011, //arith ops with register operands (R type)
    op_csr   = 7'b1110011  //control and status register (I type)
} rv32i_opcode;

typedef enum bit [2:0] {
    beq  = 3'b000,
    bne  = 3'b001,
    blt  = 3'b100,
    bge  = 3'b101,
    bltu = 3'b110,
    bgeu = 3'b111
} branch_funct3_t;

typedef enum bit [2:0] {
    lb  = 3'b000,
    lh  = 3'b001,
    lw  = 3'b010,
    lbu = 3'b100,
    lhu = 3'b101
} load_funct3_t;

endpackage : sched_structs

 /*logic load_RS;
 logic [3:0] RS_sel;
 logic [4:0] dest_rob;
 logic [2:0] alu_ops;
 logic [4:0] src1_rob;
 logic [31:0] src1_value;
 logic src1_valid;
 logic [4:0] src2_rob;
 logic [31:0] src2_value;
 logic src2_valid;*/