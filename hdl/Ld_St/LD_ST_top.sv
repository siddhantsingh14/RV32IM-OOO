import Ld_St_structs::*;
import rv_structs::*;

module LD_ST_top(
    input clk,
    input rst,

    input Ld_St_structs::IQtoLD_ST IQtoLD_ST, 

    input rv_structs::data_bus bus[5],

    output Ld_St_structs::LD_ST_bus LD_ST_bus,
	 
	 input rv_structs::data_bus_ld_st data_bus_ld_st,//ALU bus ONLY for mem address
    input rv_structs::data_bus_CMP data_bus_CMP,

    output logic cir_q_full,
    /*memory*/
    output logic pmem_read,
    input logic [31:0] pmem_rdata,

    input logic pmem_resp,
    output logic [31:0] pmem_address,

    output logic pmem_write,
    output logic [31:0] pmem_wdata
    /*memory*/
);

logic commit;
logic cir_q_empty;
logic ld_st_data_at_commit;
logic [31:0] mem_address_data_at_commit;
logic [7:0] src_rob_mem_address_data_at_commit;
logic valid_mem_address_data_at_commit;
logic [31:0] write_data_at_commit;
logic [7:0] src_rob_data_at_commit;
logic src_valid_data_at_commit;
logic [7:0] dest_rob_data_at_commit;
logic [3:0] funct3_data_at_commit;

Ld_St Ld_St(
    .clk(clk),
    .rst(rst),

    .IQtoLD_ST(IQtoLD_ST), 

    .bus(bus),
    .LD_ST_bus(LD_ST_bus),
	 .data_bus_ld_st(data_bus_ld_st),
	 .data_bus_CMP(data_bus_CMP),

    .commit(commit),//from controller

    .cir_q_full(cir_q_full), 
    .cir_q_empty(cir_q_empty),
    .ld_st_data_at_commit(ld_st_data_at_commit),
    .mem_address_data_at_commit(mem_address_data_at_commit),
    .src_rob_mem_address_data_at_commit(src_rob_mem_address_data_at_commit),
    .valid_mem_address_data_at_commit(valid_mem_address_data_at_commit),
    .write_data_at_commit(write_data_at_commit),
    .src_rob_data_at_commit(src_rob_data_at_commit),
    .src_valid_data_at_commit(src_valid_data_at_commit),
    .dest_rob_data_at_commit(dest_rob_data_at_commit),
	 .funct3_data_at_commit(funct3_data_at_commit)
);

mem_controller mem_controller(
    .clk(clk),
    .rst(rst),

    .cir_q_empty(cir_q_empty),
    .ld_st_data_at_commit(ld_st_data_at_commit),
    .mem_address_data_at_commit(mem_address_data_at_commit),
    .src_rob_mem_address_data_at_commit(src_rob_mem_address_data_at_commit),
    .valid_mem_address_data_at_commit(valid_mem_address_data_at_commit),
    .write_data_at_commit(write_data_at_commit),
    .src_rob_data_at_commit(src_rob_data_at_commit),
    .src_valid_data_at_commit(src_valid_data_at_commit),
    .dest_rob_data_at_commit(dest_rob_data_at_commit),
	 .funct3_data_at_commit(funct3_data_at_commit),
    .commit(commit),
    .LD_ST_bus(LD_ST_bus),
    /*memory*/
    .pmem_read(pmem_read),
    .pmem_rdata(pmem_rdata),

    .pmem_resp(pmem_resp),
    .pmem_address(pmem_address),

    .pmem_write(pmem_write),
    .pmem_wdata(pmem_wdata)
    /*memory*/
);

endmodule : LD_ST_top