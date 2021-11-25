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
    output logic [cir_q_index-1:0] issue_mod_out, commit_mod_out
);

localparam entry_size = 2**cir_q_offset;
localparam num_entries = 2**cir_q_index;

localparam DR_cir_q_offset = 3;
localparam DR_cir_q_index = 5;

localparam done_cir_q_offset = 0;
localparam done_cir_q_index = 5;


rob_entry_structs::rob_dr_entry dr;
rob_entry_structs::rob_done_entry done;
rob_entry_structs::rob_value_entry value;
rob_entry_structs::rob_st_entry st;

logic [cir_q_index-1:0] issue_temp_out1, commit_temp_out1;
logic [cir_q_index-1:0] issue_temp_out2, commit_temp_out2;
logic [cir_q_index-1:0] issue_temp_out3, commit_temp_out3;
logic [cir_q_index-1:0] issue_temp_out4, commit_temp_out4;



always_comb begin
    cir_q_full = dr.cir_q_full;
    cir_q_empty = dr.cir_q_empty;
    commit_ready= done.commit_ready;
    // if(value.dataout != 'x)    begin
        rob_regfile_bus.value = ((done.dataout) & (~st.dataout)) ? value.dataout : 'x;
        rob_regfile_bus.regfile_idx = ((done.dataout) & (~st.dataout)) ? dr.dataout :'x;
        rob_regfile_bus.rob_idx = ((done.dataout) & (~st.dataout)) ? dr.commit_ptr_rob_idx :'x;
        rob_regfile_bus.valid = ((done.dataout) & (~st.dataout)) ? 1'b1 : 1'b0;
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

    dr.update_cmp ='0;
    dr.update_index_cmp = '0;
    dr.datain_update_cmp ='0;

    done.update_cmp ='0;
    done.update_index_cmp = '0;
    done.datain_update_cmp ='0;

    value.update_cmp ='0;
    value.update_index_cmp = '0;
    value.datain_update_cmp ='0;

    st.update_cmp ='0;
    st.update_index_cmp = '0;
    st.datain_update_cmp ='0;

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

