package rv_structs_tb;
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


typedef struct packed {
    logic valid;
    logic [31:0] value;
    logic [4:0] dest_rob;//MASK WHEN WRITING TO THIS VARIABLE
	 logic st;//1 if store
} LD_ST_bus;

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

endpackage : rv_structs_tb
////////////////////

module RS_tb;

logic clk, rst;
 /*inputs from IQ*/
rv_structs_tb::IQtoRS IQtoRS;
rv_structs_tb::IQtoRS_br IQtoRS_br;
rv_structs_tb::IQtoRS_ld_st IQtoRS_ld_st;
rv_structs_tb::LD_ST_bus LD_ST_bus;
logic [1:0] RS_unit1, RS_unit2, RS_unit3, RS_unit4, RS_unit5, RS_unit_CMP_6;//going to instr scheduler to tell which ones are empty; will convert to packed struct if needed
logic RS_unit_BR, RS_unit_ld_st;
rv_structs_tb::data_bus bus[5];//going to ROB
rv_structs_tb::data_bus_CMP data_bus_CMP;
rv_structs_tb::data_bus_CMP_br data_bus_CMP_br;
rv_structs_tb::data_bus_ld_st data_bus_ld_st;
always #5 clk = (clk === 1'b0);

default clocking cb @(posedge clk);
	output rst, IQtoRS, IQtoRS_br, IQtoRS_ld_st, LD_ST_bus;
   input RS_unit1, RS_unit2, RS_unit3, RS_unit4, RS_unit5, RS_unit_CMP_6, bus, data_bus_CMP, data_bus_CMP_br, data_bus_ld_st;
endclocking

RS_ALU dut(.*);

function void IQ2RS_br(rv_structs_tb::IQtoRS_br load_RS, rv_structs_tb::IQtoRS_br alu_ops, rv_structs_tb::IQtoRS_br src1_rob, rv_structs_tb::IQtoRS_br src1_value, rv_structs_tb::IQtoRS_br src1_valid, rv_structs_tb::IQtoRS_br src2_rob, rv_structs_tb::IQtoRS_br src2_value, rv_structs_tb::IQtoRS_br src2_valid, rv_structs_tb::IQtoRS_br br_pc_out, rv_structs_tb::IQtoRS_br dest_rob);
	begin
	cb.IQtoRS_br.load_RS = load_RS;
	cb.IQtoRS_br.alu_ops = alu_ops;
	cb.IQtoRS_br.src1_rob = src1_rob;
	cb.IQtoRS_br.src1_value = src1_value;
	cb.IQtoRS_br.src1_valid = src1_valid;
	cb.IQtoRS_br.src2_rob = src2_rob;
	cb.IQtoRS_br.src2_value = src2_value;
	cb.IQtoRS_br.src2_valid = src2_valid;
	cb.IQtoRS_br.br_pc_out = br_pc_out;
	cb.IQtoRS_br.dest_rob = dest_rob;
	end

endfunction

function void IQ2RS_ld_st(rv_structs_tb::IQtoRS_ld_st load_RS, rv_structs_tb::IQtoRS_ld_st src1_rob, rv_structs_tb::IQtoRS_ld_st src1_val, rv_structs_tb::IQtoRS_ld_st src1_valid, rv_structs_tb::IQtoRS_ld_st src2_rob, rv_structs_tb::IQtoRS_ld_st src2_val, rv_structs_tb::IQtoRS_ld_st src2_valid, rv_structs_tb::IQtoRS_ld_st dest_rob);
	begin
	cb.IQtoRS_ld_st.load_RS = load_RS;
	cb.IQtoRS_ld_st.src1_rob = src1_rob;
	cb.IQtoRS_ld_st.src1_val = src1_val;
	cb.IQtoRS_ld_st.src1_valid = src1_valid;
	cb.IQtoRS_ld_st.src2_rob = src2_rob;
	cb.IQtoRS_ld_st.src2_val = src2_val;
	cb.IQtoRS_ld_st.src2_valid = src2_valid;
	cb.IQtoRS_ld_st.dest_rob = dest_rob;
	end

endfunction

