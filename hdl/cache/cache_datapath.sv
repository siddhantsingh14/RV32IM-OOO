/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module cache_datapath #(
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
	
	input logic [31:0] mem_addr,
	input logic [255:0] data_bus_in,
	input logic [31:0] bus_en,
	input logic [255:0] data_cacheline_in,
	output logic[255:0] data_cacheline_out,
	
	input logic [1:0] data_arr1_writer_en_ctrl,
	input logic data_arr1_datain_ctrl,
	input logic [1:0] data_arr2_writer_en_ctrl,
	input logic data_arr2_datain_ctrl,
	input logic [1:0] data_arr3_writer_en_ctrl,
	input logic data_arr3_datain_ctrl,
	input logic [1:0] data_arr4_writer_en_ctrl,
	input logic data_arr4_datain_ctrl,
	
	input logic [1:0] cacheline_out_ctrl,
	
	input logic ld_tag1,
	input logic ld_tag2,
	input logic ld_tag3,
	input logic ld_tag4,
	output logic [22:0] tag1_out, tag2_out, tag3_out, tag4_out,
	
	input logic ld_dirty1,
	input logic dirty1_in,
	output logic dirty1_out,
	input logic ld_dirty2,
	input logic dirty2_in,
	output logic dirty2_out,
	input logic ld_dirty3,
	input logic dirty3_in,
	output logic dirty3_out,
	input logic ld_dirty4,
	input logic dirty4_in,
	output logic dirty4_out,
	
	input logic ld_valid1,
	input logic valid1_in,
	output logic valid1_out,
	input logic ld_valid2,
	input logic valid2_in,
	output logic valid2_out,
	input logic ld_valid3,
	input logic valid3_in,
	output logic valid3_out,
	input logic ld_valid4,
	input logic valid4_in,
	output logic valid4_out,
	
	input logic ld_lru,
	input logic [2:0] lru_in,
	output logic [2:0] lru_out
);

logic[255:0] data_array1_out, data_array2_out, data_arr1_datain_mux, data_arr2_datain_mux, data_array3_out, data_array4_out, data_arr3_datain_mux, data_arr4_datain_mux;
logic[31:0] data_arr1_writer_en_mux, data_arr2_writer_en_mux, data_arr3_writer_en_mux, data_arr4_writer_en_mux;

