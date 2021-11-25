package ld_st_structs_tb;
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

typedef struct packed {
 logic [4:0] dest_rob;
 logic [31:0] value;
 logic valid;
}data_bus;

typedef struct packed {
    logic valid;
    logic [31:0] value;
    logic [4:0] dest_rob;
	 logic st;
} LD_ST_bus;

typedef struct packed {
 logic [4:0] dest_rob;
 logic value;
 logic valid;
}data_bus_CMP;

typedef struct packed {
 logic [31:0] value;
 logic valid;
 logic [4:0] dest_rob;
}data_bus_ld_st;

endpackage : ld_st_structs_tb
//////////////////////////

module LD_ST_tb;

logic clk, rst;
ld_st_structs_tb::IQtoLD_ST IQtoLD_ST;

ld_st_structs_tb::data_bus bus[5];
ld_st_structs_tb::data_bus_CMP data_bus_CMP;
ld_st_structs_tb::data_bus_ld_st data_bus_ld_st;

ld_st_structs_tb::LD_ST_bus LD_ST_bus;

logic cir_q_full;
    /*memory*/
logic pmem_read;
logic [31:0] pmem_rdata;

logic pmem_resp;
logic [31:0] pmem_address;

logic pmem_write;
logic [31:0] pmem_wdata;
/*memory*/
always #5 clk = (clk === 1'b0);

default clocking cb @(posedge clk);
	output rst, IQtoLD_ST, bus, pmem_rdata, pmem_resp, data_bus_CMP, data_bus_ld_st;
   input LD_ST_bus, cir_q_full, pmem_read, pmem_address, pmem_write, pmem_wdata;
endclocking

LD_ST_top dut(.*);


function void IQ2LD_ST(ld_st_structs_tb::IQtoLD_ST issue, ld_st_structs_tb::IQtoLD_ST ld_st, ld_st_structs_tb::IQtoLD_ST mem_addr, ld_st_structs_tb::IQtoLD_ST src_rob_mem_addr, ld_st_structs_tb::IQtoLD_ST valid_src_mem_addr, ld_st_structs_tb::IQtoLD_ST write_data, ld_st_structs_tb::IQtoLD_ST src_rob_write_data, ld_st_structs_tb::IQtoLD_ST src_valid_write_data, ld_st_structs_tb::IQtoLD_ST dest_rob, ld_st_structs_tb::IQtoLD_ST funct3);
begin
	cb.IQtoLD_ST.issue = issue;
	cb.IQtoLD_ST.ld_st = ld_st;
	cb.IQtoLD_ST.mem_addr = mem_addr;
	cb.IQtoLD_ST.src_rob_mem_addr = src_rob_mem_addr;
	cb.IQtoLD_ST.valid_src_mem_addr = valid_src_mem_addr;
	cb.IQtoLD_ST.write_data = write_data;
	cb.IQtoLD_ST.src_rob_write_data = src_rob_write_data;
	cb.IQtoLD_ST.src_valid_write_data = src_valid_write_data;
	cb.IQtoLD_ST.dest_rob = dest_rob;
	cb.IQtoLD_ST.funct3 = funct3;
	end
endfunction

task reset;
	cb.rst <= 1'b1;
	##10;
	IQ2LD_ST(1'b0, 1'b0, '0, '0, 1'b0, '0, '0, 1'b1, '0, '0);
	##10;
	cb.data_bus_ld_st.valid = '0;
	cb.data_bus_ld_st.value = '0;
	cb.data_bus_ld_st.dest_rob = '0;
	cb.bus[1].valid = '0;
	cb.bus[1].value = '0;
	cb.bus[1].dest_rob = '0;
	
	cb.rst <= 1'b0;
	##10;
endtask : reset

