/*
    Top Level Module for fetch_unit.sv, inst_sched.sv


import sched_structs::*;
import rv_structs::*;
import rob_entry_structs::*;

module top_0 (
    input clk,
    input rst,

    input logic [31:0] mem_rdata,
    input mem_resp,

    output logic mem_read,
    output logic mem_write,
    output logic [31:0] mem_address,
    output logic [31:0] mem_wdata,
    output logic [3:0] mem_byte_enable
);

logic commit_inst_q;                   // commit signal from instruction scheduler to pop an inst.
logic inst_q_empty;

logic [31:0] inst1, pc_out_val, pc_new;
logic rob_q_full;
logic [4:0] rob_issue_ptr, issue_mod_out, commit_mod_out;
logic [1:0] RS_unit1, RS_unit2, RS_unit3, RS_unit4, RS_unit5, RS_unit6; 
logic cir_q_full;
logic cir_q_empty;
logic commit, commit_ready;

sched_structs::RFtoIQ RFtoIQ;
sched_structs::IQtoRF IQtoRF;
sched_structs::IQtoROB IQtoROB;
rv_structs::IQtoRS IQtoRS;
rv_structs::IQtoRS_br IQtoRS_br;
// Ld_St_structs::IQtoLD_ST IQtoLD_ST;
rv_structs::data_bus bus[5];
rob_entry_structs::rob_to_regfile rob_regfile_bus;
rv_structs::data_bus_CMP_br data_bus_CMP_br;

logic [1:0] pcmux_sel;

assign rob_q_full = cir_q_full;
assign rob_issue_ptr = issue_mod_out;

inst_sched scheduler_unit (clk, rst, pc_out_val, inst1, rob_q_full, rob_issue_ptr, inst_q_empty, RS_unit1, RS_unit2, RS_unit3, RS_unit4, RS_unit5, RS_unit6, bus, RFtoIQ, commit_inst_q, pc_new, pcmux_sel, IQtoRF, IQtoROB, IQtoRS, IQtoRS_br);
rob reorder_buffer (clk, rst, bus, cir_q_full, cir_q_empty, IQtoROB, commit, commit_ready, rob_regfile_bus, issue_mod_out, commit_mod_out);
fetch_unit fetch_unit (clk, rst, mem_rdata, mem_resp, commit_inst_q, pcmux_sel, pc_new, data_bus_CMP_br, mem_read, mem_write, mem_address, mem_wdata, mem_byte_enable, inst_q_empty, inst1, pc_out_val);
regfile register_file (clk, rst, IQtoRF, RFtoIQ);

endmodule : top_0 */

/*
    Top Level Module for fetch_unit.sv, inst_sched.sv
*/

// import sched_structs::*;
// import rv_structs::*;
// import rob_entry_structs::*;

// module top_0 (
//     input clk,
//     input rst,

//     input logic [31:0] fetch_mem_rdata,
//     input fetch_mem_resp,

//     output logic fetch_mem_read,
//     output logic [31:0] fetch_mem_address
// );

// logic commit_inst_q;                   // commit signal from instruction scheduler to pop an inst.
// logic inst_q_empty;
// logic [31:0] inst;
// logic [31:0] inst1, pc_out_val;
// logic rob_q_full;
// logic [4:0] rob_issue_ptr, issue_mod_out, commit_mod_out;
// logic [1:0] RS_unit1, RS_unit2, RS_unit3, RS_unit4, RS_unit5, RS_unit_CMP_6;
// logic cir_q_full;
// logic cir_q_empty;
// logic commit, commit_ready;

// sched_structs::RFtoIQ RFtoIQ;
// sched_structs::IQtoRF IQtoRF;
// sched_structs::IQtoROB IQtoROB;
// rv_structs::IQtoRS IQtoRS;
// Ld_St_structs::IQtoLD_ST IQtoLD_ST;
// rv_structs::data_bus bus[5];
// rob_entry_structs::rob_to_regfile rob_regfile_bus;
// rv_structs::data_bus_CMP data_bus_CMP;
// rv_structs::data_bus_CMP_br data_bus_CMP_br;
// // Ld_St_structs::IQtoLD_ST IQtoLD_ST;
// Ld_St_structs::LD_ST_bus bus_ld;
// rv_structs::IQtoRS_br IQtoRS_br;
// rv_structs::data_bus_ld_st data_bus_ld_st;
// sched_structs::IQtoRS_ld_st IQtoRS_ld_st;

// logic [1:0] pcmux_sel;
// logic load_pc, load_pc_fetch;
// logic br_RS_full, ld_st_RS_full;

// assign load_pc_fetch = load_pc;

// assign rob_q_full = cir_q_full;
// assign rob_issue_ptr = issue_mod_out;
// assign inst = inst1;

// inst_sched scheduler_unit (clk, rst, pc_out_val, inst, rob_q_full, rob_issue_ptr, inst_q_empty, RS_unit1, RS_unit2, RS_unit3, RS_unit4, RS_unit5, /*RS_unit_CMP_6,*/ bus, RFtoIQ, br_RS_full, ld_st_RS_full, commit_inst_q, pc_new, pcmux_sel, IQtoRF, IQtoROB, IQtoLD_ST, IQtoRS, IQtoRS_br,IQtoRS_ld_st);
// rob reorder_buffer (clk, rst, bus, data_bus_CMP, bus_ld, cir_q_full, cir_q_empty, IQtoROB, commit, commit_ready, rob_regfile_bus, issue_mod_out, commit_mod_out);
// fetch_unit fetch_unit (clk, rst, fetch_mem_rdata, fetch_mem_resp, commit_inst_q, pcmux_sel, pc_new, data_bus_CMP_br, fetch_mem_read, fetch_mem_address, inst_q_empty, inst1, pc_out_val);
// regfile register_file (clk, rst, IQtoRF, RFtoIQ, rob_regfile_bus);

