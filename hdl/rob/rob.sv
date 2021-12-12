//the rob has 4 data entries, The DR, Done bit, Valid bit and the value that it stores. 
import rob_entry_structs::*;    //importing the structs
import rv_structs::*;
import Ld_St_structs::*;
module rob #(
    parameter cir_q_offset = 5,                 // By default, size of an entry = 32 bits 
    parameter cir_q_index = 5                   // By default, number of indices = 32 bits 
)(
    input clk,
    input rst,
    /*inputs from ALU*/
    input rv_structs::data_bus bus[5],   //the input from the bus of the ALU

    input rv_structs::data_bus_CMP bus_cmp, //input from the cmp_bus

    input Ld_St_structs::LD_ST_bus bus_ld,

    //need to add inputs from the Instr. Scheduler. Will need the following signals. DR REGISTER, ISSUE SIGNAL
    // input [4:0] DR_entry_issue,
    // input issue,
    //need to add output to the Instr. Sche. cir_q_full and cir_q_empty
    output logic cir_q_full, cir_q_empty,

    //need to add inputs from the COMMIT CONTROLER. Will need the following signals. COMMIT SIGNAL, commit_check
    input sched_structs::IQtoROB IQtoROB,
    //need to add inputs from the COMMIT CONTROLER. Will need the following signals. COMMIT SIGNAL, commit_check
    input logic commit,
    output logic commit_ready,
    // output [4:0] possible_commits,
    

    //need to add output to the regfile. Will need the following signals. DR register(idx of regfile) value and rob_entry idx
    output rob_entry_structs::rob_to_regfile rob_regfile_bus,    //can create an array to increase the bus size
    output logic [cir_q_index-1:0] issue_mod_out, commit_mod_out,
    input sched_structs::FetchToROB FetchToROB,
    output sched_structs::ROBToALL ROBToALL,
    output logic ROBtoIQ_br_jump_present
);

localparam entry_size = 2**cir_q_offset;
localparam num_entries = 2**cir_q_index;

localparam DR_cir_q_offset = 3;
localparam DR_cir_q_index = 5;

localparam done_cir_q_offset = 0;
localparam done_cir_q_index = 5;


logic [cir_q_index-1:0] issue_temp_out, commit_temp_out;
logic [cir_q_index-1:0] issue_temp_out1, commit_temp_out1;
logic [cir_q_index-1:0] issue_temp_out2, commit_temp_out2;
logic [cir_q_index-1:0] issue_temp_out3, commit_temp_out3;
logic [cir_q_index-1:0] issue_temp_out4, commit_temp_out4;
logic [cir_q_index-1:0] issue_temp_out5, commit_temp_out5;
logic [cir_q_index-1:0] issue_temp_out6, commit_temp_out6;


rob_entry_structs::rob_dr_entry dr;
rob_entry_structs::rob_done_entry done;
rob_entry_structs::rob_value_entry value;
rob_entry_structs::rob_st_entry st;
rob_entry_structs::rob_br_entry br;
rob_entry_structs::rob_br_mispredict_entry br_mispredict;
rob_entry_structs::rob_jump_entry jump;
rob_entry_structs::rob_br_mispredict_pc rob_br_mispredict_pc;
logic reset_local, reset_broadcast;

logic one_cycle_flush;

assign reset_broadcast = rst | reset_local;


always_ff @(posedge clk) begin
    if(br.dataout & br_mispredict.dataout)
        one_cycle_flush <= '0;
    else if(jump.dataout & br_mispredict.dataout)
        one_cycle_flush <= '0;
    else
        one_cycle_flush <= '1;
end