function void IQ2RS(rv_structs_tb::IQtoRS load_RS, rv_structs_tb::IQtoRS RS_sel, rv_structs_tb::IQtoRS dest_rob, rv_structs_tb::IQtoRS alu_ops, rv_structs_tb::IQtoRS src1_rob, rv_structs_tb::IQtoRS src1_value, rv_structs_tb::IQtoRS src1_valid, rv_structs_tb::IQtoRS src2_rob, rv_structs_tb::IQtoRS src2_value, rv_structs_tb::IQtoRS src2_valid);
	begin
	cb.IQtoRS.load_RS = load_RS;
	cb.IQtoRS.RS_sel = RS_sel;
	cb.IQtoRS.dest_rob = dest_rob;
	cb.IQtoRS.alu_ops = alu_ops;
	cb.IQtoRS.src1_rob = src1_rob;
	cb.IQtoRS.src1_value = src1_value;
	cb.IQtoRS.src1_valid = src1_valid;
	cb.IQtoRS.src2_rob = src2_rob;
	cb.IQtoRS.src2_value = src2_value;
	cb.IQtoRS.src2_valid = src2_valid;
	end

endfunction

task reset;
	cb.rst <= 1'b1;
	IQ2RS('0,'0,'0,'0,'0,'0,'0,'0,'0,'0);
	/*    l,sl,dr,alu,1r,1va,1v,2r,2va,2v*/
	##10;
	
	cb.rst <= 1'b0;
	
	##10;
	
	assert(!(cb.RS_unit1 | cb.RS_unit2 | cb.RS_unit3 | cb.RS_unit4 | cb.RS_unit5)) else begin
		$display("ERROR: RS not empty after reset");
	end
	
	for(logic [2:0] i = 3'b000; i < 3'b101; i++)
	begin
		assert(!(cb.bus[0].valid)) else begin
			$display("ERROR: bus %0d is valid after reset", i);
		end
	end
endtask : reset