// commit_controller controller_inst(clk, rst, commit_ready, cir_q_empty, commit);
// RS_ALU reservation_station_inst(clk, rst, IQtoRS, IQtoRS_br,IQtoRS_ld_st, bus_ld, RS_unit1, RS_unit2, RS_unit3, RS_unit4, RS_unit5, RS_unit_CMP_6, br_RS_full, ld_st_RS_full, bus, data_bus_CMP, data_bus_CMP_br, data_bus_ld_st);
// endmodule : top_0



import sched_structs::*;
import rv_structs::*;
import rob_entry_structs::*;

module top_0 (
    input clk,
    input rst,

    input logic [31:0] fetch_mem_rdata,

    input fetch_mem_resp,

    output logic fetch_mem_read,
    output logic [31:0] fetch_mem_address,

    input logic [31:0] ld_st_mem_rdata,
    input logic ld_st_mem_resp,
    output logic [31:0] ld_st_mem_address,
    output logic [31:0] ld_st_mem_wdata,
    output logic ld_st_mem_read,
    output logic ld_st_mem_write
);

logic commit_inst_q;                   // commit signal from instruction scheduler to pop an inst.
logic inst_q_empty;
logic [31:0] inst;
logic [31:0] inst1, pc_out_val;
logic rob_q_full;
logic ld_cir_q_full;
logic [4:0] rob_issue_ptr, issue_mod_out, commit_mod_out;
logic [1:0] RS_unit1, RS_unit2, RS_unit3, RS_unit4, RS_unit5, RS_unit_CMP_6;
logic cir_q_full;
logic cir_q_empty;
logic commit, commit_ready;

sched_structs::RFtoIQ RFtoIQ;
sched_structs::IQtoRF IQtoRF;
sched_structs::IQtoROB IQtoROB;
rv_structs::IQtoRS IQtoRS;
Ld_St_structs::IQtoLD_ST IQtoLD_ST;
rv_structs::data_bus bus[5];
rob_entry_structs::rob_to_regfile rob_regfile_bus;
rv_structs::data_bus_CMP data_bus_CMP;
rv_structs::data_bus_CMP_br data_bus_CMP_br;
Ld_St_structs::LD_ST_bus bus_ld;
rv_structs::IQtoRS_br IQtoRS_br;
rv_structs::data_bus_ld_st data_bus_ld_st;
sched_structs::IQtoRS_ld_st IQtoRS_ld_st;

logic [1:0] pcmux_sel;
logic load_pc, load_pc_fetch, is_op_br;
logic br_RS_full, ld_st_RS_full;

assign load_pc_fetch = load_pc;

assign rob_q_full = cir_q_full;
assign rob_issue_ptr = issue_mod_out;
assign inst = inst1;

inst_sched scheduler_unit (clk, rst, pc_out_val, inst, rob_q_full, rob_issue_ptr, inst_q_empty, RS_unit1, RS_unit2, RS_unit3, RS_unit4, RS_unit5, RS_unit_CMP_6, bus, RFtoIQ, br_RS_full, ld_st_RS_full, commit_inst_q, pc_new, pcmux_sel, is_op_br, IQtoRF, IQtoROB, IQtoLD_ST, IQtoRS, IQtoRS_br,IQtoRS_ld_st);
rob reorder_buffer (clk, rst, bus, data_bus_CMP, bus_ld, cir_q_full, cir_q_empty, IQtoROB, commit, commit_ready, rob_regfile_bus, issue_mod_out, commit_mod_out);
fetch_unit fetch_unit (clk, rst, fetch_mem_rdata, fetch_mem_resp, commit_inst_q, pcmux_sel, pc_new, is_op_br, data_bus_CMP_br, fetch_mem_read, fetch_mem_address, inst_q_empty, inst1, pc_out_val);

// fetch_unit fetch_unit (clk, rst, mem_rdata, mem_resp, commit_inst_q, pcmux_sel, pc_new, data_bus_CMP_br, mem_read, mem_address, inst_q_empty, inst1, pc_out_val);
LD_ST_top ld_st(clk, rst, IQtoLD_ST, bus, bus_ld, data_bus_ld_st,data_bus_CMP, ld_cir_q_full, ld_st_mem_read, ld_st_mem_rdata, ld_st_mem_resp, ld_st_mem_address, ld_st_mem_write, ld_st_mem_wdata);
regfile register_file (clk, rst, IQtoRF, RFtoIQ, rob_regfile_bus);

commit_controller controller_inst(clk, rst, commit_ready, cir_q_empty, commit);
RS_ALU reservation_station_inst(clk, rst, IQtoRS, IQtoRS_br,IQtoRS_ld_st, bus_ld, rob_regfile_bus, RS_unit1, RS_unit2, RS_unit3, RS_unit4, RS_unit5, RS_unit_CMP_6, br_RS_full, ld_st_RS_full, bus, data_bus_CMP, data_bus_CMP_br, data_bus_ld_st);
endmodule : top_0