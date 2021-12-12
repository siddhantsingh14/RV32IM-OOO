/* Circular Queue  - Parameterized */

/* 
Description:
    Three actions : issue, commit, and update
*/

module cir_q_rob #(
    parameter cir_q_offset = 5,                 // By default, size of an entry = 32 bits 
    parameter cir_q_index = 5                   // By default, number of indices = 32 bits 
)(
    input clk,
    input rst,
    input [cir_q_index-1:0] update_index_0,
    input [cir_q_index-1:0] update_index_1,
    input [cir_q_index-1:0] update_index_2,
    input [cir_q_index-1:0] update_index_3,
    input [cir_q_index-1:0] update_index_4,
    input [cir_q_index-1:0] update_index_cmp,
    input [cir_q_index-1:0] update_index_ld,
    input [cir_q_index-1:0] update_index_br,
    

    input issue,                                // Signal to initiate an issue => issue_ptr++ 
    input commit,                               // Signal to initiate a commit => commit_ptr++
    input update_0,                               // Signal to initiate entry update on a broadcast
    input update_1,
    input update_2,
    input update_3,
    input update_4,
    input update_cmp,
    input update_ld,
    input update_br,

    input logic [2**cir_q_offset-1:0] datain_issue,
    input logic [2**cir_q_offset-1:0] datain_update_0,
    input logic [2**cir_q_offset-1:0] datain_update_1,
    input logic [2**cir_q_offset-1:0] datain_update_2,
    input logic [2**cir_q_offset-1:0] datain_update_3,
    input logic [2**cir_q_offset-1:0] datain_update_4,
    input logic [2**cir_q_offset-1:0] datain_update_cmp,
    input logic [2**cir_q_offset-1:0] datain_update_ld,
    input logic [2**cir_q_offset-1:0] datain_update_br,

    output logic commit_ready,
    input logic is_done_bit,
    input logic is_jump_bit,
    input logic is_br_bit,
    output logic is_br_in_rob,
    output logic is_jump_in_rob,
    // output [4:0] possible_commits, 

    output logic [2**cir_q_offset-1:0] dataout,
    output logic cir_q_full, cir_q_empty,
    output logic [cir_q_index-1:0] commit_ptr_rob_idx,
    output logic [cir_q_index-1:0] issue_mod_out, commit_mod_out
);

enum logic {
    EMPTY,
    HAS_DATA
} curr_state, next_state;

localparam entry_size = 2**cir_q_offset;
localparam num_entries = 2**cir_q_index;

logic [cir_q_index-1:0] issue_in, issue_out, commit_in, commit_out;    // Pointers to keep track of indices 
logic [2**cir_q_offset-1:0] datain, datain_1, datain_2, datain_3, datain_4, datain_5, datain_cmp, datain_ld, datain_br;
logic [entry_size-1:0] data [num_entries-1:0];

logic [cir_q_index-1:0] rindex, windex, windex_1, windex_2, windex_3, windex_4, windex_5, windex_cmp, windex_ld, windex_br;
logic read, write, write_1, write_2, write_3, write_4, write_5, write_cmp, write_ld, write_br;
logic load_issue, load_commit, l_commit_out, load_l_commit, l_commit_in;
logic update_en;


assign issue_mod_out = issue_out;
assign commit_mod_out = commit_out;


assign commit_ptr_rob_idx = commit_out - 1;
// assign cir_q_full = (commit_out == issue_out) & ~l_commit_out;

assign issue_in = (issue_out == '1 ? '0 : issue_out + 1);
assign commit_in = (commit_out == '1 ? '0 : commit_out + 1);

assign l_commit_in = ((commit_out + 1) == issue_out) | (commit_out == '1 & issue_out == '0);

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
    rindex = commit_out;
    read = 1'b0;
    write = 1'b0;
    write_1 = 1'b0;
    write_2 = 1'b0;
    write_3 = 1'b0;
    write_4 = 1'b0;
    write_5 = 1'b0;
    datain = '0;
    datain_1 = '0;
    datain_2 = '0;
    datain_3 = '0;
    datain_4 = '0;
    datain_5 = '0;
    update_en = '0;

    write_cmp = '0;
    windex_cmp = '0;
    datain_cmp = '0;
    write_ld = '0;
    windex_ld = '0;
    datain_ld = '0;

    write_br = '0;
    windex_br = '0;
    datain_br = '0;

    unique case (curr_state)
        EMPTY       :  begin
            cir_q_empty = 1'b1;
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
                read = 1'b1;
                rindex = commit_out;
                if(is_done_bit) begin
                    write=1'b1;
                    datain = 1'b0;
                    windex = (commit_out)? commit_out-1 : 31;
                end
            end
            if (update_0 | update_1 | update_2 | update_3 | update_4) begin
                if(update_0)    begin
                    update_en = 1'b1;
                    rindex = commit_out;
                    write_5 = 1'b1;
                    windex_5 = update_index_0;
                    datain_5 = datain_update_0;
                end
                if(update_1)    begin
                    update_en = 1'b1;
                    rindex = commit_out;
                    write_1 = 1'b1;
                    windex_1 = update_index_1;
                    datain_1 = datain_update_1;
                end
                if(update_2)    begin
                    update_en = 1'b1;
                    rindex = commit_out;
                    write_2 = 1'b1;
                    windex_2 = update_index_2;
                    datain_2 = datain_update_2;
                end
                if(update_3)    begin
                    update_en = 1'b1;
                    rindex = commit_out;
                    write_3 = 1'b1;
                    windex_3 = update_index_3;
                    datain_3 = datain_update_3;
                end
                if(update_4)    begin
                    update_en = 1'b1;
                    rindex = commit_out;
                    write_4 = 1'b1;
                    windex_4 = update_index_4;
                    datain_4 = datain_update_4;
                end
            end
            if(update_cmp)    begin
                update_en = 1'b1;
                rindex = commit_out;
                write_cmp = 1'b1;
                windex_cmp = update_index_cmp;
                datain_cmp = datain_update_cmp;
            end
            if(update_ld)    begin
                update_en = 1'b1;
                rindex = commit_out;
                write_ld = 1'b1;
                windex_ld = update_index_ld;
                datain_ld = datain_update_ld;
            end

            if(update_br)    begin
                update_en = 1'b1;
                rindex = commit_out;
                write_br = 1'b1;
                windex_br = update_index_br;
                datain_br = datain_update_br;
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
            if (cir_q_empty & ~issue)
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

cir_q_data_array_rob #(.s_offset(cir_q_offset), .s_index(cir_q_index)) DM_cir_q  (clk, rst, read, write, write_1, write_2, write_3, write_4, write_5, write_cmp, write_ld, write_br, rindex, windex, windex_1, windex_2, windex_3, windex_4, windex_5, windex_cmp, windex_ld, windex_br, datain, datain_1, datain_2, datain_3, datain_4, datain_5, datain_cmp, datain_ld, datain_br, dataout, commit_ready, is_done_bit, update_en, is_jump_bit, is_br_bit, is_br_in_rob, is_jump_in_rob, issue_out, commit_out, cir_q_full);
register #(.width(cir_q_index)) issue_ptr_reg (clk, rst, load_issue, issue_in, issue_out);
register #(.width(cir_q_index)) commit_ptr_reg (clk, rst, load_commit, commit_in, commit_out);
register #(.width(1)) l_commit_reg (clk, rst, load_l_commit, l_commit_in, l_commit_out);
endmodule : cir_q_rob













