/* Circular Queue  - Parameterized 
SRC ROB AND MEM ROB QUES*/
/* 
Description:
    Three actions : issue, commit, and update
*/
import Ld_St_structs::*;
module cir_q_ld_st #(
    parameter cir_q_offset = 5,                 // By default, size of an entry = 32 bits 
    parameter cir_q_index = 5                   // By default, number of indices = 32 bits 
)(
    input clk,
    input rst,
    // .update_index(src_rob_cirq.update_index_0),

    input issue,                                // Signal to initiate an issue => issue_ptr++ 
    input commit,                               // Signal to initiate a commit => commit_ptr++
    // .update(src_rob_mem_address_cirq.update_0),                               // Signal to initiate entry update on a broadcast

    input logic [2**cir_q_offset-1:0] datain_issue,
    // .datain_update(src_rob_mem_address_cirq.datain_update_0),
    
    output logic [2**cir_q_offset-1:0] data_at_commit,
    output logic cir_q_full, cir_q_empty,
    // output logic commit_ready,                      // Output signal to signify that we can commit the entry at commit_ptr but not actually committing it
    //SIGNALS I NEED FROM BASE CIRQs

    input Ld_St_structs::look_up_rob look_up[7],
    output Ld_St_structs::output_look_up_rob output_look_up[7],

    input Ld_St_structs::update_32 update_32[7],
	input Ld_St_structs::update_1 update_1[7],


    input Ld_St_structs::look_up_rob look_up_mem_address,
    output Ld_St_structs::output_look_up_rob output_look_up_mem_address,
    input Ld_St_structs::look_up_valid look_up_valid_mem_address,
    output Ld_St_structs::output_look_up_valid output_look_up_valid_mem_address,
    input Ld_St_structs::update_32 update_32_mem_addr,
	input Ld_St_structs::update_1 update_1_mem_addr,

    input Ld_St_structs::look_up_valid look_up_valid[7],
    output Ld_St_structs::output_look_up_valid output_look_up_valid[7]


    //output logic data_at_commit//output
);

enum logic {
    EMPTY,
    HAS_DATA
} curr_state, next_state;

localparam entry_size = 2**cir_q_offset;
localparam num_entries = 2**cir_q_index;

logic [cir_q_index-1:0] issue_in, issue_out, commit_in, commit_out;    // Pointers to keep track of indices 
logic [2**cir_q_offset-1:0] datain, datain_1, datain_2, datain_3, datain_4, datain_5, datain_6, datain_7, datain_8;
logic [entry_size-1:0] data [num_entries-1:0];

logic [cir_q_index-1:0] rindex, windex;
logic [31:0] windex_1, windex_2, windex_3, windex_4, windex_5, windex_6, windex_7, windex_8;
logic read, write, write_1, write_2, write_3, write_4, write_5, write_6, write_7, write_8;
logic load_issue, load_commit, l_commit_out, load_l_commit, l_commit_in;

logic [31:0] windex_32_1, windex_32_2, windex_32_3, windex_32_4, windex_32_5, windex_32_6, windex_32_7, windex_32_8;
logic write_32_1, write_32_2, write_32_3, write_32_4, write_32_5, write_32_6, write_32_7, write_32_8;
logic [2**cir_q_offset-1:0] datain_32_1, datain_32_2, datain_32_3, datain_32_4, datain_32_5, datain_32_6, datain_32_7, datain_32_8;


assign commit_ptr_rob_idx = commit_out - 1;
// assign cir_q_full = (commit_out == issue_out) & ~l_commit_out;

assign issue_in = (issue_out == '1 ? '0 : issue_out + 1);
assign commit_in = (commit_out == '1 ? '0 : commit_out + 1);

assign l_commit_in = ((commit_out + 1) == issue_out) | (commit_out == '1 & issue_out == '0);
assign rindex = commit_out;
assign read = 1'b1;