task check1;
	IQ2RS(1'b1, 4'b0000, 5'b00101, 3'b000, 5'b00001, 32'b00101, 1'b1, 5'b00101, 32'b00111, 1'b1);
	/*   ld_RS, RS_sel,    dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
	##1;
	
	assert(cb.RS_unit1 == 2'b10) else begin
		$display("ERROR:Not showing correct status1 %0d, 10--", cb.RS_unit1);//add a timestamp
	end
	IQ2RS(1'b1, 4'b0001, 5'b0011, 3'b011, 5'b00001, 32'b00111, 1'b1, 5'b00101, 32'b00001, 1'b1);
	/*   ld_RS, RS_sel,    dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
	
	##1;
	
	assert(cb.RS_unit1 == 2'b01) else begin
		$display("ERROR:Not showing correct status1 %0d, 10--", cb.RS_unit1);
	end
	IQ2RS(1'b1, 4'b0000, 5'b0010, 3'b011, 5'b00001, 32'b01111, 1'b1, 5'b00111, 32'b00111, 1'b1);
	/*   ld_RS, RS_sel,    dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
	

	##1;
	assert(cb.RS_unit1 == 2'b10) else begin
		$display("ERROR:Not showing correct status1");
	end
	cb.IQtoRS.load_RS <= 1'b0;
	
	

	##1;
	
	
	
endtask : check1

task check2;
	IQ2RS(1'b1, 4'b0010, 5'b00101, 3'b000, 5'b00001, 32'b00101, 1'b1, 5'b00101, 32'b00111, 1'b1);
	/*   ld_RS, RS_sel,    dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
	##1;
	
	IQ2RS(1'b1, 4'b0011, 5'b0011, 3'b011, 5'b00001, 32'b00111, 1'b1, 5'b00101, 32'b00001, 1'b1);
	/*   ld_RS, RS_sel,    dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
	
	##1;
	
	IQ2RS(1'b1, 4'b0010, 5'b0010, 3'b011, 5'b00001, 32'b01111, 1'b1, 5'b00111, 32'b00111, 1'b1);
	/*   ld_RS, RS_sel,    dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
	assert(cb.RS_unit2 == 2'b10) else begin
		$display("ERROR:Not showing correct status2 %0d, 10--", cb.RS_unit1);
	end

	##1;
	
	cb.IQtoRS.load_RS <= 1'b0;
	assert(cb.RS_unit2 == 2'b01) else begin
		$display("ERROR:Not showing correct status2 %0d, 10--", cb.RS_unit1);
	end
	

	##1;
	
	assert(cb.RS_unit2 == 2'b10) else begin
		$display("ERROR:Not showing correct status2");
	end
	
endtask : check2

task check3;
	IQ2RS(1'b1, 4'b0100, 5'b00101, 3'b000, 5'b00001, 32'b00101, 1'b1, 5'b00101, 32'b00111, 1'b1);
	/*   ld_RS, RS_sel,    dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
	##1;
	
	IQ2RS(1'b1, 4'b0101, 5'b0011, 3'b011, 5'b00001, 32'b00111, 1'b1, 5'b00101, 32'b00001, 1'b1);
	/*   ld_RS, RS_sel,    dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
	
	##1;
	
	IQ2RS(1'b1, 4'b0100, 5'b0010, 3'b011, 5'b00001, 32'b01111, 1'b1, 5'b00111, 32'b00111, 1'b1);
	/*   ld_RS, RS_sel,    dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
	assert(cb.RS_unit3 == 2'b10) else begin
		$display("ERROR:Not showing correct status3 %0d, 10--", cb.RS_unit1);
	end

	##1;
	
	cb.IQtoRS.load_RS <= 1'b0;
	assert(cb.RS_unit3 == 2'b01) else begin
		$display("ERROR:Not showing correct status3 %0d, 10--", cb.RS_unit1);
	end
	

	##1;
	
	assert(cb.RS_unit3 == 2'b10) else begin
		$display("ERROR:Not showing correct statu3s");
	end
	
endtask : check3

task check4;
	IQ2RS(1'b1, 4'b0110, 5'b00101, 3'b000, 5'b00001, 32'b00101, 1'b1, 5'b00101, 32'b00111, 1'b1);
	/*   ld_RS, RS_sel,    dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
	##1;
	
	IQ2RS(1'b1, 4'b0111, 5'b0011, 3'b011, 5'b00001, 32'b00111, 1'b1, 5'b00101, 32'b00001, 1'b1);
	/*   ld_RS, RS_sel,    dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
	
	##1;
	
	IQ2RS(1'b1, 4'b0110, 5'b0010, 3'b011, 5'b00001, 32'b01111, 1'b1, 5'b00111, 32'b00111, 1'b1);
	/*   ld_RS, RS_sel,    dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
	assert(cb.RS_unit4 == 2'b10) else begin
		$display("ERROR:Not showing correct status 4%0d, 10--", cb.RS_unit1);
	end

	##1;
	
	cb.IQtoRS.load_RS <= 1'b0;
	assert(cb.RS_unit4 == 2'b01) else begin
		$display("ERROR:Not showing correct status 4%0d, 10--", cb.RS_unit1);
	end
	

	##1;
	
	assert(cb.RS_unit4 == 2'b10) else begin
		$display("ERROR:Not showing correct status4");
	end
	
endtask : check4

task check5;
	IQ2RS(1'b1, 4'b1000, 5'b00101, 3'b000, 5'b00001, 32'b00101, 1'b1, 5'b00101, 32'b00111, 1'b1);
	/*   ld_RS, RS_sel,    dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
	##1;
//	assert(cb.RS_unit5 == -2) else begin
//		$display("ERROR:Not showing correct status5 %0d, 10--", cb.RS_unit5);
//	end
	IQ2RS(1'b1, 4'b1001, 5'b0011, 3'b011, 5'b00001, 32'b00111, 1'b1, 5'b00101, 32'b00001, 1'b1);
	/*   ld_RS, RS_sel,    dr_rob,alu_ops, 	   1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
	
	##1;
	
	IQ2RS(1'b1, 4'b1000, 5'b0010, 3'b011, 5'b00001, 32'b01111, 1'b1, 5'b00111, 32'b00111, 1'b1);
	/*   ld_RS, RS_sel,    dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
//	assert(cb.RS_unit5 == 1) else begin
//		$display("ERROR:Not showing correct status5 %0d, 10--", cb.RS_unit5);
//	end

	##1;
	
	cb.IQtoRS.load_RS <= 1'b0;
//	assert(cb.RS_unit5 == -2) else begin
//		$display("ERROR:Not showing correct status5 %0d, 10--", cb.RS_unit5);
//	end
	

	##1;
	
//	assert(cb.RS_unit5 == 2'b10) else begin
//		$display("ERROR:Not showing correct status5");
//	end
	
endtask : check5

task checkRAW1();
IQ2RS(1'b1, 4'b0000, 5'b1000, 3'b000, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,   dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b0001, 5'b1100, 3'b011, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,  dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b1000, 5'b1001, 3'b000, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,   dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b1001, 5'b1011, 3'b011, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,   dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b0101, 5'b00110, 3'b000, 5'b00001, 32'b00101, 1'b1, 5'b00101, 32'b00101, 1'b1);
	/*ld_RS,  RS_sel,   dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b0110, 5'b00111, 3'b000, 5'b00001, 32'b00101, 1'b1, 5'b00101, 32'b01010, 1'b1);
	/*ld_RS,  RS_sel,   dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

cb.IQtoRS.load_RS <= 1'b0;

endtask : checkRAW1

task checkRAW2();
IQ2RS(1'b1, 4'b0000, 5'b1000, 3'b000, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,   dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b0001, 5'b1100, 3'b011, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,  dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b0010, 5'b1001, 3'b000, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,   dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b0011, 5'b1011, 3'b011, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,   dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b0101, 5'b00110, 3'b000, 5'b00001, 32'b00101, 1'b1, 5'b00101, 32'b00101, 1'b1);
	/*ld_RS,  RS_sel,   dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b0110, 5'b00111, 3'b000, 5'b00001, 32'b00101, 1'b1, 5'b00101, 32'b01010, 1'b1);
	/*ld_RS,  RS_sel,   dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

cb.IQtoRS.load_RS <= 1'b0;

endtask : checkRAW2


task checkRAW3();
IQ2RS(1'b1, 4'b0000, 5'b1000, 3'b000, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,   dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b0001, 5'b1100, 3'b011, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,  dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b0010, 5'b1001, 3'b000, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,   dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b0011, 5'b1011, 3'b011, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,   dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b0100, 5'b1000, 3'b000, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,   dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b0111, 5'b1100, 3'b011, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,  dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b1000, 5'b1001, 3'b000, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,   dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b1001, 5'b1011, 3'b011, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,   dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b0101, 5'b00110, 3'b000, 5'b00001, 32'b00101, 1'b1, 5'b00101, 32'b00101, 1'b1);
	/*ld_RS,  RS_sel,   dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b0110, 5'b00111, 3'b000, 5'b00001, 32'b00101, 1'b1, 5'b00101, 32'b01010, 1'b1);
	/*ld_RS,  RS_sel,   dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

cb.IQtoRS.load_RS <= 1'b0;

endtask : checkRAW3


task check_updates();

IQ2RS(1'b1, 4'b0000, 5'b01000, 3'b000, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,   dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b0001, 5'b01100, 3'b011, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,  dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b1010, 5'b00001, 3'b001, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,  dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b1011, 5'b00010, 3'b000, 5'b00110, 32'b00101, 1'b0, 5'b00111, 32'b00101, 1'b0);
	/*ld_RS,  RS_sel,  dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS_br(1'b1, 3'b000, 5'b00010, 32'b00101, 1'b0, 5'b01100, 32'b00101, 1'b0, 32'b001111101, 5'b11011);
	/*ld_RS,  alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v   br_pc_out, dest_rob*/