data_array data_array1(
	.clk(clk),
   .rst(rst),
   .read(1'b1),//check
   .write_en(data_arr1_writer_en_mux),
   .rindex(mem_addr[8:5]),
   .windex(mem_addr[8:5]),
   .datain(data_arr1_datain_mux),
   .dataout(data_array1_out)
);

data_array data_array2(
	.clk(clk),
   .rst(rst),
   .read(1'b1),//check
   .write_en(data_arr2_writer_en_mux),
   .rindex(mem_addr[8:5]),
   .windex(mem_addr[8:5]),
   .datain(data_arr2_datain_mux),
   .dataout(data_array2_out)
);

data_array data_array3(
	.clk(clk),
   .rst(rst),
   .read(1'b1),//check
   .write_en(data_arr3_writer_en_mux),
   .rindex(mem_addr[8:5]),
   .windex(mem_addr[8:5]),
   .datain(data_arr3_datain_mux),
   .dataout(data_array3_out)
);

data_array data_array4(
	.clk(clk),
   .rst(rst),
   .read(1'b1),//check
   .write_en(data_arr4_writer_en_mux),
   .rindex(mem_addr[8:5]),
   .windex(mem_addr[8:5]),
   .datain(data_arr4_datain_mux),
   .dataout(data_array4_out)
);

array #(.s_index(4), .width(23))
tag1(
	.clk(clk),
   .rst(rst),
   .read(1'b1),
   .load(ld_tag1),
   .rindex(mem_addr[8:5]),
   .windex(mem_addr[8:5]),
   .datain(mem_addr[31:9]),
   .dataout(tag1_out)
);

array #(.s_index(4), .width(23))
tag2(
	.clk(clk),
   .rst(rst),
   .read(1'b1),
   .load(ld_tag2),
   .rindex(mem_addr[8:5]),
   .windex(mem_addr[8:5]),
   .datain(mem_addr[31:9]),
   .dataout(tag2_out)
);

array #(.s_index(4), .width(23))
tag3(
	.clk(clk),
   .rst(rst),
   .read(1'b1),
   .load(ld_tag3),
   .rindex(mem_addr[8:5]),
   .windex(mem_addr[8:5]),
   .datain(mem_addr[31:9]),
   .dataout(tag3_out)
);

array #(.s_index(4), .width(23))
tag4(
	.clk(clk),
   .rst(rst),
   .read(1'b1),
   .load(ld_tag4),
   .rindex(mem_addr[8:5]),
   .windex(mem_addr[8:5]),
   .datain(mem_addr[31:9]),
   .dataout(tag4_out)
);

array #(.s_index(4), .width(1))
dirty1(
	.clk(clk),
   .rst(rst),
   .read(1'b1),
   .load(ld_dirty1),
   .rindex(mem_addr[8:5]),
   .windex(mem_addr[8:5]),
   .datain(dirty1_in),
   .dataout(dirty1_out)
);

array #(.s_index(4), .width(1))
dirty2(
	.clk(clk),
   .rst(rst),
   .read(1'b1),
   .load(ld_dirty2),
   .rindex(mem_addr[8:5]),
   .windex(mem_addr[8:5]),
   .datain(dirty2_in),
   .dataout(dirty2_out)
);

array #(.s_index(4), .width(1))
dirty3(
	.clk(clk),
   .rst(rst),
   .read(1'b1),
   .load(ld_dirty3),
   .rindex(mem_addr[8:5]),
   .windex(mem_addr[8:5]),
   .datain(dirty3_in),
   .dataout(dirty3_out)
);

array #(.s_index(4), .width(1))
dirty4(
	.clk(clk),
   .rst(rst),
   .read(1'b1),
   .load(ld_dirty4),
   .rindex(mem_addr[8:5]),
   .windex(mem_addr[8:5]),
   .datain(dirty4_in),
   .dataout(dirty4_out)
);

array #(.s_index(4), .width(1))
valid1(
	.clk(clk),
   .rst(rst),
   .read(1'b1),
   .load(ld_valid1),
   .rindex(mem_addr[8:5]),
   .windex(mem_addr[8:5]),
   .datain(valid1_in),
   .dataout(valid1_out)
);


array #(.s_index(4), .width(1))
valid2(
	.clk(clk),
   .rst(rst),
   .read(1'b1),
   .load(ld_valid2),
   .rindex(mem_addr[8:5]),
   .windex(mem_addr[8:5]),
   .datain(valid2_in),
   .dataout(valid2_out)
);

array #(.s_index(4), .width(1))
valid3(
	.clk(clk),
   .rst(rst),
   .read(1'b1),
   .load(ld_valid3),
   .rindex(mem_addr[8:5]),
   .windex(mem_addr[8:5]),
   .datain(valid3_in),
   .dataout(valid3_out)
);


array #(.s_index(4), .width(1))
valid4(
	.clk(clk),
   .rst(rst),
   .read(1'b1),
   .load(ld_valid4),
   .rindex(mem_addr[8:5]),
   .windex(mem_addr[8:5]),
   .datain(valid4_in),
   .dataout(valid4_out)
);


array #(.s_index(4), .width(3))
LRU(
	.clk(clk),
   .rst(rst),
   .read(1'b1),
   .load(ld_lru),
   .rindex(mem_addr[8:5]),
   .windex(mem_addr[8:5]),
   .datain(lru_in),
   .dataout(lru_out)
);

always_comb begin
	unique case (data_arr1_writer_en_ctrl)
		2'b00: data_arr1_writer_en_mux = 32'd0;
		2'b01: data_arr1_writer_en_mux = {32{1'b1}};
		2'b10: data_arr1_writer_en_mux = bus_en;
		default: data_arr1_writer_en_mux = 32'd0;
	endcase
	
	unique case (data_arr1_datain_ctrl)
		1'b0: data_arr1_datain_mux = data_cacheline_in;
		1'b1: data_arr1_datain_mux = data_bus_in;
		default: data_arr1_datain_mux = data_cacheline_in;
	endcase
	
	unique case (data_arr2_writer_en_ctrl)
		2'b00: data_arr2_writer_en_mux = 32'd0;
		2'b01: data_arr2_writer_en_mux = {32{1'b1}};
		2'b10: data_arr2_writer_en_mux = bus_en;
		default: data_arr2_writer_en_mux = 32'd0;
	endcase
	
	unique case (data_arr2_datain_ctrl)
		1'b0: data_arr2_datain_mux = data_cacheline_in;
		1'b1: data_arr2_datain_mux = data_bus_in;
		default: data_arr2_datain_mux = data_cacheline_in;
	endcase
	
	unique case (data_arr3_writer_en_ctrl)
		2'b00: data_arr3_writer_en_mux = 32'd0;
		2'b01: data_arr3_writer_en_mux = {32{1'b1}};
		2'b10: data_arr3_writer_en_mux = bus_en;
		default: data_arr3_writer_en_mux = 32'd0;
	endcase
	
	unique case (data_arr3_datain_ctrl)
		1'b0: data_arr3_datain_mux = data_cacheline_in;
		1'b1: data_arr3_datain_mux = data_bus_in;
		default: data_arr3_datain_mux = data_cacheline_in;
	endcase
	
	unique case (data_arr4_writer_en_ctrl)
		2'b00: data_arr4_writer_en_mux = 32'd0;
		2'b01: data_arr4_writer_en_mux = {32{1'b1}};
		2'b10: data_arr4_writer_en_mux = bus_en;
		default: data_arr4_writer_en_mux = 32'd0;
	endcase
	
	unique case (data_arr4_datain_ctrl)
		1'b0: data_arr4_datain_mux = data_cacheline_in;
		1'b1: data_arr4_datain_mux = data_bus_in;
		default: data_arr4_datain_mux = data_cacheline_in;
	endcase
	
	unique case(cacheline_out_ctrl)
		2'b00: data_cacheline_out = data_array1_out;
		2'b01: data_cacheline_out = data_array2_out;
		2'b10: data_cacheline_out = data_array3_out;
		2'b11: data_cacheline_out = data_array4_out;
		default: data_cacheline_out = data_array1_out;
	endcase
end

endmodule : cache_datapath