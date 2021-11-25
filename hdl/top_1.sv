module top_1 (
    input clk,
    input rst,

    input logic [31:0] inst_rdata,
    input logic [31:0] data_rdata, 
    input logic inst_resp,
    input logic data_resp,

    output logic [31:0] inst_addr,
    output logic [31:0] data_addr,
    output logic [31:0] data_wdata,
    output logic inst_read,
    output logic data_read,
    output logic data_write,
    output logic [4:0] mbe
);

assign mbe = '1;

logic fetch_mem_read;
logic ld_st_mem_read;
logic ld_st_mem_write;
logic [31:0] fetch_mem_address, ld_st_mem_address;
logic [31:0] ld_st_mem_wdata, fetch_mem_rdata, ld_st_mem_rdata;
logic fetch_mem_resp, ld_st_mem_resp;

top_0 top_0 (clk, rst, fetch_mem_rdata, fetch_mem_resp, fetch_mem_read, fetch_mem_address,ld_st_mem_rdata, ld_st_mem_resp, ld_st_mem_address, ld_st_mem_wdata, ld_st_mem_read,ld_st_mem_write);
arbiter arbiter (clk, rst, fetch_mem_read, ld_st_mem_read, ld_st_mem_write, inst_resp, data_resp, inst_rdata, data_rdata, fetch_mem_address, ld_st_mem_address, ld_st_mem_wdata, fetch_mem_rdata, ld_st_mem_rdata, data_wdata, inst_addr, data_addr, inst_read, data_read, data_write, fetch_mem_resp, ld_st_mem_resp);

endmodule