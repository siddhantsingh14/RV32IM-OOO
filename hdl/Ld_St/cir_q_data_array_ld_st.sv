/*TO BE USED FOR FOR SRC_ROB and MEM_ROB QUES*/
import Ld_St_structs::*;
module cir_q_data_array_ld_st #(
    parameter s_offset = 5,
    parameter s_index = 5
)
(
    input clk,
    input rst,
    input read,
    input logic write, write_1, write_2, write_3, write_4, write_5, write_6, write_7, write_8, write_9,
    input logic [s_index-1:0] rindex, windex,
    input logic [31:0] windex_1, windex_2, windex_3, windex_4, windex_5, windex_6, windex_7, windex_8, windex_9,
    input logic [2**s_offset-1:0] datain, datain_1, datain_2, datain_3, datain_4, datain_5, datain_6, datain_7, datain_8, datain_9,
    output logic [2**s_offset-1:0] data_at_commit,
    
	 input logic [31:0] windex_32_1, windex_32_2, windex_32_3, windex_32_4, windex_32_5, windex_32_6, windex_32_7, windex_32_8, windex_32_9,
	 input logic write_32_1, write_32_2, write_32_3, write_32_4, write_32_5, write_32_6, write_32_7, write_32_8, write_32_9,
	 input logic [2**s_offset-1:0] datain_32_1, datain_32_2, datain_32_3, datain_32_4, datain_32_5, datain_32_6, datain_32_7, datain_32_8, datain_32_9,
	 
    input Ld_St_structs::look_up_rob look_up[8],
    output Ld_St_structs::output_look_up_rob output_look_up[8],
    //input logic check_done_bit,
    //output logic commit_ready
    // output [4:0] possible_commits, 
    input Ld_St_structs::look_up_valid look_up_valid[8],
    output Ld_St_structs::output_look_up_valid output_look_up_valid[8],
    input Ld_St_structs::look_up_rob look_up_mem_address,
    output Ld_St_structs::output_look_up_rob output_look_up_mem_address,
    input Ld_St_structs::look_up_valid look_up_valid_mem_address,
    output Ld_St_structs::output_look_up_valid output_look_up_valid_mem_address
);

// localparam s_line   = 8*s_mask;
localparam entry_size = 2**s_offset;
localparam num_sets = 2**s_index;

logic [entry_size-1:0] data [31:0] /* synthesis ramstyle = "logic" */;
logic [entry_size-1:0] _dataout;

assign data_at_commit = _dataout;

