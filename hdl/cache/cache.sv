/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */
import sched_structs::*;

module cache #(
    parameter s_offset = 5,
    parameter s_index  = 4,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,
	input rst,
	
	//MP2 Processor
	input logic mem_read,
	input logic mem_write,
	input [31:0] mem_address,
	input logic [31:0] mem_wdata,
	input logic [3:0] mem_byte_enable,
	output logic [31:0] mem_rdata,
	output mem_resp,
	
	//MP1 Cacheline adapter
   input logic [255:0] pmem_rdata,
   input logic pmem_resp,
	output logic [31:0] pmem_address,
   output pmem_read,
   output pmem_write,
	output logic [255:0] pmem_wdata,
	input sched_structs::ROBToALL ROBToALL
);

logic [255:0] mem_wdata256_bus;
logic [255:0] mem_rdata256_bus;
logic [31:0] mem_byte_enable256;

assign pmem_wdata = mem_rdata256_bus;

logic [1:0] data_arr1_writer_en_ctrl;
logic data_arr1_datain_ctrl;
logic [1:0] data_arr2_writer_en_ctrl;
logic data_arr2_datain_ctrl;
logic [1:0] data_arr3_writer_en_ctrl;
logic data_arr3_datain_ctrl;
logic [1:0] data_arr4_writer_en_ctrl;
logic data_arr4_datain_ctrl;
logic [1:0] cacheline_out_ctrl;
logic ld_tag1;
logic ld_tag2;
logic ld_tag3;
logic ld_tag4;
logic [22:0] tag1_out, tag2_out, tag3_out, tag4_out;
logic ld_dirty1;
logic dirty1_in;
logic dirty1_out;
logic ld_dirty2;
logic dirty2_in;
logic dirty2_out;
logic ld_dirty3;
logic dirty3_in;
logic dirty3_out;
logic ld_dirty4;
logic dirty4_in;
logic dirty4_out;
logic ld_valid1;
logic valid1_in;
logic valid1_out;
logic ld_valid2;
logic valid2_in;
logic valid2_out;
logic ld_valid3;
logic valid3_in;
logic valid3_out;
logic ld_valid4;
logic valid4_in;
logic valid4_out;
logic ld_lru;
logic [2:0]lru_in;
logic [2:0] lru_out;

cache_control control
(
	.clk(clk),
	.rst(rst),
	
	.mem_address(mem_address),
	.mem_resp(mem_resp),
	.mem_read(mem_read),
	.mem_write(mem_write),
	
	.pmem_resp(pmem_resp),
	.pmem_read(pmem_read),
	.pmem_write(pmem_write),
	.pmem_addr(pmem_address),
	
	.data_arr1_writer_en_ctrl(data_arr1_writer_en_ctrl),
	.data_arr1_datain_ctrl(data_arr1_datain_ctrl),
	.data_arr2_writer_en_ctrl(data_arr2_writer_en_ctrl),
	.data_arr2_datain_ctrl(data_arr2_datain_ctrl),
	.data_arr3_writer_en_ctrl(data_arr3_writer_en_ctrl),
	.data_arr3_datain_ctrl(data_arr3_datain_ctrl),
	.data_arr4_writer_en_ctrl(data_arr4_writer_en_ctrl),
	.data_arr4_datain_ctrl(data_arr4_datain_ctrl),
	
	.cacheline_out_ctrl(cacheline_out_ctrl),
	
	.ld_tag1(ld_tag1),
	.ld_tag2(ld_tag2),
	.tag1_out(tag1_out),
	.tag2_out(tag2_out),
	.ld_tag3(ld_tag3),
	.ld_tag4(ld_tag4),
	.tag3_out(tag3_out),
	.tag4_out(tag4_out),
	.ld_dirty1(ld_dirty1),
   .dirty1_in(dirty1_in),
   .dirty1_out(dirty1_out),
   .ld_dirty2(ld_dirty2),
   .dirty2_in(dirty2_in),
   .dirty2_out(dirty2_out),
	.ld_dirty3(ld_dirty3),
   .dirty3_in(dirty3_in),
   .dirty3_out(dirty3_out),
   .ld_dirty4(ld_dirty4),
   .dirty4_in(dirty4_in),
   .dirty4_out(dirty4_out),
	.ld_lru(ld_lru),
	.lru_in(lru_in),
	.lru_out(lru_out),
   .ld_valid1(ld_valid1),
   .valid1_in(valid1_in),
   .valid1_out(valid1_out),
   .ld_valid2(ld_valid2),
   .valid2_in(valid2_in),
   .valid2_out(valid2_out),
	.ld_valid3(ld_valid3),
   .valid3_in(valid3_in),
   .valid3_out(valid3_out),
   .ld_valid4(ld_valid4),
   .valid4_in(valid4_in),
   .valid4_out(valid4_out),
	.ROBToALL(ROBToALL)

);

