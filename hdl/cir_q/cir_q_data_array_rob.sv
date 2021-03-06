module cir_q_data_array_rob #(
    parameter s_offset = 5,
    parameter s_index = 5
)
(
    input clk,
    input rst,
    input read,
    input write, write_1, write_2, write_3, write_4, write_5,
    input write_cmp, write_ld, write_br,
    input [s_index-1:0] rindex,
    input [s_index-1:0] windex, windex_1, windex_2, windex_3, windex_4, windex_5,
    input [s_index-1:0] windex_cmp, windex_ld, windex_br,
    input [2**s_offset-1:0] datain, datain_1, datain_2, datain_3, datain_4, datain_5, datain_cmp, datain_ld, datain_br,
    output logic [2**s_offset-1:0] dataout,

    output logic commit_ready,
    input logic is_done_bit,
    input logic update_en,
    input logic is_jump_bit,
    input logic is_br_bit,
    output logic is_br_in_rob,
    output logic is_jump_in_rob,
    input logic [4:0] issue_ptr,
    input logic [4:0] commit_ptr,
    input logic cir_q_full
    // output [4:0] possible_commits, 
);

// localparam s_line   = 8*s_mask;
localparam entry_size = 2**s_offset;
localparam num_sets = 2**s_index;

logic [entry_size-1:0] data [num_sets-1:0] /* synthesis ramstyle = "logic" */;
logic [entry_size-1:0] _dataout;

logic [s_index-1:0] rindex_next;

assign rindex_next = (rindex==31) ? '0 : rindex + 1;

assign dataout = _dataout;

always_ff @(posedge clk)
begin
    if (rst) begin
        for (int i = 0; i < num_sets; ++i)
            data[i] <= '0;
            
        _dataout <= '0;
    end
    else begin
        if (read)
            _dataout  <= data[rindex];

        if (write)
            data[windex] <= datain;

        if (write_1)
            data[windex_1] <= datain_1;

        if (write_2)
            data[windex_2] <= datain_2;

        if (write_3)
            data[windex_3] <= datain_3;

        if (write_4)
            data[windex_4] <= datain_4;

        if (write_5)
            data[windex_5] <= datain_5;

        if (write_cmp)
            data[windex_cmp] <= datain_cmp;

        if (write_ld)
            data[windex_ld] <= datain_ld;
        
        if (write_br)
            data[windex_br] <= datain_br;
    end
end

always_comb begin   : commit_ready_checking
    commit_ready=0;
    if(is_done_bit) begin
        if(write)   begin
            if(read)    begin
                if((datain) & (rindex==windex))
                    commit_ready=1'b1;
            end
            else begin
                if((datain) & (rindex_next==windex))
                    commit_ready=1'b1;
            end
        end
        else if(read)  begin //if we are committing, then check the next index to see if its already being done
            if(data[rindex_next]==1'b1)
                commit_ready= 1'b1; //if its done, then we can continue committing more
            else    begin   //if it hasnt been done yet, there is a chance it could be being broadcasted right now
                if(update_en)  begin
                    if((rindex_next==windex_5) & datain_5)
                        commit_ready = 1'b1;
                    else if((rindex_next==windex_1) & datain_1)
                        commit_ready = 1'b1;
                    else if((rindex_next==windex_2) & datain_2)
                        commit_ready = 1'b1;
                    else if((rindex_next==windex_3) & datain_3)
                        commit_ready = 1'b1;
                    else if((rindex_next==windex_4) & datain_4)
                        commit_ready = 1'b1;
                    else if((rindex_next==windex_cmp) & datain_cmp)
                        commit_ready = 1'b1;
                    else if((rindex_next==windex_ld) & datain_ld)
                        commit_ready = 1'b1;
                    else if((rindex_next==windex_br) & datain_br)
                        commit_ready = 1'b1;    
                    else
                        commit_ready = 1'b0;
                end
            end
        end
        else if(update_en)  begin
                if((rindex==windex_5) & datain_5)
                    commit_ready = 1'b1;
                else if((rindex==windex_1) & datain_1)
                    commit_ready = 1'b1;
                else if((rindex==windex_2) & datain_2)
                    commit_ready = 1'b1;
                else if((rindex==windex_3) & datain_3)
                    commit_ready = 1'b1;
                else if((rindex==windex_4) & datain_4)
                    commit_ready = 1'b1;
                else if((rindex==windex_cmp) & datain_cmp)
                    commit_ready = 1'b1;
                else if((rindex==windex_ld) & datain_ld)
                    commit_ready = 1'b1;
                else if((rindex==windex_br) & datain_br)
                    commit_ready = 1'b1;    
                else
                    commit_ready = 1'b0;
        end
        // end
        else begin
            if(data[rindex])    begin
                commit_ready = 1'b1;
            end
        end
    end

    else
        commit_ready = 1'b0;

end

/*
always_comb begin : jump_in_rob_checking
    is_jump_in_rob ='0;
    if(is_jump_bit) begin
        if(issue_ptr > commit_ptr)   begin
            for(int i = commit_ptr; i < issue_ptr ; i++)    begin
                if(data[i] == '1)
                    is_jump_in_rob = '1;
                else    
                    is_jump_in_rob = '0;
            end
        end
        else if(issue_ptr < commit_ptr) begin
            for(int i = commit_ptr; i < 32 ; i++)    begin
                if(data[i] == '1)
                    is_jump_in_rob = '1;
                else    
                    is_jump_in_rob = '0;
            end
            for(int i = 0; i < issue_ptr ; i++)    begin
                if(data[i] == '1)
                    is_jump_in_rob = '1;
                else    
                    is_jump_in_rob = '0;
            end
        end
        else if(cir_q_full) begin
            for(int i = 0; i < 32 ; i++)    begin
                if(data[i] == '1)
                    is_jump_in_rob = '1;
                else    
                    is_jump_in_rob = '0;
            end
        end
    end
end


always_comb begin : br_in_rob_checking
    is_br_in_rob ='0;
    if(is_br_bit) begin
        if(issue_ptr > commit_ptr)   begin
            for(int i = commit_ptr; i < issue_ptr ; i++)    begin
                if(data[i] == '1)
                    is_br_in_rob = '1;
                else    
                    is_br_in_rob = '0;
            end
        end
        else if(issue_ptr < commit_ptr) begin
            for(int i = commit_ptr; i < 32 ; i++)    begin
                if(data[i] == '1)
                    is_br_in_rob = '1;
                else    
                    is_br_in_rob = '0;
            end
            for(int i = 0; i < issue_ptr ; i++)    begin
                if(data[i] == '1)
                    is_br_in_rob = '1;
                else    
                    is_br_in_rob = '0;
            end
        end
        else if(cir_q_full) begin
            for(int i = 0; i < 32 ; i++)    begin
                if(data[i] == '1)
                    is_br_in_rob = '1;
                else    
                    is_br_in_rob = '0;
            end
        end
    end
end*/

endmodule : cir_q_data_array_rob