##1;

IQ2RS_ld_st(1'b1,  5'b00010, 32'b00101, 1'b0, 5'b01100, 32'b00101, 1'b0, 5'b10001);
	/*      ld_RS,    1_rob,      1_va,   1v,	   2_rob,	   2_va,  2_v,  dest_rob*/
##1;


IQ2RS(1'b1, 4'b0010,  5'b00110, 3'b000, 5'b00110, 32'b01010, 1'b1, 5'b00111, 32'b00101, 1'b1);
	/*ld_RS, RS_sel, dest_rob, alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS(1'b1, 4'b0011, 5'b00111, 3'b011, 5'b00110, 32'b01010, 1'b1, 5'b00111, 32'b00101, 1'b1);
	/*ld_RS,  RS_sel,  dr_rob,alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##1;

IQ2RS_br(1'b0, 3'b000, 5'b00010, 32'b00101, 1'b0, 5'b01100, 32'b00101, 1'b0, 32'b001111101, 5'b11010);
	/*ld_RS,  alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v   br_pc_out*/


IQ2RS_ld_st(1'b0,  5'b00010, 32'b00101, 1'b0, 5'b01100, 32'b00101, 1'b0, 5'b10001);
	/*      ld_RS,    1_rob,      1_va,   1v,	   2_rob,	   2_va,  2_v,  dest_rob*/

IQ2RS(1'b0, 4'b0010,  5'b00110, 3'b000, 5'b00110, 32'b01010, 1'b1, 5'b00111, 32'b00101, 1'b1);
	/*ld_RS, RS_sel, dest_rob, alu_ops,    1_rob,      1_va,   1v,	   2_rob,	   2_va, 2_v*/
##2;


endtask : check_updates

initial begin
	$display("Resetting");
	reset();
	$display("Resetted");
//	check1();
//	$display("Check1");
//	check2();
//	$display("Check2");
//	check3();
//	$display("Check3");
//	check4();
//	$display("Check4");
//	check5();
//	$display("Check5");
//	checkRAW1();
//	$display("weird test1");
//	checkRAW2();
////	$display("weird test2");
//	checkRAW3();
//	$display("weird test3");
	check_updates();
	$display("weird test 4");
	##2;
	$finish;
end

endmodule : RS_tb