always_comb begin : CURR_STATE_LOGIC
    load_issue = 1'b0;
    load_commit = 1'b0;
	load_l_commit = 1'b0;
    cir_q_empty = 1'b0;
    cir_q_full = 1'b0;
    windex = '0;
    windex_1 = '0;
    windex_2 = '0;
    windex_3 = '0;
    windex_4 = '0;
    windex_5 = '0;
	 windex_6 = '0;
      windex_7 = '0;
	 windex_8 = '0;
    // rindex = '0;
    // read = 1'b0;
    write = 1'b0;
    write_1 = 1'b0;
    write_2 = 1'b0;
    write_3 = 1'b0;
    write_4 = 1'b0;
    write_5 = 1'b0;
	 write_6 = 1'b0;
      write_7 = 1'b0;
       write_8 = 1'b0;
    datain = '0;
    datain_1 = '0;
    datain_2 = '0;
    datain_3 = '0;
    datain_4 = '0;
    datain_5 = '0;
	 datain_6 = '0;
    datain_7 = '0;
	 datain_8 = '0;
	 write_32_1 = 1'b0;
    write_32_2 = 1'b0;
    write_32_3 = 1'b0;
    write_32_4 = 1'b0;
    write_32_5 = 1'b0;
	 write_32_6 = 1'b0;
     write_32_7 = 1'b0;
	 write_32_8 = 1'b0;
    datain_32_1 = '0;
    datain_32_2 = '0;
    datain_32_3 = '0;
    datain_32_4 = '0;
    datain_32_5 = '0;
	 datain_32_6 = '0;
        datain_32_7 = '0;
	 datain_32_8 = '0;
	 windex_32_1 = '0;
    windex_32_2 = '0;
    windex_32_3 = '0;
    windex_32_4 = '0;
    windex_32_5 = '0;
	 windex_32_6 = '0;
       windex_32_7 = '0;
	 windex_32_8 = '0;
	 

    unique case (curr_state)
        EMPTY       :  begin
            cir_q_empty = 1'b1;
            // cir_q_full = 1'b0;
            if (issue) begin
                load_issue = 1'b1;
                write = 1'b1;
                windex = issue_out;
                datain = datain_issue;
            end
		end	
        HAS_DATA    :   begin
            if (issue & ~cir_q_full) begin
                load_issue = 1'b1;
                write = 1'b1;
                windex = issue_out;
                datain = datain_issue;
            end
            if (commit) begin
                load_l_commit = 1'b1;
                load_commit = 1'b1;
               // read = 1'b1;
              //  rindex = commit_out;
            end
            // if (check_done_bit) begin
            //     rindex = commit_out;
            // end
            if (update_1[0].valid | update_1[1].valid | update_1[2].valid | update_1[3].valid | update_1[4].valid | update_1[5].valid | update_1[6].valid | update_1_mem_addr.valid) begin
                if(update_1[0].valid)    begin
                    write_1 = 1'b1;
                    windex_1 = update_1[0].que_write_idx;
                    datain_1 = update_1[0].update_data;
                end
                if(update_1[1].valid)    begin
                    write_2 = 1'b1;
                    windex_2 = update_1[1].que_write_idx;
                    datain_2 = update_1[1].update_data;
                end
                if(update_1[2].valid)    begin
                    write_3 = 1'b1;
                    windex_3 = update_1[2].que_write_idx;
                    datain_3 = update_1[2].update_data;
                end
                if(update_1[3].valid)    begin
                    write_4 = 1'b1;
                    windex_4 = update_1[3].que_write_idx;
                    datain_4 = update_1[3].update_data;
                end
                if(update_1[4].valid)    begin
                    write_5 = 1'b1;
                    windex_5 = update_1[4].que_write_idx;
                    datain_5 = update_1[4].update_data;
                end
                if(update_1[5].valid)    begin
                    write_6 = 1'b1;
                    windex_6 = update_1[5].que_write_idx;
                    datain_6 = update_1[5].update_data;
                end
                if(update_1[6].valid)    begin
                    write_7 = 1'b1;
                    windex_7 = update_1[6].que_write_idx;
                    datain_7 = update_1[6].update_data;
                end
                if(update_1_mem_addr.valid)    begin
                    write_8 = 1'b1;
                    windex_8 = update_1_mem_addr.que_write_idx;
                    datain_8 = update_1_mem_addr.update_data;
                end
            end
				
				if (update_32[0].valid | update_32[1].valid | update_32[2].valid | update_32[3].valid | update_32[4].valid | update_32[5].valid | update_32[6].valid | update_32_mem_addr.valid) begin
                if(update_32[0].valid)    begin
                    write_32_1 = 1'b1;
                    windex_32_1 = update_32[0].que_write_idx;
                    datain_32_1 = update_32[0].update_data;
                end
                if(update_32[1].valid)    begin
                    write_32_2 = 1'b1;
                    windex_32_2 = update_32[1].que_write_idx;
                    datain_32_2 = update_32[1].update_data;
                end
                if(update_32[2].valid)    begin
                    write_32_3 = 1'b1;
                    windex_32_3 = update_32[2].que_write_idx;
                    datain_32_3 = update_32[2].update_data;
                end
                if(update_32[3].valid)    begin
                    write_32_4 = 1'b1;
                    windex_32_4 = update_32[3].que_write_idx;
                    datain_32_4 = update_32[3].update_data;
                end
                if(update_32[4].valid)    begin
                    write_32_5 = 1'b1;
                    windex_32_5 = update_32[4].que_write_idx;
                    datain_32_5 = update_32[4].update_data;
                end
                if(update_32[5].valid)    begin
                    write_32_6 = 1'b1;
                    windex_32_6 = update_32[5].que_write_idx;
                    datain_32_6 = update_32[5].update_data;
                end
                if(update_32[6].valid)    begin
                    write_32_7 = 1'b1;
                    windex_32_7 = update_32[6].que_write_idx;
                    datain_32_7 = update_32[6].update_data;
                end
                if(update_32_mem_addr.valid)    begin
                    write_32_8 = 1'b1;
                    windex_32_8 = update_32_mem_addr.que_write_idx;
                    datain_32_8 = update_32_mem_addr.update_data;
                end
            end
            if ((issue_out == commit_out) & l_commit_out) cir_q_empty = 1'b1;
            if ((commit_out == issue_out) & ~l_commit_out)  cir_q_full = 1'b1;
        end
    endcase