always_comb begin
    cir_q_full = dr.cir_q_full;
    cir_q_empty = dr.cir_q_empty;
    commit_ready= done.commit_ready;
    ROBtoIQ_br_jump_present = (jump.is_jump_in_rob | br.is_br_in_rob) ? '1 : '0;

    ROBToALL.flush_all ='0; 
    ROBToALL.target_pc ='0;

    rob_regfile_bus.value = '0;
    rob_regfile_bus.regfile_idx ='0;
    rob_regfile_bus.rob_idx = '0;
    rob_regfile_bus.valid = 1'b0;
    reset_local ='0;

    if(br.dataout & one_cycle_flush)  begin
        if(br_mispredict.dataout)   begin
            ROBToALL.flush_all ='1; //send flush signal to all units
            ROBToALL.target_pc =rob_br_mispredict_pc.dataout;
            reset_local = 1'b1;
        end
        else begin
            ROBToALL.flush_all ='0; 
            ROBToALL.target_pc =rob_br_mispredict_pc.dataout;
            reset_local = 1'b0;
        end
    end
    else if(jump.dataout & one_cycle_flush)  begin
        if(br_mispredict.dataout)   begin
            ROBToALL.flush_all ='1; //send flush signal to all units
            ROBToALL.target_pc =rob_br_mispredict_pc.dataout;
            reset_local = 1'b1;
            rob_regfile_bus.value = value.dataout;
            rob_regfile_bus.regfile_idx =dr.dataout;
            rob_regfile_bus.rob_idx = dr.commit_ptr_rob_idx;
            rob_regfile_bus.valid = 1'b1;
        end
        else begin
            ROBToALL.flush_all ='0; 
            ROBToALL.target_pc =rob_br_mispredict_pc.dataout;
            reset_local = 1'b0;
            rob_regfile_bus.value = value.dataout;
            rob_regfile_bus.regfile_idx =dr.dataout;
            rob_regfile_bus.rob_idx = dr.commit_ptr_rob_idx;
            rob_regfile_bus.valid = 1'b1;
        end
    end
    else    begin
        rob_regfile_bus.value = ((done.dataout) & (~st.dataout)) ? value.dataout : 'x;
        rob_regfile_bus.regfile_idx = ((done.dataout) & (~st.dataout)) ? dr.dataout :'x;
        rob_regfile_bus.rob_idx = ((done.dataout) & (~st.dataout)) ? dr.commit_ptr_rob_idx :'x;
        rob_regfile_bus.valid = ((done.dataout) & (~st.dataout)) ? 1'b1 : 1'b0;
    end
    // end

end
function void set_defaults();
    dr.issue ='0;
    dr.commit ='0;
    dr.update_0 ='0;
    dr.update_1 ='0;
    dr.update_2 ='0;
    dr.update_3 ='0;
    dr.update_4 ='0;
    done.issue ='0;
    done.commit ='0;
    done.update_0 ='0;
    done.update_1 ='0;
    done.update_2 ='0;
    done.update_3 ='0;
    done.update_4 ='0;
    value.issue ='0;
    value.commit ='0;
    value.update_0 ='0;
    value.update_1 ='0;
    value.update_2 ='0;
    value.update_3 ='0;
    value.update_4 ='0;
    st.issue ='0;
    st.commit ='0;
    st.update_0 ='0;
    st.update_1 ='0;
    st.update_2 ='0;
    st.update_3 ='0;
    st.update_4 ='0;
    br.issue ='0;
    br.commit ='0;
    br.update_0 ='0;
    br.update_1 ='0;
    br.update_2 ='0;
    br.update_3 ='0;
    br.update_4 ='0;
    br_mispredict.issue ='0;
    br_mispredict.commit ='0;
    br_mispredict.update_0 ='0;
    br_mispredict.update_1 ='0;
    br_mispredict.update_2 ='0;
    br_mispredict.update_3 ='0;
    br_mispredict.update_4 ='0;
    jump.issue ='0;
    jump.commit ='0;
    jump.update_0 ='0;
    jump.update_1 ='0;
    jump.update_2 ='0;
    jump.update_3 ='0;
    jump.update_4 ='0;
    rob_br_mispredict_pc.issue ='0;
    rob_br_mispredict_pc.commit ='0;
    rob_br_mispredict_pc.update_0 ='0;
    rob_br_mispredict_pc.update_1 ='0;
    rob_br_mispredict_pc.update_2 ='0;
    rob_br_mispredict_pc.update_3 ='0;
    rob_br_mispredict_pc.update_4 ='0;

    dr.update_cmp ='0;
    dr.update_index_cmp = '0;
    dr.datain_update_cmp ='0;
    dr.update_br ='0;
    dr.update_index_br = '0;
    dr.datain_update_br ='0;

    done.update_cmp ='0;
    done.update_index_cmp = '0;
    done.datain_update_cmp ='0;
    done.update_br ='0;
    done.update_index_br = '0;
    done.datain_update_br ='0;

    value.update_cmp ='0;
    value.update_index_cmp = '0;
    value.datain_update_cmp ='0;
    value.update_br ='0;
    value.update_index_br = '0;
    value.datain_update_br ='0;

    st.update_cmp ='0;
    st.update_index_cmp = '0;
    st.datain_update_cmp ='0;
    st.update_br ='0;
    st.update_index_br = '0;
    st.datain_update_br ='0;

    br.update_cmp ='0;
    br.update_index_cmp = '0;
    br.datain_update_cmp ='0;
    br.update_br ='0;
    br.update_index_br = '0;
    br.datain_update_br ='0;

    br_mispredict.update_cmp ='0;
    br_mispredict.update_index_cmp = '0;
    br_mispredict.datain_update_cmp ='0;
    br_mispredict.update_br ='0;
    br_mispredict.update_index_br = '0;
    br_mispredict.datain_update_br ='0;

    jump.update_cmp ='0;
    jump.update_index_cmp = '0;
    jump.datain_update_cmp ='0;
    jump.update_br ='0;
    jump.update_index_br = '0;
    jump.datain_update_br ='0;

    rob_br_mispredict_pc.update_cmp ='0;
    rob_br_mispredict_pc.update_index_cmp = '0;
    rob_br_mispredict_pc.datain_update_cmp ='0;
    rob_br_mispredict_pc.update_br ='0;
    rob_br_mispredict_pc.update_index_br = '0;
    rob_br_mispredict_pc.datain_update_br ='0;

    dr.update_ld ='0;
    dr.update_index_ld = '0;
    dr.datain_update_ld ='0;

    done.update_ld ='0;
    done.update_index_ld = '0;
    done.datain_update_ld ='0;

    value.update_ld ='0;
    value.update_index_ld = '0;
    value.datain_update_ld ='0;

    st.update_ld ='0;
    st.update_index_ld = '0;
    st.datain_update_ld ='0;

    br.update_ld ='0;
    br.update_index_ld = '0;
    br.datain_update_ld ='0;

    br_mispredict.update_ld ='0;
    br_mispredict.update_index_ld = '0;
    br_mispredict.datain_update_ld ='0;

    jump.update_ld ='0;
    jump.update_index_ld = '0;
    jump.datain_update_ld ='0;

    rob_br_mispredict_pc.update_ld ='0;
    rob_br_mispredict_pc.update_index_ld = '0;
    rob_br_mispredict_pc.datain_update_ld ='0;

