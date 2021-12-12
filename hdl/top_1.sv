import sched_structs::*;

module top_1 (
    // input clk,
    // input rst,

    // output logic pmem_read,
    // output logic pmem_write,
    // output logic [31:0] pmem_address,
    // input [63:0] pmem_rdata,
    // output [63:0] pmem_wdata,
    // input logic pmem_resp
    input clk,
    input rst,
    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output [31:0] pmem_address,
    output [63:0] pmem_wdata
);

// assign mbe = '1;

logic fetch_mem_read;
logic ld_st_mem_read;
logic ld_st_mem_write;
logic [31:0] fetch_mem_address, ld_st_mem_address;
logic [31:0] ld_st_mem_wdata, fetch_mem_rdata, ld_st_mem_rdata;
logic fetch_mem_resp, ld_st_mem_resp, prefetch_mem_read, prefetch_mem_resp;

//cacheline adapter and arbiter signal
logic [255:0] line_o, line_i;
logic [255:0] instr_line_o, instr_line_i, prefetch_mem_data;
logic [255:0] data_line_o, data_line_i, data_wdata;
logic [31:0] address_instr_cache_to_arbiter, address_data_cache_to_arbiter;
logic resp_instr_arb, read_instr_arb, write_instr_arb;
logic resp_data_arb, read_data_arb, write_data_arb;

logic read_cl, write_cl, resp_o_cl, data_write, prefetch_enable;
logic [31:0] address_cl, inst_addr, data_addr, prefetch_mem_addr;
logic [3:0] mem_byte_enable;

sched_structs::ROBToALL ROBToALL;

logic inst_read, data_read;
always_comb begin
    read_cl ='0;
    write_cl='0;
    address_cl='0;
    if(inst_read | data_read)  begin
        if(inst_read)   begin
            read_cl = inst_read;
            address_cl = inst_addr;
        end
        else if(data_read)   begin
            read_cl = data_read;
            address_cl = data_addr;
        end
    end
    else if(data_write) begin
        write_cl = data_write;
        address_cl = data_addr;
    end
end

//set logic to set read/write signals to CL from arbiter. differentiate between ld/st and fetch
top_0 top_0 (clk, rst, fetch_mem_rdata, fetch_mem_resp, fetch_mem_read, fetch_mem_address,ld_st_mem_rdata, ld_st_mem_resp, ld_st_mem_address, ld_st_mem_wdata, mem_byte_enable, ld_st_mem_read,ld_st_mem_write, ROBToALL);
arbiter arbiter (clk, rst, read_instr_arb, read_data_arb, write_data_arb, resp_o_cl, line_o, address_instr_cache_to_arbiter, address_data_cache_to_arbiter, data_line_i, instr_line_o, prefetch_mem_data, data_line_o, data_wdata, inst_addr, data_addr, inst_read, data_read, data_write, resp_instr_arb, resp_data_arb, prefetch_mem_resp, prefetch_enable, prefetch_mem_read, prefetch_mem_addr);

cache instr_cache(
	.clk(clk),
	.rst(rst),
	
	.mem_read(fetch_mem_read),
	.mem_write(1'b0),
	.mem_address(fetch_mem_address),
	.mem_wdata('0),
	.mem_byte_enable('0),
	.mem_rdata(fetch_mem_rdata),
	.mem_resp(fetch_mem_resp),
	
	//MP1 arbiter
   .pmem_rdata(instr_line_o),   //need to connect this signal
   .pmem_resp(resp_instr_arb), 
	.pmem_address(address_instr_cache_to_arbiter),
   .pmem_read(read_instr_arb),
   .pmem_write(write_instr_arb),    //blank signal, does not go anywhere as instr doesnt write
	.pmem_wdata(instr_line_i),  //blank signal, does not go anywhere as instr doesnt write
	.ROBToALL()
	);


cache data_cache(
	.clk(clk),
	.rst(rst),
	
	.mem_read(ld_st_mem_read),
	.mem_write(ld_st_mem_write),
	.mem_address(ld_st_mem_address),
	.mem_wdata(ld_st_mem_wdata),
	.mem_byte_enable(mem_byte_enable),
	.mem_rdata(ld_st_mem_rdata),
	.mem_resp(ld_st_mem_resp),
	
	//MP1 arbiter
   .pmem_rdata(data_line_o),    //need to connect this signal
   .pmem_resp(resp_data_arb),  
    .pmem_address(address_data_cache_to_arbiter),
   .pmem_read(read_data_arb),
   .pmem_write(write_data_arb),
	.pmem_wdata(data_line_i),
	.ROBToALL(ROBToALL)
);

prefetcher prefetching_unit(
    .clk(clk),
    .rst(rst),
    .prefetch_enable(prefetch_enable),
    .prefetch_mem_read(prefetch_mem_read),
    .prefetch_mem_addr(prefetch_mem_addr),
    .prefetch_mem_resp(prefetch_mem_resp),
    .prefetch_mem_data(prefetch_mem_data),
    .icache_read(read_instr_arb),
    .icache_addr(address_instr_cache_to_arbiter),
    .dcache_read(read_data_arb),
    .dcache_write(write_data_arb)
);

// From MP1
cacheline_adaptor instr_cacheline_adaptor
(
	 .clk(clk),
    .reset_n(~rst),

    // Port from arbiter
    .line_i(data_wdata),
    .line_o(line_o),
    .address_i(address_cl),
    .read_i(read_cl),
    .write_i(write_cl),
    .resp_o(resp_o_cl),

    // Port to memory
    .burst_i(pmem_rdata),
    .burst_o(pmem_wdata),
    .address_o(pmem_address),
    .read_o(pmem_read),
    .write_o(pmem_write),
    .resp_i(pmem_resp)
);

endmodule