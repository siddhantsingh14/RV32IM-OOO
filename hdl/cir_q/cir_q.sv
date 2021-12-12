/* Circular Queue  - Parameterized */

/* 
Description:
    Three actions : issue, commit, and update
*/

module cir_q #(
    parameter cir_q_offset = 5,                 // By default, size of an entry = 32 bits 
    parameter cir_q_index = 5                   // By default, number of indices = 32 bits 
)(
    input clk,
    input rst,
    input [cir_q_index-1:0] update_index,

    input issue,                                // Signal to initiate an issue => issue_ptr++ 
    input commit,                               // Signal to initiate a commit => commit_ptr++
    input update,                               // Signal to initiate entry update on a broadcast

    input logic [2**cir_q_offset-1:0] datain_issue,
    input logic [2**cir_q_offset-1:0] datain_update,
    
    output logic [2**cir_q_offset-1:0] dataout,
    output logic [2**cir_q_offset-1:0] dataout_commit,
    output logic cir_q_full, cir_q_empty, cir_q_empty_1,
    // output logic commit_ready,                      // Output signal to signify that we can commit the entry at commit_ptr but not actually committing it

    output logic [cir_q_index-1:0] issue_ptr_dbg,
    output logic l_commit_dbg,
    output logic [cir_q_index-1:0] commit_ptr_dbg,
    output logic [cir_q_index-1:0] windex_dbg,
    output logic [cir_q_index-1:0] rindex_dbg
);

enum logic {
    EMPTY,
    HAS_DATA
} curr_state, next_state;

localparam entry_size = 2**cir_q_offset;
localparam num_entries = 2**cir_q_index;

logic [cir_q_index-1:0] issue_in, issue_out, commit_in, commit_out, rindex, windex;    // Pointers to keep track of indices 
logic [2**cir_q_offset-1:0] datain;
logic [entry_size-1:0] data [num_entries-1:0];

logic read, write, load_reg_full, cir_q_full_in;
logic load_issue, load_commit, l_commit_out, load_l_commit, l_commit_in;

assign issue_ptr_dbg = issue_out;
assign commit_ptr_dbg = commit_out;
assign l_commit_dbg = l_commit_out;
assign windex_dbg = windex;
assign rindex_dbg = rindex;

// assign cir_q_full = (commit_out == issue_out) & ~l_commit_out;

assign issue_in = (issue_out == '1 ? '0 : issue_out + 1);
assign commit_in = (commit_out == '1 ? '0 : commit_out + 1);

assign l_commit_in = ((commit_out + 1) == issue_out) | (commit_out == '1 & issue_out == '0);

always_comb begin : CURR_STATE_LOGIC
    load_issue = 1'b0;
    load_commit = 1'b0;
	load_l_commit = 1'b0;
    cir_q_empty = 1'b0;
    cir_q_empty_1 = 1'b0;
    cir_q_full_in = 1'b0;
    load_reg_full = 1'b0;
    windex = '0;
    rindex = '0;
    read = 1'b0;
    write = 1'b0;
    datain = '0;

    unique case (curr_state)
        EMPTY       :  begin
            cir_q_empty = 1'b1;
            cir_q_empty_1 = 1'b1;
            if (issue) begin
                load_issue = 1'b1;
                // load_l_commit = 1'b1;
                cir_q_empty_1 = 1'b0;
                write = 1'b1;
                windex = issue_out;
                datain = datain_issue;
            end
		end	
        HAS_DATA    :   begin
            if ((issue_out == commit_out) & l_commit_out) begin
                cir_q_empty = 1'b1;
                cir_q_empty_1 = 1'b1;
            end
            if ((issue_out == commit_out) & ~l_commit_out) begin
                cir_q_full_in = 1'b1;
                load_reg_full = 1'b1;
            end

            if (issue) begin
                if (~cir_q_full & ~cir_q_full_in) begin
                    load_issue = 1'b1;
                    write = 1'b1;
                    load_l_commit = 1'b1;
                    windex = issue_out;
                    datain = datain_issue;
                end
                else begin
                    load_reg_full = 1'b1;
                    cir_q_full_in = 1'b1;
                end
            end
            if (commit) begin
                load_commit = 1'b1;
                load_l_commit = l_commit_in;
                read = 1'b1;
                rindex = commit_out;
                cir_q_full_in = 1'b0;
                load_reg_full = 1'b1;
            end
    
            if (update) begin
                write = 1'b1;
                windex = update_index;
                datain = datain_update;
            end
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

cir_q_data_array #(.s_offset(cir_q_offset), .s_index(cir_q_index)) DM_cir_q  (clk, rst, read, write, rindex, windex, commit_out, datain, dataout, dataout_commit);

register #(.width(cir_q_index)) issue_ptr_reg (clk, rst, load_issue, issue_in, issue_out);
register #(.width(cir_q_index)) commit_ptr_reg (clk, rst, load_commit, commit_in, commit_out);
register #(.width(1)) l_commit_reg (clk, rst, load_l_commit, l_commit_in, l_commit_out);
register #(.width(1)) full_reg (clk, rst, load_reg_full, cir_q_full_in, cir_q_full);
endmodule : cir_q