initial begin
	reset();
	##20;
	IQ2LD_ST(1'b1, 1'b0, 32'b011110, 4'b1010, 1'b1, 32'b00001, 4'b0001, 1'b1, 4'b1111, 3'b000);
	##1;
	cb.IQtoLD_ST.issue = '0;
	cb.IQtoLD_ST.ld_st = '0;
	cb.IQtoLD_ST.mem_addr = '0;
	cb.IQtoLD_ST.src_rob_mem_addr = '0;
	cb.IQtoLD_ST.valid_src_mem_addr = '0;
	cb.IQtoLD_ST.write_data = '0;
	cb.IQtoLD_ST.src_rob_write_data = '0;
	cb.IQtoLD_ST.src_valid_write_data = '0;
	cb.IQtoLD_ST.dest_rob = '0;
	##1;
	IQ2LD_ST(1'b1, 1'b0, 32'b001111, 4'b1111, 1'b1, 32'b00001, 4'b1010, 1'b1, 4'b1001, 3'b000);
	##1;
	cb.IQtoLD_ST.issue = '0;
	cb.IQtoLD_ST.ld_st = '0;
	cb.IQtoLD_ST.mem_addr = '0;
	cb.IQtoLD_ST.src_rob_mem_addr = '0;
	cb.IQtoLD_ST.valid_src_mem_addr = '0;
	cb.IQtoLD_ST.write_data = '0;
	cb.IQtoLD_ST.src_rob_write_data = '0;
	cb.IQtoLD_ST.src_valid_write_data = '0;
	cb.IQtoLD_ST.dest_rob = '0;
	##1;
	IQ2LD_ST(1'b1, 1'b0, 32'b001100, 4'b1010, 1'b1, 32'b00001, 4'b0001, 1'b0, 4'b1001, 3'b000);
	##1;
	cb.IQtoLD_ST.issue = '0;
	cb.IQtoLD_ST.ld_st = '0;
	cb.IQtoLD_ST.mem_addr = '0;
	cb.IQtoLD_ST.src_rob_mem_addr = '0;
	cb.IQtoLD_ST.valid_src_mem_addr = '0;
	cb.IQtoLD_ST.write_data = '0;
	cb.IQtoLD_ST.src_rob_write_data = '0;
	cb.IQtoLD_ST.src_valid_write_data = '0;
	cb.IQtoLD_ST.dest_rob = '0;
	##1;
	IQ2LD_ST(1'b1, 1'b0, 32'b001110, 4'b1010, 1'b1, 32'b00001, 4'b0001, 1'b0, 4'b1001, 3'b001);
	##1;
	cb.IQtoLD_ST.issue = '0;
	cb.IQtoLD_ST.ld_st = '0;
	cb.IQtoLD_ST.mem_addr = '0;
	cb.IQtoLD_ST.src_rob_mem_addr = '0;
	cb.IQtoLD_ST.valid_src_mem_addr = '0;
	cb.IQtoLD_ST.write_data = '0;
	cb.IQtoLD_ST.src_rob_write_data = '0;
	cb.IQtoLD_ST.src_valid_write_data = '0;
	cb.IQtoLD_ST.dest_rob = '0;
	##1;
	IQ2LD_ST(1'b1, 1'b0, 32'b001110, 4'b1010, 1'b1, 32'b00001, 4'b0001, 1'b0, 4'b1001, 3'b010);
	##1;
	cb.IQtoLD_ST.issue = '0;
	cb.IQtoLD_ST.ld_st = '0;
	cb.IQtoLD_ST.mem_addr = '0;
	cb.IQtoLD_ST.src_rob_mem_addr = '0;
	cb.IQtoLD_ST.valid_src_mem_addr = '0;
	cb.IQtoLD_ST.write_data = '0;
	cb.IQtoLD_ST.src_rob_write_data = '0;
	cb.IQtoLD_ST.src_valid_write_data = '0;
	cb.IQtoLD_ST.dest_rob = '0;
	##1;
//	IQ2LD_ST(1'b1, 1'b0, 32'b001110, 4'b1010, 1'b0, 32'b00001, 4'b0001, 1'b1, 4'b1001);
//	##1;
//	cb.IQtoLD_ST.issue = '0;
//	cb.IQtoLD_ST.ld_st = '0;
//	cb.IQtoLD_ST.mem_addr = '0;
//	cb.IQtoLD_ST.src_rob_mem_addr = '0;
//	cb.IQtoLD_ST.valid_src_mem_addr = '0;
//	cb.IQtoLD_ST.write_data = '0;
//	cb.IQtoLD_ST.src_rob_write_data = '0;
//	cb.IQtoLD_ST.src_valid_write_data = '0;
//	cb.IQtoLD_ST.dest_rob = '0;
//	##1;
//	IQ2LD_ST(1'b1, 1'b0, 32'b001110, 4'b1111, 1'b0, 32'b00001, 4'b0001, 1'b1, 4'b1111);
//	##1;
//	cb.IQtoLD_ST.issue = '0;
//	cb.IQtoLD_ST.ld_st = '0;
//	cb.IQtoLD_ST.mem_addr = '0;
//	cb.IQtoLD_ST.src_rob_mem_addr = '0;
//	cb.IQtoLD_ST.valid_src_mem_addr = '0;
//	cb.IQtoLD_ST.write_data = '0;
//	cb.IQtoLD_ST.src_rob_write_data = '0;
//	cb.IQtoLD_ST.src_valid_write_data = '0;
//	cb.IQtoLD_ST.dest_rob = '0;
//	#10;
//	cb.data_bus_ld_st.valid = 1'b1;
//	cb.data_bus_ld_st.value = 32'b01001;
//	cb.data_bus_ld_st.dest_rob = 4'b1010;
//	cb.bus[1].valid = 1'b1;
//	cb.bus[1].value = 32'b01101;
//	cb.bus[1].dest_rob = 4'b0001;
//	##4; 
//	cb.data_bus_ld_st.valid = 1'b0;
//	cb.data_bus_ld_st.value = '0;
//	cb.data_bus_ld_st.dest_rob = '0;
//	cb.bus[1].valid = 1'b0;
//	cb.bus[1].value = 32'b0;
//	cb.bus[1].dest_rob = 4'b0;
	##20;
	cb.pmem_resp <= 1'b1;
	cb.pmem_rdata <= 32'hff11aa99;
	##1;
	cb.pmem_resp <= '0;
	cb.pmem_rdata <= '0;
	##20;
	cb.pmem_resp <= 1'b1;
	cb.pmem_rdata <= 32'hff11aa99;
	##1;
	cb.pmem_resp <= 1'b0;
	cb.pmem_rdata <= 32'hff11aa99;
	##20;
	cb.pmem_resp <= 1'b1;
	cb.pmem_rdata <= 32'hff11aa99;
	##1;
	cb.pmem_resp <= 1'b0;
	cb.pmem_rdata <= 32'hff11aa99;
	##20;
	cb.pmem_resp <= 1'b1;
	cb.pmem_rdata <= 32'hff11aa99;
	##1;
	cb.pmem_resp <= 1'b0;
	cb.pmem_rdata <= 32'hff11aa99;
	##20;
	cb.pmem_resp <= 1'b1;
	cb.pmem_rdata <= 32'hff11aa99;
	##1;
	cb.pmem_resp <= 1'b0;
	cb.pmem_rdata <= 32'hff11aa99;
	$finish;
end

endmodule : LD_ST_tb