end

always_comb begin : NEXT_STATE_LOGIC
    next_state = curr_state;
    unique case (curr_state)
        EMPTY       :   if (issue) next_state = HAS_DATA;
        HAS_DATA    :   begin
            if (cir_q_full) next_state = HAS_DATA;
            if (cir_q_empty)
                next_state = EMPTY;
        end
    endcase
end

always_ff @(posedge clk) begin
    if (rst) begin
        curr_state <= EMPTY;
    end
    else begin
        curr_state <= next_state; 
	 end	  
end

cir_q_data_array_ld_st #(.s_offset(cir_q_offset), .s_index(cir_q_index)) DM_cir_q  (clk, rst, read, write, write_1, write_2, write_3, write_4, write_5, write_6, write_7, write_8, rindex, windex, windex_1, windex_2, windex_3, windex_4, windex_5, windex_6, windex_7, windex_8, datain, datain_1, datain_2, datain_3, datain_4, datain_5, datain_6, datain_7, datain_8, data_at_commit, windex_32_1, windex_32_2, windex_32_3, windex_32_4, windex_32_5, windex_32_6, windex_32_7, windex_32_8, write_32_1, write_32_2, write_32_3, write_32_4, write_32_5, write_32_6, write_32_7, write_32_8, datain_32_1, datain_32_2, datain_32_3, datain_32_4, datain_32_5, datain_32_6, datain_32_7, datain_32_8, look_up, output_look_up, look_up_valid, output_look_up_valid, look_up_mem_address, output_look_up_mem_address, look_up_valid_mem_address, output_look_up_valid_mem_address);
register #(.width(cir_q_index)) issue_ptr_reg (clk, rst, load_issue, issue_in, issue_out);
register #(.width(cir_q_index)) commit_ptr_reg (clk, rst, load_commit, commit_in, commit_out);
register #(.width(1)) l_commit_reg (clk, rst, load_l_commit, l_commit_in, l_commit_out);
endmodule : cir_q_ld_st