endfunction
//driving inputs
always_comb    begin
    set_defaults();
    if(rst) begin
        set_defaults();
	end
    else    begin
        if(IQtoROB.rob_issue)  begin
            dr.issue =1'b1;
            done.issue =1'b1;
            value.issue =1'b1;
            st.issue = 1'b1;

            st.datain_issue = 1'b0;
            dr.datain_issue = {3'd0, IQtoROB.dr};  //only written like this because important to note top 3 bits are masked.
            if(IQtoROB.load_imm)    begin
                if(IQtoROB.is_st)
                    done.datain_issue = 1'b0;
                else
                    done.datain_issue = 1'b1;
                value.datain_issue = IQtoROB.load_imm_val;
            end
            else begin
                done.datain_issue = 1'b0;
                value.datain_issue = 'x;
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
        if(commit)  begin
            dr.commit =1'b1;
            done.commit =1'b1;
            value.commit =1'b1;
            st.commit = 1'b1;
        end
    end
end

cir_q_rob #(
    .cir_q_offset(DR_cir_q_offset),
    .cir_q_index(DR_cir_q_index)
)
DR_entry (
    .clk(clk),
    .rst(rst),
    .update_index_0(dr.update_index_0),
    .update_index_1(dr.update_index_1),
    .update_index_2(dr.update_index_2),
    .update_index_3(dr.update_index_3),
    .update_index_4(dr.update_index_4),
    .update_index_cmp(dr.update_index_cmp),
    .update_index_ld(dr.update_index_ld),

    .issue(dr.issue),
    .commit(dr.commit),
    .update_0(dr.update_0),
    .update_1(dr.update_1),
    .update_2(dr.update_2),
    .update_3(dr.update_3),
    .update_4(dr.update_4),
    .update_cmp(dr.update_cmp),
    .update_ld(dr.update_ld),

    .datain_issue(dr.datain_issue),
    .datain_update_0(dr.datain_update_0),
    .datain_update_1(dr.datain_update_1),
    .datain_update_2(dr.datain_update_2),
    .datain_update_3(dr.datain_update_3),
    .datain_update_4(dr.datain_update_4),
    .datain_update_cmp(dr.datain_update_cmp),
    .datain_update_ld(dr.datain_update_ld),

    .commit_ready(dr.commit_ready),
    .is_done_bit(1'b0),
    
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
    .rst(rst),
    .update_index_0(done.update_index_0),
    .update_index_1(done.update_index_1),
    .update_index_2(done.update_index_2),
    .update_index_3(done.update_index_3),
    .update_index_4(done.update_index_4),
    .update_index_cmp(done.update_index_cmp),
    .update_index_ld(done.update_index_ld),

    .issue(done.issue),
    .commit(done.commit),
    .update_0(done.update_0),
    .update_1(done.update_1),
    .update_2(done.update_2),
    .update_3(done.update_3),
    .update_4(done.update_4),
    .update_cmp(done.update_cmp),
    .update_ld(done.update_ld),

    .datain_issue(done.datain_issue),
    .datain_update_0(done.datain_update_0),
    .datain_update_1(done.datain_update_1),
    .datain_update_2(done.datain_update_2),
    .datain_update_3(done.datain_update_3),
    .datain_update_4(done.datain_update_4),
    .datain_update_cmp(done.datain_update_cmp),
    .datain_update_ld(done.datain_update_ld),

    .commit_ready(done.commit_ready),
    .is_done_bit(1'b1),

    .dataout(done.dataout),
    .cir_q_empty(done.cir_q_empty),
    .cir_q_full(done.cir_q_full),
    .commit_ptr_rob_idx(done.commit_ptr_rob_idx),
    .issue_mod_out(issue_temp_out1),
    .commit_mod_out(commit_temp_out1)
);

cir_q_rob #(
    .cir_q_offset(cir_q_offset),
    .cir_q_index(cir_q_index)
)
value_entry (
    .clk(clk),
    .rst(rst),
    .update_index_0(value.update_index_0),
    .update_index_1(value.update_index_1),
    .update_index_2(value.update_index_2),
    .update_index_3(value.update_index_3),
    .update_index_4(value.update_index_4),
    .update_index_cmp(value.update_index_cmp),
    .update_index_ld(value.update_index_ld),

    .issue(value.issue),
    .commit(value.commit),
    .update_0(value.update_0),
    .update_1(value.update_1),
    .update_2(value.update_2),
    .update_3(value.update_3),
    .update_4(value.update_4),
    .update_cmp(value.update_cmp),
    .update_ld(value.update_ld),

    .datain_issue(value.datain_issue),
    .datain_update_0(value.datain_update_0),
    .datain_update_1(value.datain_update_1),
    .datain_update_2(value.datain_update_2),
    .datain_update_3(value.datain_update_3),
    .datain_update_4(value.datain_update_4),
    .datain_update_cmp(value.datain_update_cmp),
    .datain_update_ld(value.datain_update_ld),

    .commit_ready(value.commit_ready),
    .is_done_bit(1'b0),
    
    .dataout(value.dataout),
    .cir_q_empty(value.cir_q_empty),
    .cir_q_full(value.cir_q_full),
    .commit_ptr_rob_idx(value.commit_ptr_rob_idx),
    .issue_mod_out(issue_temp_out3),
    .commit_mod_out(commit_temp_out3)
);

cir_q_rob #(
    .cir_q_offset(done_cir_q_offset),
    .cir_q_index(done_cir_q_index)
)
st_entry (
    .clk(clk),
    .rst(rst),
    .update_index_0(st.update_index_0),
    .update_index_1(st.update_index_1),
    .update_index_2(st.update_index_2),
    .update_index_3(st.update_index_3),
    .update_index_4(st.update_index_4),
    .update_index_cmp(st.update_index_cmp),
    .update_index_ld(st.update_index_ld),

    .issue(st.issue),
    .commit(st.commit),
    .update_0(st.update_0),
    .update_1(st.update_1),
    .update_2(st.update_2),
    .update_3(st.update_3),
    .update_4(st.update_4),
    .update_cmp(st.update_cmp),
    .update_ld(st.update_ld),

    .datain_issue(st.datain_issue),
    .datain_update_0(st.datain_update_0),
    .datain_update_1(st.datain_update_1),
    .datain_update_2(st.datain_update_2),
    .datain_update_3(st.datain_update_3),
    .datain_update_4(st.datain_update_4),
    .datain_update_cmp(st.datain_update_cmp),
    .datain_update_ld(st.datain_update_ld),

    .commit_ready(st.commit_ready),
    .is_done_bit(1'b0),
    
    .dataout(st.dataout),
    .cir_q_empty(st.cir_q_empty),
    .cir_q_full(st.cir_q_full),
    .commit_ptr_rob_idx(st.commit_ptr_rob_idx),
    .issue_mod_out(issue_temp_out4),
    .commit_mod_out(commit_temp_out4)
);

endmodule : rob