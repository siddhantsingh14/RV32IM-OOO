/*Instruction que to be connected to this module; or added to it with rob instantation*/
import rv_structs::*;
import Ld_St_structs::*;
import sched_structs::*;
import rob_entry_structs::*;

module RS_ALU(
    input clk,
    input rst,
   
   /*inputs from IQ*/
    input rv_structs::IQtoRS IQtoRS,
	input rv_structs::IQtoRS_br IQtoRS_br,
	input sched_structs::IQtoRS_ld_st IQtoRS_ld_st,

    input Ld_St_structs::LD_ST_bus LD_ST_bus,

    input rob_entry_structs::rob_to_regfile rob_to_regfile,

	output [1:0] RS_unit1, RS_unit2, RS_unit3, RS_unit4, RS_unit5, RS_unit_CMP_6,//going to instr scheduler to tell which ones are empty; will convert to packed struct if needed
	output RS_unit_BR, RS_unit_ld_st,

    output rv_structs::data_bus bus[5],
    output rv_structs::data_bus_CMP data_bus_CMP,
    output rv_structs::data_bus_CMP_br data_bus_CMP_br,
    output rv_structs::data_bus_ld_st data_bus_ld_st,
    input sched_structs::ROBToALL ROBToALL
);

rv_structs::RStoALU RStoALU[6];
rv_structs::RStoCMP RStoCMP;
rv_structs::RStoCMP_br RStoCMP_br;
rv_structs::RStoALU_ld_st RStoALU_ld_st;

logic rst_flush;

assign rst_flush = rst | ROBToALL.flush_all;

RS Reservation_stations(
	.clk(clk),
    .rst(rst_flush),

    /*inputs from IQ*/
    .IQtoRS(IQtoRS),
    .IQtoRS_br(IQtoRS_br),
    .IQtoRS_ld_st(IQtoRS_ld_st),
    .rob_to_regfile(rob_to_regfile),
    /*inputs from busses*/
    .bus(bus),
    .LD_ST_bus(LD_ST_bus),
    .data_bus_CMP(data_bus_CMP),
    /*Outputs*/
    .RS_unit1(RS_unit1), .RS_unit2(RS_unit2), .RS_unit3(RS_unit3), .RS_unit4(RS_unit4), .RS_unit5(RS_unit5), .RS_unit_CMP_6(RS_unit_CMP_6), .RS_unit_BR(RS_unit_BR), .RS_unit_ld_st(RS_unit_ld_st),
    .RStoALU(RStoALU),
    .RStoCMP(RStoCMP),
    .RStoCMP_br(RStoCMP_br),
    .RStoALU_ld_st(RStoALU_ld_st)
);

alu alus(
	 /*input*/
	 .RStoALU(RStoALU),
	 
	 /*output*/
    .bus(bus)
);

cmp cmp(
    .RStoCMP(RStoCMP),
	 
	 /*output*/
    .data_bus_CMP(data_bus_CMP)
);

cmp_br cmp_br(
    .RStoCMP_br(RStoCMP_br),
	 
	 /*output*/
    .data_bus_CMP_br(data_bus_CMP_br)
);

alu_ld_st alu_ld_st(
	 /*input*/
	 .RStoALU_ld_st(RStoALU_ld_st),
	 
	 /*output*/
    .data_bus_ld_st(data_bus_ld_st)
);

endmodule : RS_ALU