cache_datapath datapath
(
	.clk(clk),
	.rst(rst),
	
	.mem_addr(mem_address),
	.data_bus_in(mem_wdata256_bus),
	.bus_en(mem_byte_enable256),
	.data_cacheline_in(pmem_rdata),
	.data_cacheline_out(mem_rdata256_bus),
	
	.data_arr1_writer_en_ctrl(data_arr1_writer_en_ctrl),
	.data_arr1_datain_ctrl(data_arr1_datain_ctrl),
	.data_arr2_writer_en_ctrl(data_arr2_writer_en_ctrl),
	.data_arr2_datain_ctrl(data_arr2_datain_ctrl),
	.data_arr3_writer_en_ctrl(data_arr3_writer_en_ctrl),
	.data_arr3_datain_ctrl(data_arr3_datain_ctrl),
	.data_arr4_writer_en_ctrl(data_arr4_writer_en_ctrl),
	.data_arr4_datain_ctrl(data_arr4_datain_ctrl),
	.cacheline_out_ctrl(cacheline_out_ctrl),
	.ld_tag1(ld_tag1),
	.ld_tag2(ld_tag2),
	.tag1_out(tag1_out),
	.tag2_out(tag2_out),
	.ld_tag3(ld_tag3),
	.ld_tag4(ld_tag4),
	.tag3_out(tag3_out),
	.tag4_out(tag4_out),
	.ld_dirty1(ld_dirty1),
   .dirty1_in(dirty1_in),
   .dirty1_out(dirty1_out),
   .ld_dirty2(ld_dirty2),
   .dirty2_in(dirty2_in),
   .dirty2_out(dirty2_out),
	.ld_dirty3(ld_dirty3),
   .dirty3_in(dirty3_in),
   .dirty3_out(dirty3_out),
   .ld_dirty4(ld_dirty4),
   .dirty4_in(dirty4_in),
   .dirty4_out(dirty4_out),
	.ld_lru(ld_lru),
	.lru_in(lru_in),
	.lru_out(lru_out),
   .ld_valid1(ld_valid1),
   .valid1_in(valid1_in),
   .valid1_out(valid1_out),
   .ld_valid2(ld_valid2),
   .valid2_in(valid2_in),
   .valid2_out(valid2_out),
	.ld_valid3(ld_valid3),
   .valid3_in(valid3_in),
   .valid3_out(valid3_out),
   .ld_valid4(ld_valid4),
   .valid4_in(valid4_in),
   .valid4_out(valid4_out)
);

bus_adapter bus_adapter
(
	.mem_wdata256(mem_wdata256_bus),
   .mem_rdata256(mem_rdata256_bus),//output cache
   .mem_wdata(mem_wdata),
   .mem_rdata(mem_rdata),
   .mem_byte_enable(mem_byte_enable),
   .mem_byte_enable256(mem_byte_enable256),
   .address(mem_address)
);

endmodule : cache
