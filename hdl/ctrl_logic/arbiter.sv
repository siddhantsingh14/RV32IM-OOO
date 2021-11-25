// module arbiter
// (
//     input clk,
//     input rst,

//     input mem_read_fetch,
//     input mem_read_ld_unit,
//     input mem_write_ld_unit,
//     input [31:0] mem_wdata_ld_unit,
//     input [31:0] mem_address_fetch,
//     input [31:0] mem_address_ld_unit,


//     input mem_resp,
//     input logic [31:0] mem_rdata,

//     output mem_resp_fetch,
//     output mem_resp_ld_unit,
//     output [31:0] mem_rdata_ld_unit,
//     output [31:0] mem_rdata_fetch,

//     output mem_read,
//     output mem_write,
//     output logic [31:0] mem_address,
//     output logic [31:0] mem_wdata
// );

// logic data_owner;   //0 means give data to fetch unit, 1 to ld_unit
// logic pmem_query;
// logic local_read, local_write;

// always_comb
// begin
//     mem_resp_fetch='0;
//     mem_resp_ld_unit='0;
//     mem_rdata_ld_unit='0;
//     mem_rdata_fetch='0;

//     mem_read=local_read;
//     mem_write=local_write;
//     mem_address='0;
//     mem_wdata='0;
//     if(rst) begin
//         mem_resp_fetch = '0;
//         mem_resp_ld_unit='0;
//     end
//     else    begin
//         if(~pmem_query) begin
//             if(mem_read_fetch | mem_read_ld_unit)   begin
//                 if(mem_read_fetch & mem_read_ld_unit)   begin
//                     data_owner = '0;
//                     pmem_query='1;
//                     mem_address=mem_address_fetch;
//                     mem_read='1;
//                     local_read= mem_read;
//                 end
//                 else if(mem_read_fetch)   begin
//                     data_owner = '0;
//                     pmem_query='1;
//                     mem_address=mem_address_fetch;
//                     mem_read='1;
//                     local_read= mem_read;
//                 end
//                 else if(mem_read_ld_unit)   begin
//                     data_owner = '1;
//                     pmem_query='1;
//                     mem_address=mem_address_ld_unit;
//                     mem_read='1;
//                     local_read= mem_read;
//                 end
//             end
//             else if(mem_write_ld_unit)  begin
//                 mem_wdata=mem_wdata_ld_unit;
//                 data_owner = '1;
//                 pmem_query='1;
//                 mem_address=mem_address_ld_unit;
//                 mem_write='1;
//                 local_write=mem_write;
//             end
//         end
        
//         if(mem_resp)    begin
//             if(local_write) begin
//                 local_write='0;
//                 mem_write ='0;
//                 pmem_query='0;
//                 if(~data_owner) begin
//                     mem_resp_fetch = '1;
//                 end
//                 else if(data_owner) begin
//                     mem_resp_ld_unit = '1;
//                 end
//             end
//             else if(local_read) begin
//                 local_read='0;
//                 if(~data_owner) begin   //means give data to fetch unit
//                     mem_read='0;
//                     mem_rdata_fetch=mem_rdata;
//                     mem_resp_fetch = '1;
//                     pmem_query='0;
//                 end
//                 else    begin
//                     mem_read='0;
//                     mem_rdata_ld_unit=mem_rdata;
//                     mem_resp_ld_unit = '1;
//                     pmem_query='0;
//                 end
//             end
//         end
//     end
// end

// endmodule