always_ff @(posedge clk)
begin
    if (rst) begin
        for (int i = 0; i < num_sets; ++i)
            data[i] <= '0;
    end
    else begin
        if (read)
            _dataout  <= data[rindex];
				
		  if (write)
            data[windex] <= datain;


        if (write_1)
        begin
            for(int i = 0; i < 32; i++)
            begin
                if (windex_1[i] == 1'b1)
                    data[i] <= datain_1;
            end
        end

        if (write_2)
        begin
            for(int i = 0; i < 32; i++)
            begin
                if (windex_2[i] == 1'b1)
                    data[i] <= datain_2;
            end
        end

        if (write_3)
        begin
            for(int i = 0; i < 32; i++)
            begin
                if (windex_3[i] == 1'b1)
                    data[i] <= datain_3;
            end
        end

        if (write_4)
        begin
            for(int i = 0; i < 32; i++)
            begin
                if (windex_4[i] == 1'b1)
                    data[i] <= datain_4;
            end
        end

        if (write_5)
        begin
            for(int i = 0; i < 32; i++)
            begin
                if (windex_5[i] == 1'b1)
                    data[i] <= datain_5;
            end
        end
        
        if (write_6)
        begin
            for(int i = 0; i < 32; i++)
            begin
                if (windex_6[i] == 1'b1)
                    data[i] <= datain_6;
            end
        end

        if (write_7)
        begin
            for(int i = 0; i < 32; i++)
            begin
                if (windex_7[i] == 1'b1)
                    data[i] <= datain_7;
            end
        end
        
        if (write_8)
        begin
            for(int i = 0; i < 32; i++)
            begin
                if (windex_8[i] == 1'b1)
                    data[i] <= datain_8;
            end
        end

        if (write_9)
        begin
            for(int i = 0; i < 32; i++)
            begin
                if (windex_9[i] == 1'b1)
                    data[i] <= datain_9;
            end
        end
				
		if (write_32_1)
        begin
            for(int i = 0; i < 32; i++)
            begin
                if (windex_32_1[i] == 1'b1)
                    data[i] <= datain_32_1;
            end
        end

        if (write_32_2)
        begin
            for(int i = 0; i < 32; i++)
            begin
                if (windex_32_2[i] == 1'b1)
                    data[i] <= datain_32_2;
            end
        end

        if (write_32_3)
        begin
            for(int i = 0; i < 32; i++)
            begin
                if (windex_32_3[i] == 1'b1)
                    data[i] <= datain_32_3;
            end
        end

        if (write_32_4)
        begin
            for(int i = 0; i < 32; i++)
            begin
                if (windex_32_4[i] == 1'b1)
                    data[i] <= datain_32_4;
            end
        end

        if (write_32_5)
        begin
            for(int i = 0; i < 32; i++)
            begin
                if (windex_32_5[i] == 1'b1)
                    data[i] <= datain_32_5;
            end
        end
        
        if (write_32_6)
        begin
            for(int i = 0; i < 32; i++)
            begin
                if (windex_32_6[i] == 1'b1)
                    data[i] <= datain_32_6;
            end
        end
        
        if (write_32_7)
        begin
            for(int i = 0; i < 32; i++)
            begin
                if (windex_32_7[i] == 1'b1)
                    data[i] <= datain_32_7;
            end
        end

        if (write_32_8)
        begin
            for(int i = 0; i < 32; i++)
            begin
                if (windex_32_8[i] == 1'b1)
                    data[i] <= datain_32_8;
            end
        end

        if (write_32_9)
        begin
            for(int i = 0; i < 32; i++)
            begin
                if (windex_32_9[i] == 1'b1)
                    data[i] <= datain_32_9;
            end
        end

    end
end

always_comb 
begin
    for(int i = 0; i < 8; i++)//ROB
    begin
        if(look_up[i].valid)
        begin
            output_look_up[i].valid = 1'b1; 
            for(int j = 0; j < 32; j++)
            begin
                if(data[j] == look_up[i].rob_idx)
                    output_look_up[i].que_write_idx[j] = 1'b1;
                else
                    output_look_up[i].que_write_idx[j] = 1'b0;
            end
        end
        else
        begin
            output_look_up[i].valid = 1'b0; 
            output_look_up[i].que_write_idx = '0;
        end
    end
end

always_comb begin
    for(int i = 0; i < 8; i++)
    begin
        if(look_up_valid[i].valid)
        begin
            output_look_up_valid[i].valid = 1'b1; 
            for(int j = 0; j < 32; j++)
            begin
                if(data[j] == look_up_valid[i].value)
                    output_look_up_valid[i].que_write_idx[j] = 1'b1;
                else
                    output_look_up_valid[i].que_write_idx[j] = 1'b0;
            end
        end
        else
        begin
            output_look_up_valid[i].valid = 1'b0; 
            output_look_up_valid[i].que_write_idx = '0;
        end
    end
end

always_comb begin
    if(look_up_mem_address.valid)
    begin
        output_look_up_mem_address.valid = 1'b1; 
        for(int j = 0; j < 32; j++)
        begin
            if(data[j] == look_up_mem_address.rob_idx)
                output_look_up_mem_address.que_write_idx[j] = 1'b1;
            else
                output_look_up_mem_address.que_write_idx[j] = 1'b0;
        end
    end
    else
    begin
        output_look_up_mem_address.valid = 1'b0; 
        output_look_up_mem_address.que_write_idx = '0;
    end

end

always_comb begin
    if(look_up_valid_mem_address.valid)
    begin
        output_look_up_valid_mem_address.valid = 1'b1; 
        for(int j = 0; j < 32; j++)
        begin
            if(data[j] == look_up_valid_mem_address.value)
                output_look_up_valid_mem_address.que_write_idx[j] = 1'b1;
            else
                output_look_up_valid_mem_address.que_write_idx[j] = 1'b0;
        end
    end
    else
    begin
        output_look_up_valid_mem_address.valid = 1'b0; 
        output_look_up_valid_mem_address.que_write_idx = '0;
    end
end

endmodule : cir_q_data_array_ld_st