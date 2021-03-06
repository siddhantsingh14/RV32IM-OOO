import rv_structs::*;
import Ld_St_structs::*;
import sched_structs::*;
import rob_entry_structs::*;

module RS(
    input clk,
    input rst,

    /*inputs from IQ*/
    input rv_structs::IQtoRS IQtoRS,
	input rv_structs::IQtoRS_br IQtoRS_br,
	input sched_structs::IQtoRS_ld_st IQtoRS_ld_st,
    /*inputs from busses*/
    input rv_structs::data_bus bus[5],
	input Ld_St_structs::LD_ST_bus LD_ST_bus,
	input rv_structs::data_bus_CMP data_bus_CMP,
    input rob_entry_structs::rob_to_regfile rob_to_regfile,
    /*Outputs*/
    output [1:0] RS_unit1, RS_unit2, RS_unit3, RS_unit4, RS_unit5, RS_unit_CMP_6,
	output RS_unit_BR, RS_unit_ld_st,
    output rv_structs::RStoALU RStoALU[6],//[5]
	output rv_structs::RStoCMP RStoCMP,
	output rv_structs::RStoCMP_br RStoCMP_br,
	output rv_structs::RStoALU_ld_st RStoALU_ld_st
 );
 
 rv_structs::Reservation_st res_st[14];
 rv_structs::evict evict[8];
 
 assign RS_unit1 = {res_st[0].valid, res_st[1].valid};
 assign RS_unit2 = {res_st[2].valid, res_st[3].valid};
 assign RS_unit3 = {res_st[4].valid, res_st[5].valid};
 assign RS_unit4 = {res_st[6].valid, res_st[7].valid};
 assign RS_unit5 = {res_st[8].valid, res_st[9].valid};
 assign RS_unit_CMP_6 = {res_st[10].valid, res_st[11].valid};//HAS DEST ROB GOING TO ROB
 assign RS_unit_BR = res_st[12].valid;//NO DEST ROB JUST OUTPUT 
 assign RS_unit_ld_st = res_st[13].valid;//LD_ST
 always_ff @(posedge clk)
 begin
	  if(rst)
	  begin
			for(int i = 0; i < 14; i++)
			begin
				 res_st[i].dest_rob <= '0;
				 res_st[i].alu_ops <= '0;
				 res_st[i].src1_rob <= '0;
				 res_st[i].src1_value <= '0;
				 res_st[i].src1_valid <= 'b0;
				 res_st[i].src2_rob <= '0;
				 res_st[i].src2_value <= '0;
				 res_st[i].src2_valid <= '0;
				 res_st[i].valid <= '0;
			end
	  end
	  else
	  begin
			if(IQtoRS.load_RS)//loading 1 inst from IQ to RS
			begin
				 res_st[IQtoRS.RS_sel].dest_rob <= IQtoRS.dest_rob;
				 res_st[IQtoRS.RS_sel].alu_ops <= IQtoRS.alu_ops;
				 res_st[IQtoRS.RS_sel].valid <= 1'b1;
				 if(IQtoRS.src1_valid)
				 begin
					  res_st[IQtoRS.RS_sel].src1_valid <= IQtoRS.src1_valid;
					  res_st[IQtoRS.RS_sel].src1_value <= IQtoRS.src1_value;
				 end
				 else
				 begin
					  res_st[IQtoRS.RS_sel].src1_valid <= IQtoRS.src1_valid;
					  res_st[IQtoRS.RS_sel].src1_rob <= IQtoRS.src1_rob;
				 end
				 if(IQtoRS.src2_valid)
				 begin
					  res_st[IQtoRS.RS_sel].src2_valid <= IQtoRS.src2_valid;
					  res_st[IQtoRS.RS_sel].src2_value <= IQtoRS.src2_value;
				 end
				 else
				 begin
					  res_st[IQtoRS.RS_sel].src2_valid <= IQtoRS.src2_valid;
					  res_st[IQtoRS.RS_sel].src2_rob <= IQtoRS.src2_rob;
				 end
			end
			if(IQtoRS_ld_st.load_RS)//loading 1 inst from IQ to RS
			begin
				 res_st[13].dest_rob <= IQtoRS_ld_st.dest_rob;
				 res_st[13].alu_ops <= 3'b000;
				 res_st[13].valid <= 1'b1;
				 if(IQtoRS_ld_st.src1_valid)
				 begin
					  res_st[13].src1_valid <= IQtoRS_ld_st.src1_valid;
					  res_st[13].src1_value <= IQtoRS_ld_st.src1_val;
				 end
				 else
				 begin
					  res_st[13].src1_valid <= IQtoRS_ld_st.src1_valid;
					  res_st[13].src1_rob <= IQtoRS_ld_st.src1_rob;
				 end
				 if(IQtoRS_ld_st.src2_valid)
				 begin
					  res_st[13].src2_valid <= IQtoRS_ld_st.src2_valid;
					  res_st[13].src2_value <= IQtoRS_ld_st.src2_val;
				 end
				 else
				 begin
					  res_st[13].src2_valid <= IQtoRS_ld_st.src2_valid;
					  res_st[13].src2_rob <= IQtoRS_ld_st.src2_rob;
				 end
			end
			if(IQtoRS_br.load_RS)//loading 1 inst from IQ to RS
			begin
				 res_st[12].dest_rob <= IQtoRS_br.dest_rob;
				 res_st[12].alu_ops <= IQtoRS_br.alu_ops;
				 res_st[12].valid <= 1'b1;
				 res_st[12].is_jump <= IQtoRS_br.is_jump;
				 res_st[12].is_jump_r <= IQtoRS_br.is_jump_r;
				 res_st[12].pc <= IQtoRS_br.pc;
				 //res_st[12].br_pc_out <= IQtoRS_br.br_pc_out;;
				 if(IQtoRS_br.src1_valid)
				 begin
					  res_st[12].src1_valid <= IQtoRS_br.src1_valid;
					  res_st[12].src1_value <= IQtoRS_br.src1_value;
				 end
				 else
				 begin
					  res_st[12].src1_valid <= IQtoRS_br.src1_valid;
					  res_st[12].src1_rob <= IQtoRS_br.src1_rob;
				 end
				 if(IQtoRS_br.src2_valid)
				 begin
					  res_st[12].src2_valid <= IQtoRS_br.src2_valid;
					  res_st[12].src2_value <= IQtoRS_br.src2_value;
				 end
				 else
				 begin
					  res_st[12].src2_valid <= IQtoRS_br.src2_valid;
					  res_st[12].src2_rob <= IQtoRS_br.src2_rob;
				 end
				 if(IQtoRS_br.br_pc_in1_valid)
				 begin
					  res_st[12].br_pc_in1_valid <= IQtoRS_br.br_pc_in1_valid;
					  res_st[12].br_pc_in1_value <= IQtoRS_br.br_pc_in1_value;
				 end
				 else
				 begin
					  res_st[12].br_pc_in1_valid <= IQtoRS_br.br_pc_in1_valid;
					  res_st[12].br_pc_in1_rob <= IQtoRS_br.br_pc_in1_rob;
				 end
				 if(IQtoRS_br.br_pc_in2_valid)
				 begin
					  res_st[12].br_pc_in2_valid <= IQtoRS_br.br_pc_in2_valid;
					  res_st[12].br_pc_in2_value <= IQtoRS_br.br_pc_in2_value;
				 end
				 else
				 begin
					  res_st[12].br_pc_in2_valid <= IQtoRS_br.br_pc_in2_valid;
					  res_st[12].br_pc_in2_rob <= IQtoRS_br.br_pc_in2_rob;
				 end
			end
			/*Check busses coming from all execution units; TODO:LOAD/STORE UNIT*/
			if(bus[0].valid)
			begin
				 for(int i = 0; i < 14; i++)
				 begin
					  if((res_st[i].valid) && (res_st[i].src1_rob == bus[0].dest_rob) && !(res_st[i].src1_valid))
					  begin
							res_st[i].src1_value <= bus[0].value;
							res_st[i].src1_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].src2_rob == bus[0].dest_rob) && !(res_st[i].src2_valid))
					  begin
							res_st[i].src2_value <= bus[0].value;
							res_st[i].src2_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].br_pc_in1_rob == bus[0].dest_rob) && !(res_st[i].br_pc_in1_valid))
					  begin
							res_st[i].br_pc_in1_value <= bus[0].value;
							res_st[i].br_pc_in1_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].br_pc_in2_rob == bus[0].dest_rob) && !(res_st[i].br_pc_in2_valid))
					  begin
							res_st[i].br_pc_in2_value <= bus[0].value;
							res_st[i].br_pc_in2_valid <= 1'b1;
					  end
				 end
			end

			if(bus[1].valid)
			begin
				 for(int i = 0; i < 14; i++)
				 begin
					  if((res_st[i].valid) && (res_st[i].src1_rob == bus[1].dest_rob) && !(res_st[i].src1_valid))
					  begin
							res_st[i].src1_value <= bus[1].value;
							res_st[i].src1_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].src2_rob == bus[1].dest_rob) && !(res_st[i].src2_valid))
					  begin
							res_st[i].src2_value <= bus[1].value;
							res_st[i].src2_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].br_pc_in1_rob == bus[1].dest_rob) && !(res_st[i].br_pc_in1_valid))
					  begin
							res_st[i].br_pc_in1_value <= bus[1].value;
							res_st[i].br_pc_in1_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].br_pc_in2_rob == bus[1].dest_rob) && !(res_st[i].br_pc_in2_valid))
					  begin
							res_st[i].br_pc_in2_value <= bus[1].value;
							res_st[i].br_pc_in2_valid <= 1'b1;
					  end
				 end
			end

			if(bus[2].valid)
			begin
				 for(int i = 0; i < 14; i++)
				 begin
					  if((res_st[i].valid) && (res_st[i].src1_rob == bus[2].dest_rob) && !(res_st[i].src1_valid))
					  begin
							res_st[i].src1_value <= bus[2].value;
							res_st[i].src1_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].src2_rob == bus[2].dest_rob) && !(res_st[i].src2_valid))
					  begin
							res_st[i].src2_value <= bus[2].value;
							res_st[i].src2_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].br_pc_in1_rob == bus[2].dest_rob) && !(res_st[i].br_pc_in1_valid))
					  begin
							res_st[i].br_pc_in1_value <= bus[2].value;
							res_st[i].br_pc_in1_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].br_pc_in2_rob == bus[2].dest_rob) && !(res_st[i].br_pc_in2_valid))
					  begin
							res_st[i].br_pc_in2_value <= bus[2].value;
							res_st[i].br_pc_in2_valid <= 1'b1;
					  end
				 end
			end

			if(bus[3].valid)
			begin
				 for(int i = 0; i < 14; i++)
				 begin
					  if((res_st[i].valid) && (res_st[i].src1_rob == bus[3].dest_rob) && !(res_st[i].src1_valid))
					  begin
							res_st[i].src1_value <= bus[3].value;
							res_st[i].src1_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].src2_rob == bus[3].dest_rob) && !(res_st[i].src2_valid))
					  begin
							res_st[i].src2_value <= bus[3].value;
							res_st[i].src2_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].br_pc_in1_rob == bus[3].dest_rob) && !(res_st[i].br_pc_in1_valid))
					  begin
							res_st[i].br_pc_in1_value <= bus[3].value;
							res_st[i].br_pc_in1_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].br_pc_in2_rob == bus[3].dest_rob) && !(res_st[i].br_pc_in2_valid))
					  begin
							res_st[i].br_pc_in2_value <= bus[3].value;
							res_st[i].br_pc_in2_valid <= 1'b1;
					  end
				 end
			end

			if(bus[4].valid)
			begin
				 for(int i = 0; i < 14; i++)
				 begin
					  if((res_st[i].valid) && (res_st[i].src1_rob == bus[4].dest_rob) && !(res_st[i].src1_valid))
					  begin
							res_st[i].src1_value <= bus[4].value;
							res_st[i].src1_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].src2_rob == bus[4].dest_rob) && !(res_st[i].src2_valid))
					  begin
							res_st[i].src2_value <= bus[4].value;
							res_st[i].src2_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].br_pc_in1_rob == bus[4].dest_rob) && !(res_st[i].br_pc_in1_valid))
					  begin
							res_st[i].br_pc_in1_value <= bus[4].value;
							res_st[i].br_pc_in1_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].br_pc_in2_rob == bus[4].dest_rob) && !(res_st[i].br_pc_in2_valid))
					  begin
							res_st[i].br_pc_in2_value <= bus[4].value;
							res_st[i].br_pc_in2_valid <= 1'b1;
					  end
				 end
			end

			if(LD_ST_bus.valid)
			begin
				 for(int i = 0; i < 14; i++)
				 begin
					  if((res_st[i].valid) && (res_st[i].src1_rob == LD_ST_bus.dest_rob) && !(res_st[i].src1_valid))
					  begin
							res_st[i].src1_value <= LD_ST_bus.value;
							res_st[i].src1_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].src2_rob == LD_ST_bus.dest_rob) && !(res_st[i].src2_valid))
					  begin
							res_st[i].src2_value <= LD_ST_bus.value;
							res_st[i].src2_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].br_pc_in1_rob == LD_ST_bus.dest_rob) && !(res_st[i].br_pc_in1_valid))
					  begin
							res_st[i].br_pc_in1_value <= LD_ST_bus.value;
							res_st[i].br_pc_in1_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].br_pc_in2_rob == LD_ST_bus.dest_rob) && !(res_st[i].br_pc_in2_valid))
					  begin
							res_st[i].br_pc_in2_value <= LD_ST_bus.value;
							res_st[i].br_pc_in2_valid <= 1'b1;
					  end
				 end
			end

			if(data_bus_CMP.valid)
			begin
				 for(int i = 0; i < 14; i++)
				 begin
					  if((res_st[i].valid) && (res_st[i].src1_rob == data_bus_CMP.dest_rob) && !(res_st[i].src1_valid))
					  begin
							res_st[i].src1_value <= data_bus_CMP.value;
							res_st[i].src1_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].src2_rob == data_bus_CMP.dest_rob) && !(res_st[i].src2_valid))
					  begin
							res_st[i].src2_value <= data_bus_CMP.value;
							res_st[i].src2_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].br_pc_in1_rob == data_bus_CMP.dest_rob) && !(res_st[i].br_pc_in1_valid))
					  begin
							res_st[i].br_pc_in1_value <= data_bus_CMP.value;
							res_st[i].br_pc_in1_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].br_pc_in2_rob == data_bus_CMP.dest_rob) && !(res_st[i].br_pc_in2_valid))
					  begin
							res_st[i].br_pc_in2_value <= data_bus_CMP.value;
							res_st[i].br_pc_in2_valid <= 1'b1;
					  end
				 end
			end

			if(rob_to_regfile.valid)
			begin
				 for(int i = 0; i < 14; i++)
				 begin
					  if((res_st[i].valid) && (res_st[i].src1_rob == rob_to_regfile.rob_idx) && !(res_st[i].src1_valid))
					  begin
							res_st[i].src1_value <= rob_to_regfile.value;
							res_st[i].src1_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].src2_rob == rob_to_regfile.rob_idx) && !(res_st[i].src2_valid))
					  begin
							res_st[i].src2_value <= rob_to_regfile.value;
							res_st[i].src2_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].br_pc_in1_rob == rob_to_regfile.rob_idx) && !(res_st[i].br_pc_in1_valid))
					  begin
							res_st[i].br_pc_in1_value <= rob_to_regfile.value;
							res_st[i].br_pc_in1_valid <= 1'b1;
					  end
					  if((res_st[i].valid) && (res_st[i].br_pc_in2_rob == rob_to_regfile.rob_idx) && !(res_st[i].br_pc_in2_valid))
					  begin
							res_st[i].br_pc_in2_value <= rob_to_regfile.value;
							res_st[i].br_pc_in2_valid <= 1'b1;
					  end
				 end
			end

			if(evict[0].do_evict)
				 res_st[evict[0].evict_idx].valid <= 1'b0;

			if(evict[1].do_evict)
				 res_st[evict[1].evict_idx].valid <= 1'b0;

			if(evict[2].do_evict)
				 res_st[evict[2].evict_idx].valid <= 1'b0;

			if(evict[3].do_evict)
				 res_st[evict[3].evict_idx].valid <= 1'b0;

			if(evict[4].do_evict)
				 res_st[evict[4].evict_idx].valid <= 1'b0;

			if(evict[5].do_evict)//for CMP
				 res_st[evict[5].evict_idx].valid <= 1'b0;

			if(evict[6].do_evict)//CMP_br
				 res_st[12].valid <= 1'b0;

			if(evict[7].do_evict)//LD_ST mem address
				 res_st[13].valid <= 1'b0;

	  end
 end
 
 always_comb begin 

	  for(logic [3:0] i = 4'b0000; i < 4'b1011; i = i + 2)
	  begin
			if(((res_st[i].valid) && (res_st[i].src1_valid) && (res_st[i].src2_valid)) && !((res_st[i+1].valid) && (res_st[i+1].src1_valid) && (res_st[i+1].src2_valid)))
			begin
				if(i == 4'b1010)
				begin
					RStoCMP.ld_cmp = 1'b1;
					RStoCMP.cmp_op = res_st[i].alu_ops;
					RStoCMP.cmp_src1 = res_st[i].src1_value;
					RStoCMP.cmp_src2 = res_st[i].src2_value;
					RStoCMP.rob_idx = res_st[i].dest_rob;
					evict[(i/2)].do_evict = 1'b1;
					evict[(i/2)].evict_idx = i;
				end
				else
				begin
					RStoALU[(i/2)].ld_alu = 1'b1;
					RStoALU[(i/2)].alu_op = res_st[i].alu_ops;
					RStoALU[(i/2)].alu_src1 = res_st[i].src1_value;
					RStoALU[(i/2)].alu_src2 = res_st[i].src2_value;
					RStoALU[(i/2)].rob_idx = res_st[i].dest_rob;
					evict[(i/2)].do_evict = 1'b1;
					evict[(i/2)].evict_idx = i;
				end

			end
			else if(!((res_st[i].valid) && (res_st[i].src1_valid) && (res_st[i].src2_valid)) && ((res_st[i+1].valid) && (res_st[i+1].src1_valid) && (res_st[i+1].src2_valid)))
			begin
				if(i == 4'b1010)
				begin
					RStoCMP.ld_cmp = 1'b1;
					RStoCMP.cmp_op = res_st[i+1].alu_ops;
					RStoCMP.cmp_src1 = res_st[i+1].src1_value;
					RStoCMP.cmp_src2 = res_st[i+1].src2_value;
					RStoCMP.rob_idx = res_st[i+1].dest_rob;
					evict[(i/2)].do_evict = 1'b1;
					evict[(i/2)].evict_idx = i+1;
				end
				else
				begin
					RStoALU[(i/2)].ld_alu = 1'b1;
					RStoALU[(i/2)].alu_op = res_st[i+1].alu_ops;
					RStoALU[(i/2)].alu_src1 = res_st[i+1].src1_value;
					RStoALU[(i/2)].alu_src2 = res_st[i+1].src2_value;
					RStoALU[(i/2)].rob_idx = res_st[i+1].dest_rob;
					evict[(i/2)].do_evict = 1'b1;
					evict[(i/2)].evict_idx = i + 1;
				end

			end
			else if(((res_st[i].valid) && (res_st[i].src1_valid) && (res_st[i].src2_valid)) && ((res_st[i+1].valid) && (res_st[i+1].src1_valid) && (res_st[i+1].src2_valid)))
			begin
				if(i == 4'b1010)
				begin
					RStoCMP.ld_cmp = 1'b1;
					RStoCMP.cmp_op = res_st[i].alu_ops;
					RStoCMP.cmp_src1 = res_st[i].src1_value;
					RStoCMP.cmp_src2 = res_st[i].src2_value;
					RStoCMP.rob_idx = res_st[i].dest_rob;
					evict[(i/2)].do_evict = 1'b1;
					evict[(i/2)].evict_idx = i;
				end
				else
				begin
					RStoALU[(i/2)].ld_alu = 1'b1;
					RStoALU[(i/2)].alu_op = res_st[i].alu_ops;
					RStoALU[(i/2)].alu_src1 = res_st[i].src1_value;
					RStoALU[(i/2)].alu_src2 = res_st[i].src2_value;
					RStoALU[(i/2)].rob_idx = res_st[i].dest_rob;
					evict[(i/2)].do_evict = 1'b1;
					evict[(i/2)].evict_idx = i;
				end
			end
			else
			begin
				RStoCMP.ld_cmp = 1'b0;
				RStoCMP.cmp_op = '0;
				RStoCMP.cmp_src1 = '0;
				RStoCMP.cmp_src2 = '0;
				RStoCMP.rob_idx = '0;
				RStoALU[(i/2)].ld_alu = 1'b0;
				RStoALU[(i/2)].alu_op = '0;
				RStoALU[(i/2)].alu_src1 = '0;
				RStoALU[(i/2)].alu_src2 = '0;
				RStoALU[(i/2)].rob_idx = '0;
				evict[(i/2)].do_evict = 1'b0;
				evict[(i/2)].evict_idx = '0;
			end
	  end
	if((res_st[12].valid) && (res_st[12].src1_valid) && (res_st[12].src2_valid) && (res_st[12].br_pc_in1_valid) && (res_st[12].br_pc_in2_valid))
		begin
		RStoCMP_br.ld_cmp = 1'b1;
		RStoCMP_br.cmp_op = res_st[12].alu_ops;
		RStoCMP_br.cmp_src1 = res_st[12].src1_value;
		RStoCMP_br.cmp_src2 = res_st[12].src2_value;
		//RStoCMP_br.br_pc_out = res_st[12].br_pc_out;
		RStoCMP_br.pc = res_st[12].pc;
		RStoCMP_br.is_jump = res_st[12].is_jump;
		RStoCMP_br.is_jump_r = res_st[12].is_jump_r;
		RStoCMP_br.rob_idx = res_st[12].dest_rob;
		RStoCMP_br.br_pc_in1_value = res_st[12].br_pc_in1_value;
		RStoCMP_br.br_pc_in2_value = res_st[12].br_pc_in2_value;
		evict[6].do_evict = 1'b1;
		//evict[6].evict_idx = i;
	end
	else
		begin
		RStoCMP_br.ld_cmp = '0;
		RStoCMP_br.cmp_op = '0;
		RStoCMP_br.cmp_src1 = '0;
		RStoCMP_br.cmp_src2 = '0;
		//RStoCMP_br.br_pc_out = '0;
		RStoCMP_br.pc = '0;
		RStoCMP_br.rob_idx = '0;
		evict[6].do_evict = '0;
	end

	if((res_st[13].valid) && (res_st[13].src1_valid) && (res_st[13].src2_valid))
		begin
		RStoALU_ld_st.ld_alu = 1'b1;
		RStoALU_ld_st.alu_op = res_st[13].alu_ops;
		RStoALU_ld_st.alu_src1 = res_st[13].src1_value;
		RStoALU_ld_st.alu_src2 = res_st[13].src2_value;
		RStoALU_ld_st.rob_idx = res_st[13].dest_rob;
		evict[7].do_evict = 1'b1;
		//evict[6].evict_idx = i;
	end
	else
		begin
		RStoALU_ld_st.ld_alu = '0;
		RStoALU_ld_st.alu_op = '0;
		RStoALU_ld_st.alu_src1 = '0;
		RStoALU_ld_st.alu_src2 = '0;
		RStoALU_ld_st.rob_idx = '0;
		evict[7].do_evict = '0;
	end
 end

//  always_comb
//  begin
	//  if((res_st[12].valid) && (res_st[12].src1_valid) && (res_st[12].src2_valid))
	//  begin
	// 	RStoCMP_br.ld_cmp = 1'b1;
	// 	RStoCMP_br.cmp_op = res_st[12].alu_ops;
	// 	RStoCMP_br.cmp_src1 = res_st[12].src1_value;
	// 	RStoCMP_br.cmp_src2 = res_st[12].src2_value;
	// 	RStoCMP_br.br_pc_out = res_st[12].br_pc_out;
	// 	evict[6].do_evict = 1'b1;
	// 	//evict[6].evict_idx = i;
	//  end
	//  else
	//  begin
	// 	RStoCMP_br.ld_cmp = '0;
	// 	RStoCMP_br.cmp_op = '0;
	// 	RStoCMP_br.cmp_src1 = '0;
	// 	RStoCMP_br.cmp_src2 = '0;
	// 	RStoCMP_br.br_pc_out = '0;
	// 	evict[6].do_evict = '0;
	//  end
//  end


//  always_comb
//  begin
// 	 if((res_st[13].valid) && (res_st[13].src1_valid) && (res_st[13].src2_valid))
// 	 begin
// 		RStoALU_ld_st.ld_alu = 1'b1;
// 		RStoALU_ld_st.alu_op = res_st[13].alu_ops;
// 		RStoALU_ld_st.alu_src1 = res_st[13].src1_value;
// 		RStoALU_ld_st.alu_src2 = res_st[13].src2_value;
// 		RStoALU_ld_st.rob_idx = res_st[13].dest_rob;
// 		evict[7].do_evict = 1'b1;
// 		//evict[6].evict_idx = i;
// 	 end
// 	 else
// 	 begin
// 		RStoALU_ld_st.ld_alu = '0;
// 		RStoALU_ld_st.alu_op = '0;
// 		RStoALU_ld_st.alu_src1 = '0;
// 		RStoALU_ld_st.alu_src2 = '0;
// 		RStoALU_ld_st.rob_idx = '0;
// 		evict[7].do_evict = '0;
// 	 end
//  end


endmodule : RS