endfunction
//driving inputs
always_comb    begin
    set_defaults();
    if(reset_broadcast) begin
        set_defaults();
	end
    else    begin
        if(IQtoROB.rob_issue)  begin
            dr.issue =1'b1;
            done.issue =1'b1;
            value.issue =1'b1;
            st.issue = 1'b1;
            br.issue = 1'b1;
            br_mispredict.issue = 1'b1;
            jump.issue = 1'b1;
            rob_br_mispredict_pc.issue =1'b1;

            st.datain_issue = 1'b0;
            dr.datain_issue = {3'd0, IQtoROB.dr};  //only written like this because important to note top 3 bits are masked.
            if(IQtoROB.load_imm)    begin
                if(IQtoROB.is_st | IQtoROB.is_jump)
                    done.datain_issue = 1'b0;
                else
                    done.datain_issue = 1'b1;
                if(IQtoROB.is_jump) begin
                    jump.datain_issue = 1'b1;
                    rob_br_mispredict_pc.datain_issue = IQtoROB.load_imm_val;
                end
                else begin
                    jump.datain_issue = 1'b0;
                    rob_br_mispredict_pc.datain_issue = '0;
                end
                value.datain_issue = IQtoROB.load_imm_val;
                br.datain_issue = 1'b0;
                br_mispredict.datain_issue = 1'b0;
            end
            else if(IQtoROB.is_br) begin
                rob_br_mispredict_pc.datain_issue = '0;
                done.datain_issue = 1'b0;
                value.datain_issue = 'x;
                br.datain_issue = 1'b1;
                br_mispredict.datain_issue = 1'b0;
                jump.datain_issue = 1'b0;
            end
            else begin
                rob_br_mispredict_pc.datain_issue = '0;
                done.datain_issue = 1'b0;
                value.datain_issue = 'x;
                br.datain_issue = 1'b0;
                jump.datain_issue = 1'b0;
                br_mispredict.datain_issue = 1'b0;
            end
            
        end

        if(bus[0].valid)    begin   //only need to update the done bit and the value on broadcast. the valid bit and dr_entry stay same.
            done.update_0 =1'b1;
            done.update_index_0 = bus[0].dest_rob;
            done.datain_update_0 =1'b1;

            value.update_0 =1'b1;
            value.update_index_0 = bus[0].dest_rob;
            value.datain_update_0 =bus[0].value;
		end
        if(bus[1].valid)    begin   //only need to update the done bit and the value on broadcast. the valid bit and dr_entry stay same.
            done.update_1 =1'b1;
            done.update_index_1 = bus[1].dest_rob;
            done.datain_update_1 =1'b1;

            value.update_1 =1'b1;
            value.update_index_1 = bus[1].dest_rob;
            value.datain_update_1 =bus[1].value;
		end
        if(bus[2].valid)    begin   //only need to update the done bit and the value on broadcast. the valid bit and dr_entry stay same.
            done.update_2 =1'b1;
            done.update_index_2 = bus[2].dest_rob;
            done.datain_update_2 =1'b1;

            value.update_2 =1'b1;
            value.update_index_2 = bus[2].dest_rob;
            value.datain_update_2 =bus[2].value;
		end
        if(bus[3].valid)    begin   //only need to update the done bit and the value on broadcast. the valid bit and dr_entry stay same.
            done.update_3 =1'b1;
            done.update_index_3 = bus[3].dest_rob;
            done.datain_update_3 =1'b1;

            value.update_3 =1'b1;
            value.update_index_3 = bus[3].dest_rob;
            value.datain_update_3 =bus[3].value;
		end
        if(bus[4].valid)    begin   //only need to update the done bit and the value on broadcast. the valid bit and dr_entry stay same.
            done.update_4 =1'b1;
            done.update_index_4 = bus[4].dest_rob;
            done.datain_update_4 =1'b1;

            value.update_4 =1'b1;
            value.update_index_4 = bus[4].dest_rob;
            value.datain_update_4 =bus[4].value;
		end
        if(bus_cmp.valid)   begin
            done.update_cmp =1'b1;
            done.update_index_cmp = bus_cmp.dest_rob;
            done.datain_update_cmp =1'b1;

            value.update_cmp =1'b1;
            value.update_index_cmp = bus_cmp.dest_rob;
            value.datain_update_cmp =bus_cmp.value;
        end
        if(bus_ld.valid)    begin
            if(bus_ld.st)   begin
                done.update_ld =1'b1;
                done.update_index_ld = bus_ld.dest_rob;
                done.datain_update_ld =1'b1;

                st.update_ld =1'b1;
                st.update_index_ld = bus_ld.dest_rob;
                st.datain_update_ld =1'b1;
            end
            else begin
                done.update_ld =1'b1;
                done.update_index_ld = bus_ld.dest_rob;
                done.datain_update_ld =1'b1;

                value.update_ld =1'b1;
                value.update_index_ld = bus_ld.dest_rob;
                value.datain_update_ld =bus_ld.value;
            end
        end

        if(FetchToROB.bus_valid)    begin
            if(FetchToROB.is_mispredict)   begin
                br_mispredict.update_br =1'b1;
                br_mispredict.update_index_br = FetchToROB.br_rob_index;
                br_mispredict.datain_update_br =1'b1;

                done.update_br =1'b1;
                done.update_index_br = FetchToROB.br_rob_index;
                done.datain_update_br =1'b1;

                // if(FetchToROB.load_val) begin
                    // value.update_br =1'b1;
                    // value.update_index_br = FetchToROB.br_rob_index;
                    // value.datain_update_br =FetchToROB.target_pc;

                rob_br_mispredict_pc.update_br = '1;
                rob_br_mispredict_pc.update_index_br = FetchToROB.br_rob_index;
                rob_br_mispredict_pc.datain_update_br =FetchToROB.target_pc;
                // end
                // else    begin
                //     // value.update_br =1'b0;
                    // value.update_index_br = '0;
                    // value.datain_update_br ='0;

                    // rob_br_mispredict_pc.update_br = '1;
                    // rob_br_mispredict_pc.update_index_br = FetchToROB.br_rob_index;
                    // rob_br_mispredict_pc.datain_update_br =FetchToROB.target_pc;
                // end
            end
            else begin
                br_mispredict.update_br =1'b1;
                br_mispredict.update_index_br = FetchToROB.br_rob_index;
                br_mispredict.datain_update_br =FetchToROB.target_pc;

                done.update_br =1'b1;
                done.update_index_br = FetchToROB.br_rob_index;
                done.datain_update_br =1'b1;

                // if(FetchToROB.load_val) begin
                //     value.update_br =1'b1;
                //     value.update_index_br = FetchToROB.br_rob_index;
                //     value.datain_update_br =FetchToROB.target_pc;
                // end
                // else
                //     value.update_br = '0;
            end
        end

        if(commit)  begin
            dr.commit =1'b1;
            done.commit =1'b1;
            value.commit =1'b1;
            st.commit = 1'b1;
            br.commit = 1'b1;
            br_mispredict.commit = 1'b1;
            jump.commit = 1'b1;
            rob_br_mispredict_pc.commit =1'b1;
        end
    end
end

cir_q_rob #(
    .cir_q_offset(DR_cir_q_offset),
    .cir_q_index(DR_cir_q_index)
)
DR_entry (
    .clk(clk),
    .rst(reset_broadcast),
    .update_index_0(dr.update_index_0),
    .update_index_1(dr.update_index_1),
    .update_index_2(dr.update_index_2),
    .update_index_3(dr.update_index_3),
    .update_index_4(dr.update_index_4),
    .update_index_cmp(dr.update_index_cmp),
    .update_index_ld(dr.update_index_ld),
    .update_index_br(dr.update_index_br),

    .issue(dr.issue),
    .commit(dr.commit),
    .update_0(dr.update_0),
    .update_1(dr.update_1),
    .update_2(dr.update_2),
    .update_3(dr.update_3),
    .update_4(dr.update_4),
    .update_cmp(dr.update_cmp),
    .update_ld(dr.update_ld),
    .update_br(dr.update_br),

    .datain_issue(dr.datain_issue),
    .datain_update_0(dr.datain_update_0),
    .datain_update_1(dr.datain_update_1),
    .datain_update_2(dr.datain_update_2),
    .datain_update_3(dr.datain_update_3),
    .datain_update_4(dr.datain_update_4),
    .datain_update_cmp(dr.datain_update_cmp),
    .datain_update_ld(dr.datain_update_ld),
    .datain_update_br(dr.datain_update_br),

    .commit_ready(dr.commit_ready),
    .is_done_bit(1'b0),
    .is_jump_bit(1'b0),
    .is_br_bit(1'b0),
    .is_br_in_rob(dr.is_br_in_rob),
    .is_jump_in_rob(dr.is_jump_in_rob),
    
    .dataout(dr.dataout),
    .cir_q_empty(dr.cir_q_empty),
    .cir_q_full(dr.cir_q_full),
    .commit_ptr_rob_idx(dr.commit_ptr_rob_idx),
    .issue_mod_out(issue_mod_out),
    .commit_mod_out(commit_mod_out)
);

cir_q_rob #(
    .cir_q_offset(done_cir_q_offset),
    .cir_q_index(done_cir_q_index)
)
done_entry (
    .clk(clk),
    .rst(reset_broadcast),
    .update_index_0(done.update_index_0),
    .update_index_1(done.update_index_1),
    .update_index_2(done.update_index_2),
    .update_index_3(done.update_index_3),
    .update_index_4(done.update_index_4),
    .update_index_cmp(done.update_index_cmp),
    .update_index_ld(done.update_index_ld),
    .update_index_br(done.update_index_br),

    .issue(done.issue),
    .commit(done.commit),
    .update_0(done.update_0),
    .update_1(done.update_1),
    .update_2(done.update_2),
    .update_3(done.update_3),
    .update_4(done.update_4),
    .update_cmp(done.update_cmp),
    .update_ld(done.update_ld),
    .update_br(done.update_br),

    .datain_issue(done.datain_issue),
    .datain_update_0(done.datain_update_0),
    .datain_update_1(done.datain_update_1),
    .datain_update_2(done.datain_update_2),
    .datain_update_3(done.datain_update_3),
    .datain_update_4(done.datain_update_4),
    .datain_update_cmp(done.datain_update_cmp),
    .datain_update_ld(done.datain_update_ld),
    .datain_update_br(done.datain_update_br),

    .commit_ready(done.commit_ready),
    .is_done_bit(1'b1),

    .is_jump_bit(1'b0),
    .is_br_bit(1'b0),
    .is_br_in_rob(done.is_br_in_rob),
    .is_jump_in_rob(done.is_jump_in_rob),

    .dataout(done.dataout),
    .cir_q_empty(done.cir_q_empty),
    .cir_q_full(done.cir_q_full),
    .commit_ptr_rob_idx(done.commit_ptr_rob_idx),
    .issue_mod_out(issue_temp_out),
    .commit_mod_out(commit_temp_out)
);

cir_q_rob #(
    .cir_q_offset(cir_q_offset),
    .cir_q_index(cir_q_index)
)
value_entry (
    .clk(clk),
    .rst(reset_broadcast),
    .update_index_0(value.update_index_0),
    .update_index_1(value.update_index_1),
    .update_index_2(value.update_index_2),
    .update_index_3(value.update_index_3),
    .update_index_4(value.update_index_4),
    .update_index_cmp(value.update_index_cmp),
    .update_index_ld(value.update_index_ld),
    .update_index_br(value.update_index_br),

    .issue(value.issue),
    .commit(value.commit),
    .update_0(value.update_0),
    .update_1(value.update_1),
    .update_2(value.update_2),
    .update_3(value.update_3),
    .update_4(value.update_4),
    .update_cmp(value.update_cmp),
    .update_ld(value.update_ld),
    .update_br(value.update_br),

    .datain_issue(value.datain_issue),
    .datain_update_0(value.datain_update_0),
    .datain_update_1(value.datain_update_1),
    .datain_update_2(value.datain_update_2),
    .datain_update_3(value.datain_update_3),
    .datain_update_4(value.datain_update_4),
    .datain_update_cmp(value.datain_update_cmp),
    .datain_update_ld(value.datain_update_ld),
    .datain_update_br(value.datain_update_br),

    .commit_ready(value.commit_ready),
    .is_done_bit(1'b0),
    .is_jump_bit(1'b0),
    .is_br_bit(1'b0),
    .is_br_in_rob(value.is_br_in_rob),
    .is_jump_in_rob(value.is_jump_in_rob),
    
    .dataout(value.dataout),
    .cir_q_empty(value.cir_q_empty),
    .cir_q_full(value.cir_q_full),
    .commit_ptr_rob_idx(value.commit_ptr_rob_idx),
    .issue_mod_out(issue_temp_out1),
    .commit_mod_out(commit_temp_out1)
);

cir_q_rob #(
    .cir_q_offset(done_cir_q_offset),
    .cir_q_index(done_cir_q_index)
)
st_entry (
    .clk(clk),
    .rst(reset_broadcast),
    .update_index_0(st.update_index_0),
    .update_index_1(st.update_index_1),
    .update_index_2(st.update_index_2),
    .update_index_3(st.update_index_3),
    .update_index_4(st.update_index_4),
    .update_index_cmp(st.update_index_cmp),
    .update_index_ld(st.update_index_ld),
    .update_index_br(st.update_index_br),

    .issue(st.issue),
    .commit(st.commit),
    .update_0(st.update_0),
    .update_1(st.update_1),
    .update_2(st.update_2),
    .update_3(st.update_3),
    .update_4(st.update_4),
    .update_cmp(st.update_cmp),
    .update_ld(st.update_ld),
    .update_br(st.update_br),

    .datain_issue(st.datain_issue),
    .datain_update_0(st.datain_update_0),
    .datain_update_1(st.datain_update_1),
    .datain_update_2(st.datain_update_2),
    .datain_update_3(st.datain_update_3),
    .datain_update_4(st.datain_update_4),
    .datain_update_cmp(st.datain_update_cmp),
    .datain_update_ld(st.datain_update_ld),
    .datain_update_br(st.datain_update_br),

    .commit_ready(st.commit_ready),
    .is_done_bit(1'b0),
    .is_jump_bit(1'b0),
    .is_br_bit(1'b0),
    .is_br_in_rob(st.is_br_in_rob),
    .is_jump_in_rob(st.is_jump_in_rob),
    
    .dataout(st.dataout),
    .cir_q_empty(st.cir_q_empty),
    .cir_q_full(st.cir_q_full),
    .commit_ptr_rob_idx(st.commit_ptr_rob_idx),
    .issue_mod_out(issue_temp_out2),
    .commit_mod_out(commit_temp_out2)
);

cir_q_rob #(
    .cir_q_offset(done_cir_q_offset),
    .cir_q_index(done_cir_q_index)
)
br_entry (
    .clk(clk),
    .rst(reset_broadcast),
    .update_index_0(br.update_index_0),
    .update_index_1(br.update_index_1),
    .update_index_2(br.update_index_2),
    .update_index_3(br.update_index_3),
    .update_index_4(br.update_index_4),
    .update_index_cmp(br.update_index_cmp),
    .update_index_ld(br.update_index_ld),
    .update_index_br(br.update_index_br),

    .issue(br.issue),
    .commit(br.commit),
    .update_0(br.update_0),
    .update_1(br.update_1),
    .update_2(br.update_2),
    .update_3(br.update_3),
    .update_4(br.update_4),
    .update_cmp(br.update_cmp),
    .update_ld(br.update_ld),
    .update_br(br.update_br),

    .datain_issue(br.datain_issue),
    .datain_update_0(br.datain_update_0),
    .datain_update_1(br.datain_update_1),
    .datain_update_2(br.datain_update_2),
    .datain_update_3(br.datain_update_3),
    .datain_update_4(br.datain_update_4),
    .datain_update_cmp(br.datain_update_cmp),
    .datain_update_ld(br.datain_update_ld),
    .datain_update_br(br.datain_update_br),

    .commit_ready(br.commit_ready),
    .is_done_bit(1'b0),
    .is_jump_bit(1'b0),
    .is_br_bit(1'b1),
    .is_br_in_rob(br.is_br_in_rob),
    .is_jump_in_rob(br.is_jump_in_rob),
    
    .dataout(br.dataout),
    .cir_q_empty(br.cir_q_empty),
    .cir_q_full(br.cir_q_full),
    .commit_ptr_rob_idx(br.commit_ptr_rob_idx),
    .issue_mod_out(issue_temp_out3),
    .commit_mod_out(commit_temp_out3)
);

cir_q_rob #(
    .cir_q_offset(done_cir_q_offset),
    .cir_q_index(done_cir_q_index)
)
br_mispredict_entry (
    .clk(clk),
    .rst(reset_broadcast),
    .update_index_0(br_mispredict.update_index_0),
    .update_index_1(br_mispredict.update_index_1),
    .update_index_2(br_mispredict.update_index_2),
    .update_index_3(br_mispredict.update_index_3),
    .update_index_4(br_mispredict.update_index_4),
    .update_index_cmp(br_mispredict.update_index_cmp),
    .update_index_ld(br_mispredict.update_index_ld),
    .update_index_br(br_mispredict.update_index_br),

    .issue(br_mispredict.issue),
    .commit(br_mispredict.commit),
    .update_0(br_mispredict.update_0),
    .update_1(br_mispredict.update_1),
    .update_2(br_mispredict.update_2),
    .update_3(br_mispredict.update_3),
    .update_4(br_mispredict.update_4),
    .update_cmp(br_mispredict.update_cmp),
    .update_ld(br_mispredict.update_ld),
    .update_br(br_mispredict.update_br),

    .datain_issue(br_mispredict.datain_issue),
    .datain_update_0(br_mispredict.datain_update_0),
    .datain_update_1(br_mispredict.datain_update_1),
    .datain_update_2(br_mispredict.datain_update_2),
    .datain_update_3(br_mispredict.datain_update_3),
    .datain_update_4(br_mispredict.datain_update_4),
    .datain_update_cmp(br_mispredict.datain_update_cmp),
    .datain_update_ld(br_mispredict.datain_update_ld),
    .datain_update_br(br_mispredict.datain_update_br),

    .commit_ready(br_mispredict.commit_ready),
    .is_done_bit(1'b0),
    .is_br_in_rob(br_mispredict.is_br_in_rob),
    .is_jump_in_rob(br_mispredict.is_jump_in_rob),
    
    .dataout(br_mispredict.dataout),
    .cir_q_empty(br_mispredict.cir_q_empty),
    .cir_q_full(br_mispredict.cir_q_full),
    .commit_ptr_rob_idx(br_mispredict.commit_ptr_rob_idx),
    .issue_mod_out(issue_temp_out4),
    .commit_mod_out(commit_temp_out4)
);

cir_q_rob #(
    .cir_q_offset(done_cir_q_offset),
    .cir_q_index(done_cir_q_index)
)
jump_entry (
    .clk(clk),
    .rst(reset_broadcast),
    .update_index_0(jump.update_index_0),
    .update_index_1(jump.update_index_1),
    .update_index_2(jump.update_index_2),
    .update_index_3(jump.update_index_3),
    .update_index_4(jump.update_index_4),
    .update_index_cmp(jump.update_index_cmp),
    .update_index_ld(jump.update_index_ld),
    .update_index_br(jump.update_index_br),

    .issue(jump.issue),
    .commit(jump.commit),
    .update_0(jump.update_0),
    .update_1(jump.update_1),
    .update_2(jump.update_2),
    .update_3(jump.update_3),
    .update_4(jump.update_4),
    .update_cmp(jump.update_cmp),
    .update_ld(jump.update_ld),
    .update_br(jump.update_br),

    .datain_issue(jump.datain_issue),
    .datain_update_0(jump.datain_update_0),
    .datain_update_1(jump.datain_update_1),
    .datain_update_2(jump.datain_update_2),
    .datain_update_3(jump.datain_update_3),
    .datain_update_4(jump.datain_update_4),
    .datain_update_cmp(jump.datain_update_cmp),
    .datain_update_ld(jump.datain_update_ld),
    .datain_update_br(jump.datain_update_br),

    .commit_ready(jump.commit_ready),
    .is_done_bit(1'b0),
    .is_jump_bit(1'b1),
    .is_br_bit(1'b0),
    .is_br_in_rob(jump.is_br_in_rob),
    .is_jump_in_rob(jump.is_jump_in_rob),
    
    .dataout(jump.dataout),
    .cir_q_empty(jump.cir_q_empty),
    .cir_q_full(jump.cir_q_full),
    .commit_ptr_rob_idx(jump.commit_ptr_rob_idx),
    .issue_mod_out(issue_temp_out5),
    .commit_mod_out(commit_temp_out5)
);

cir_q_rob #(
    .cir_q_offset(cir_q_offset),
    .cir_q_index(cir_q_index)
)
mispredict_pc_entry (
    .clk(clk),
    .rst(reset_broadcast),
    .update_index_0(rob_br_mispredict_pc.update_index_0),
    .update_index_1(rob_br_mispredict_pc.update_index_1),
    .update_index_2(rob_br_mispredict_pc.update_index_2),
    .update_index_3(rob_br_mispredict_pc.update_index_3),
    .update_index_4(rob_br_mispredict_pc.update_index_4),
    .update_index_cmp(rob_br_mispredict_pc.update_index_cmp),
    .update_index_ld(rob_br_mispredict_pc.update_index_ld),
    .update_index_br(rob_br_mispredict_pc.update_index_br),

    .issue(rob_br_mispredict_pc.issue),
    .commit(rob_br_mispredict_pc.commit),
    .update_0(rob_br_mispredict_pc.update_0),
    .update_1(rob_br_mispredict_pc.update_1),
    .update_2(rob_br_mispredict_pc.update_2),
    .update_3(rob_br_mispredict_pc.update_3),
    .update_4(rob_br_mispredict_pc.update_4),
    .update_cmp(rob_br_mispredict_pc.update_cmp),
    .update_ld(rob_br_mispredict_pc.update_ld),
    .update_br(rob_br_mispredict_pc.update_br),

    .datain_issue(rob_br_mispredict_pc.datain_issue),
    .datain_update_0(rob_br_mispredict_pc.datain_update_0),
    .datain_update_1(rob_br_mispredict_pc.datain_update_1),
    .datain_update_2(rob_br_mispredict_pc.datain_update_2),
    .datain_update_3(rob_br_mispredict_pc.datain_update_3),
    .datain_update_4(rob_br_mispredict_pc.datain_update_4),
    .datain_update_cmp(rob_br_mispredict_pc.datain_update_cmp),
    .datain_update_ld(rob_br_mispredict_pc.datain_update_ld),
    .datain_update_br(rob_br_mispredict_pc.datain_update_br),

    .commit_ready(rob_br_mispredict_pc.commit_ready),
    .is_done_bit(1'b0),
    .is_jump_bit(1'b0),
    .is_br_bit(1'b0),
    .is_br_in_rob(rob_br_mispredict_pc.is_br_in_rob),
    .is_jump_in_rob(rob_br_mispredict_pc.is_jump_in_rob),
    
    .dataout(rob_br_mispredict_pc.dataout),
    .cir_q_empty(rob_br_mispredict_pc.cir_q_empty),
    .cir_q_full(rob_br_mispredict_pc.cir_q_full),
    .commit_ptr_rob_idx(rob_br_mispredict_pc.commit_ptr_rob_idx),
    .issue_mod_out(issue_temp_out6),
    .commit_mod_out(commit_temp_out6)
);

endmodule : rob