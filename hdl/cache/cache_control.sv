/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */
//import sched_structs::*;

module cache_control (
	input clk,
	input rst,
	
	input [31:0] mem_address,
	output logic mem_resp,
	input mem_read,
	input mem_write,
	
	input pmem_resp,
	output logic pmem_read,
   output logic pmem_write,
   output logic[31:0] pmem_addr,
	
	output logic [1:0] data_arr1_writer_en_ctrl,
	output logic data_arr1_datain_ctrl,
	output logic [1:0] data_arr2_writer_en_ctrl,
	output logic data_arr2_datain_ctrl,
	output logic [1:0] data_arr3_writer_en_ctrl,
	output logic data_arr3_datain_ctrl,
	output logic [1:0] data_arr4_writer_en_ctrl,
	output logic data_arr4_datain_ctrl,
	
	output logic [1:0] cacheline_out_ctrl,
	
	output logic ld_tag1,
	output logic ld_tag2,
	output logic ld_tag3,
	output logic ld_tag4,
	input logic [22:0] tag1_out, tag2_out, tag3_out, tag4_out,
	
	output logic ld_dirty1,
	output logic dirty1_in,
	input logic dirty1_out,
	output logic ld_dirty2,
	output logic dirty2_in,
	input logic dirty2_out,
	output logic ld_dirty3,
	output logic dirty3_in,
	input logic dirty3_out,
	output logic ld_dirty4,
	output logic dirty4_in,
	input logic dirty4_out,
	
	output logic ld_lru,
	output logic [2:0] lru_in,
	input logic [2:0] lru_out,
	
	output logic ld_valid1,
	output logic valid1_in,
	input logic valid1_out,
	output logic ld_valid2,
	output logic valid2_in,
	input logic valid2_out,
	output logic ld_valid3,
	output logic valid3_in,
	input logic valid3_out,
	output logic ld_valid4,
	output logic valid4_in,
	input logic valid4_out,
	input sched_structs::ROBToALL ROBToALL
);

logic tag1_hit, tag2_hit, tag3_hit, tag4_hit;
assign tag1_hit = (tag1_out == mem_address[31:9] && valid1_out) ? 1'b1 : 1'b0;
assign tag2_hit = (tag2_out == mem_address[31:9] && valid2_out) ? 1'b1 : 1'b0;
assign tag3_hit = (tag3_out == mem_address[31:9] && valid3_out) ? 1'b1 : 1'b0;
assign tag4_hit = (tag4_out == mem_address[31:9] && valid4_out) ? 1'b1 : 1'b0;


//always_ff@(posedge clk)	begin
//	if(valid1_out)	begin
//		if(tag1_out == mem_address[31:9])
//			tag1_hit = '1;
//		else
//			tag1_hit = '0;
//	end
//	else
//		tag1_hit ='0;
//		
//	if(valid2_out)	begin
//		if(tag2_out == mem_address[31:9])
//			tag2_hit = '1;
//		else
//			tag2_hit = '0;
//	end
//	else
//		tag2_hit ='0;
//	if(valid3_out)	begin
//		if(tag3_out == mem_address[31:9])
//			tag3_hit = '1;
//		else
//			tag3_hit = '0;
//	end
//	else
//		tag3_hit ='0;
//	if(valid4_out)	begin
//		if(tag4_out == mem_address[31:9])
//			tag4_hit = '1;
//		else
//			tag4_hit = '0;
//	end
//	else
//		tag4_hit ='0;
//end

enum int unsigned {
    /* List of states */
	 WAIT=0,
	 READ_WRITE=1,
	 WRITE = 2,
	 READ_MEM=3,
	 WRITE_CACHE=4,
	 WRITE_MEM=5,
	 READ_MISS=6,
	 FLUSH=7
	 
} state, next_state;

function void set_defaults();
	 mem_resp = 1'b0;
	 pmem_read = 1'b0;
	 pmem_write = 1'b0;
	 data_arr1_writer_en_ctrl = 2'b0;
	 data_arr1_datain_ctrl = 1'b0;
	 data_arr2_writer_en_ctrl = 2'b0;
	 data_arr2_datain_ctrl = 1'b0;
	 data_arr3_writer_en_ctrl = 2'b0;
	 data_arr3_datain_ctrl = 1'b0;
	 data_arr4_writer_en_ctrl = 2'b0;
	 data_arr4_datain_ctrl = 1'b0;
	 cacheline_out_ctrl = 2'b0;
	 ld_tag1 = 1'b0;
	 ld_tag2 = 1'b0;
	 ld_tag3 = 1'b0;
	 ld_tag4 = 1'b0;
	 ld_dirty1 = 1'b0;
	 dirty1_in = 1'b0;
	 ld_dirty2 = 1'b0;
	 dirty2_in = 1'b0;
	 ld_dirty3 = 1'b0;
	 dirty3_in = 1'b0;
	 ld_dirty4 = 1'b0;
	 dirty4_in = 1'b0;
	 ld_lru = 1'b0;
	 lru_in = 3'b000;
	 ld_valid1 = 1'b0;
	 valid1_in = 1'b0;
	 ld_valid2 = 1'b0;
	 valid2_in = 1'b0;
	 ld_valid3 = 1'b0;
	 valid3_in = 1'b0;
	 ld_valid4 = 1'b0;
	 valid4_in = 1'b0;
	 pmem_addr = {mem_address[31:5], 5'd0};
endfunction

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 if(rst) 
	 begin
		state <= WAIT; 
	 end
	 else 
	 begin
		state <= next_state;
	 end
end

always_comb begin 
    set_defaults();
	case (state)
	
		READ_WRITE:
		begin
//			if(mem_read == 1'b1 && mem_write == 1'b0)
//			begin
				if(((tag1_out == mem_address[31:9] && valid1_out) | (tag2_out == mem_address[31:9] && valid2_out) | (tag3_out == mem_address[31:9] && valid3_out) | (tag4_out == mem_address[31:9] && valid4_out)))
				begin
					ld_lru = 1'b1;
					if((tag1_out == mem_address[31:9] && valid1_out))
					begin
						lru_in = {lru_out[2], 2'b0};
						cacheline_out_ctrl = 2'b00;
					end
					else if ((tag2_out == mem_address[31:9] && valid2_out))
					begin
						lru_in = {lru_out[2], 1'b1, 1'b0};
						cacheline_out_ctrl = 2'b01;
					end
					else if ((tag3_out == mem_address[31:9] && valid3_out))
					begin
						lru_in = {1'b0, lru_out[1], 1'b1};
						cacheline_out_ctrl = 2'b10;
					end
					else //if ((tag4_out == mem_address[31:9] && valid4_out))
					begin
						lru_in = {1'b1, lru_out[1], 1'b1};
						cacheline_out_ctrl = 2'b11;
					end
					mem_resp = 1'b1;
				end
		 end
		 
		 READ_MISS:
		 begin
//				else //if //(mem_address != '0)
//				begin
					if(valid1_out == 0)
					begin
						data_arr1_writer_en_ctrl = 2'b01;
						data_arr1_datain_ctrl = 1'b0;
						pmem_read = 1'b1;
					end
					else if(valid2_out == 0)
					begin
						data_arr2_writer_en_ctrl = 2'b01;
						data_arr2_datain_ctrl = 1'b0;
						pmem_read = 1'b1;
					end
					else if(valid3_out == 0)
					begin
						data_arr3_writer_en_ctrl = 2'b01;
						data_arr3_datain_ctrl = 1'b0;
						pmem_read = 1'b1;
					end
					else if(valid4_out == 0)
					begin
						data_arr4_writer_en_ctrl = 2'b01;
						data_arr4_datain_ctrl = 1'b0;
						pmem_read = 1'b1;
					end
					else
					begin
						if(lru_out == 3'b000 | lru_out == 3'b100)
						begin
							if(dirty2_out == 0)
							begin
								data_arr2_writer_en_ctrl = 2'b01;
								data_arr2_datain_ctrl = 1'b0;
								pmem_read = 1'b1;
							end
							else
							begin
								pmem_addr = {tag2_out, mem_address[8:5], 5'd0};
								cacheline_out_ctrl = 2'b01;
								pmem_write = 1'b1;
							end
						end
						else if(lru_out == 3'b010 | lru_out == 3'b110)
						begin
							if(dirty1_out == 0)
							begin
								data_arr1_writer_en_ctrl = 2'b01;
								data_arr1_datain_ctrl = 1'b0;
								pmem_read = 1'b1;
							end
							else
							begin
								pmem_addr = {tag1_out, mem_address[8:5], 5'd0};
								cacheline_out_ctrl = 2'b00;
								pmem_write = 1'b1;
							end
						end
						else if(lru_out == 3'b001 | lru_out == 3'b011)
						begin
							if(dirty4_out == 0)
							begin
								data_arr4_writer_en_ctrl = 2'b01;
								data_arr4_datain_ctrl = 1'b0;
								pmem_read = 1'b1;
							end
							else
							begin
								pmem_addr = {tag4_out, mem_address[8:5], 5'd0};
								cacheline_out_ctrl = 2'b11;
								pmem_write = 1'b1;
							end
						end
						else //if(lru_out == 3'b101 | lru_out == 3'b111)
						begin
							if(dirty3_out == 0)
							begin
								data_arr3_writer_en_ctrl = 2'b01;
								data_arr3_datain_ctrl = 1'b0;
								pmem_read = 1'b1;
							end
							else
							begin
								pmem_addr = {tag3_out, mem_address[8:5], 5'd0};
								cacheline_out_ctrl = 2'b10;
								pmem_write = 1'b1;
							end
						end
					end
				end
			//end
			
//			else //if(mem_read == 1'b0 && mem_write == 1'b1)// WRITE
//			begin
//				if((tag1_hit | tag2_hit | tag3_hit | tag4_hit))
//				begin
//					ld_lru = 1'b1;
//					if(tag1_hit)
//					begin
//						lru_in = {lru_out[2], 2'b0};
//						ld_dirty1 = 1'b1;
//						dirty1_in = 1'b1;
//						data_arr1_writer_en_ctrl = 2'b10;
//						data_arr1_datain_ctrl = 1'b1;
//					end
//					else if(tag2_hit)
//					begin
//						lru_in = {lru_out[2], 1'b1, 1'b0};
//						ld_dirty2 = 1'b1;
//						dirty2_in = 1'b1;
//						data_arr2_writer_en_ctrl = 2'b10;
//						data_arr2_datain_ctrl = 1'b1;
//					end
//					else if(tag3_hit)
//					begin
//						lru_in = {1'b0 ,lru_out[1], 2'b1};
//						ld_dirty3 = 1'b1;
//						dirty3_in = 1'b1;
//						data_arr3_writer_en_ctrl = 2'b10;
//						data_arr3_datain_ctrl = 1'b1;
//					end
//					else //if(tag4_hit)
//					begin
//						lru_in = {1'b1 ,lru_out[1], 2'b1};
//						ld_dirty4 = 1'b1;
//						dirty4_in = 1'b1;
//						data_arr4_writer_en_ctrl = 2'b10;
//						data_arr4_datain_ctrl = 1'b1;
//					end
//					mem_resp = 1'b1;
//				end
//				
//				else//WRITE_MISS
//				begin
//					if(valid1_out == 0)//need to read from mem for spatial locality
//					begin
//						data_arr1_writer_en_ctrl = 2'b01;
//						data_arr1_datain_ctrl = 1'b0;
//						pmem_read = 1'b1;
//					end
//					else if(valid2_out == 0)
//					begin
//						data_arr2_writer_en_ctrl = 2'b01;
//						data_arr2_datain_ctrl = 1'b0;
//						pmem_read = 1'b1;
//					end
//					else if(valid3_out == 0)
//					begin
//						data_arr3_writer_en_ctrl = 2'b01;
//						data_arr3_datain_ctrl = 1'b0;
//						pmem_read = 1'b1;
//					end
//					else if(valid4_out == 0)
//					begin
//						data_arr4_writer_en_ctrl = 2'b01;
//						data_arr4_datain_ctrl = 1'b0;
//						pmem_read = 1'b1;
//					end
//					else 
//					begin
//						if(lru_out == 3'b000 | lru_out == 3'b100)
//						begin
//							if(dirty2_out == 0)
//							begin
//								data_arr2_writer_en_ctrl = 2'b01;
//								data_arr2_datain_ctrl = 1'b0;
//								pmem_read = 1'b1;
//							end
//							else
//							begin
//								pmem_addr = {tag2_out, mem_address[8:5], 5'd0};
//								cacheline_out_ctrl = 2'b01;
//								pmem_write = 1'b1;
//							end
//						end
//						else if(lru_out == 3'b010 | lru_out == 3'b110)
//						begin
//							if(dirty1_out == 0)
//							begin
//								data_arr1_writer_en_ctrl = 2'b01;
//								data_arr1_datain_ctrl = 1'b0;
//								pmem_read = 1'b1;
//							end
//							else
//							begin
//								pmem_addr = {tag1_out, mem_address[8:5], 5'd0};
//								cacheline_out_ctrl = 2'b00;
//								pmem_write = 1'b1;
//							end
//						end
//						else if(lru_out == 3'b001 | lru_out == 3'b011)
//						begin
//							if(dirty4_out == 0)
//							begin
//								data_arr4_writer_en_ctrl = 2'b01;
//								data_arr4_datain_ctrl = 1'b0;
//								pmem_read = 1'b1;
//							end
//							else
//							begin
//								pmem_addr = {tag4_out, mem_address[8:5], 5'd0};
//								cacheline_out_ctrl = 2'b11;
//								pmem_write = 1'b1;
//							end
//						end
//						else //if(lru_out == 3'b101 | 3'111)
//						begin
//							if(dirty3_out == 0)
//							begin
//								data_arr3_writer_en_ctrl = 2'b01;
//								data_arr3_datain_ctrl = 1'b0;
//								pmem_read = 1'b1;
//							end
//							else
//							begin
//								pmem_addr = {tag3_out, mem_address[8:5], 5'd0};
//								cacheline_out_ctrl = 2'b10;
//								pmem_write = 1'b1;
//							end
//						end
//					end
//				end
//			end
		//end
	
		WRITE:
		begin
			if(((tag1_out == mem_address[31:9] && valid1_out) | (tag2_out == mem_address[31:9] && valid2_out) | (tag3_out == mem_address[31:9] && valid3_out) | (tag4_out == mem_address[31:9] && valid4_out)))
				begin
					ld_lru = 1'b1;
					if((tag1_out == mem_address[31:9] && valid1_out))
					begin
						lru_in = {lru_out[2], 2'b0};
						ld_dirty1 = 1'b1;
						dirty1_in = 1'b1;
						data_arr1_writer_en_ctrl = 2'b10;
						data_arr1_datain_ctrl = 1'b1;
					end
					else if((tag2_out == mem_address[31:9] && valid2_out))
					begin
						lru_in = {lru_out[2], 1'b1, 1'b0};
						ld_dirty2 = 1'b1;
						dirty2_in = 1'b1;
						data_arr2_writer_en_ctrl = 2'b10;
						data_arr2_datain_ctrl = 1'b1;
					end
					else if((tag3_out == mem_address[31:9] && valid3_out))
					begin
						lru_in = {1'b0 ,lru_out[1], 1'b1};
						ld_dirty3 = 1'b1;
						dirty3_in = 1'b1;
						data_arr3_writer_en_ctrl = 2'b10;
						data_arr3_datain_ctrl = 1'b1;
					end
					else //if((tag4_out == mem_address[31:9] && valid4_out))
					begin
						lru_in = {1'b1 ,lru_out[1], 1'b1};
						ld_dirty4 = 1'b1;
						dirty4_in = 1'b1;
						data_arr4_writer_en_ctrl = 2'b10;
						data_arr4_datain_ctrl = 1'b1;
					end
					mem_resp = 1'b1;
				end
				
				else//WRITE_MISS
				begin
					if(valid1_out == 0)//need to read from mem for spatial locality
					begin
						data_arr1_writer_en_ctrl = 2'b01;
						data_arr1_datain_ctrl = 1'b0;
						pmem_read = 1'b1;
					end
					else if(valid2_out == 0)
					begin
						data_arr2_writer_en_ctrl = 2'b01;
						data_arr2_datain_ctrl = 1'b0;
						pmem_read = 1'b1;
					end
					else if(valid3_out == 0)
					begin
						data_arr3_writer_en_ctrl = 2'b01;
						data_arr3_datain_ctrl = 1'b0;
						pmem_read = 1'b1;
					end
					else if(valid4_out == 0)
					begin
						data_arr4_writer_en_ctrl = 2'b01;
						data_arr4_datain_ctrl = 1'b0;
						pmem_read = 1'b1;
					end
					else 
					begin
						if(lru_out == 3'b000 | lru_out == 3'b100)
						begin
							if(dirty2_out == 0)
							begin
								data_arr2_writer_en_ctrl = 2'b01;
								data_arr2_datain_ctrl = 1'b0;
								pmem_read = 1'b1;
							end
							else
							begin
								pmem_addr = {tag2_out, mem_address[8:5], 5'd0};
								cacheline_out_ctrl = 2'b01;
								pmem_write = 1'b1;
							end
						end
						else if(lru_out == 3'b010 | lru_out == 3'b110)
						begin
							if(dirty1_out == 0)
							begin
								data_arr1_writer_en_ctrl = 2'b01;
								data_arr1_datain_ctrl = 1'b0;
								pmem_read = 1'b1;
							end
							else
							begin
								pmem_addr = {tag1_out, mem_address[8:5], 5'd0};
								cacheline_out_ctrl = 2'b00;
								pmem_write = 1'b1;
							end
						end
						else if(lru_out == 3'b001 | lru_out == 3'b011)
						begin
							if(dirty4_out == 0)
							begin
								data_arr4_writer_en_ctrl = 2'b01;
								data_arr4_datain_ctrl = 1'b0;
								pmem_read = 1'b1;
							end
							else
							begin
								pmem_addr = {tag4_out, mem_address[8:5], 5'd0};
								cacheline_out_ctrl = 2'b11;
								pmem_write = 1'b1;
							end
						end
						else //if(lru_out == 3'b101 | 3'111)
						begin
							if(dirty3_out == 0)
							begin
								data_arr3_writer_en_ctrl = 2'b01;
								data_arr3_datain_ctrl = 1'b0;
								pmem_read = 1'b1;
							end
							else
							begin
								pmem_addr = {tag3_out, mem_address[8:5], 5'd0};
								cacheline_out_ctrl = 2'b10;
								pmem_write = 1'b1;
							end
						end
					end
				end
		end
		
		
		READ_MEM:
		begin
			if(valid1_out == 0)
			begin
				ld_tag1 = 1'b1;
				ld_lru = 1'b1;
				lru_in = {lru_out[2], 2'b0};
				ld_valid1 = 1'b1;
				valid1_in = 1'b1;
				ld_dirty1 = 1'b1;
				dirty1_in = 1'b0;
				cacheline_out_ctrl = 2'b00;
				mem_resp = 1'b1;
			end
			else if(valid2_out == 0)
			begin
				ld_tag2 = 1'b1;
				ld_lru = 1'b1;
				lru_in = {lru_out[2], 1'b1, 1'b0};
				ld_valid2 = 1'b1;
				valid2_in = 1'b1;
				ld_dirty2 = 1'b1;
				dirty2_in = 1'b0;
				cacheline_out_ctrl = 2'b01;
				mem_resp = 1'b1;
			end
			else if(valid3_out == 0)
			begin
				ld_tag3 = 1'b1;
				ld_lru = 1'b1;
				lru_in = {1'b0, lru_out[1], 1'b1};
				ld_valid3 = 1'b1;
				valid3_in = 1'b1;
				ld_dirty3 = 1'b1;
				dirty3_in = 1'b0;
				cacheline_out_ctrl = 2'b10;
				mem_resp = 1'b1;
			end
			else if(valid4_out == 0)
			begin
				ld_tag4 = 1'b1;
				ld_lru = 1'b1;
				lru_in = {1'b1, lru_out[1], 1'b1};
				ld_valid4 = 1'b1;
				valid4_in = 1'b1;
				ld_dirty4 = 1'b1;
				dirty4_in = 1'b0;
				cacheline_out_ctrl = 2'b11;
				mem_resp = 1'b1;
			end
			else
			begin
				if(lru_out == 3'b000 | lru_out == 3'b100)
				begin
					ld_tag2 = 1'b1;
					ld_lru = 1'b1;
					lru_in = {lru_out[2], 1'b1, 1'b0};
					ld_valid2 = 1'b1;
					valid2_in = 1'b1;
					ld_dirty2 = 1'b1;
					dirty2_in = 1'b0;
					cacheline_out_ctrl = 2'b01;
					mem_resp = 1'b1;
				end
				else if(lru_out == 3'b010 | lru_out == 3'b110)
				begin
					ld_tag1 = 1'b1;
					ld_lru = 1'b1;
					lru_in = {lru_out[2], 2'b0};
					ld_valid1 = 1'b1;
					valid1_in = 1'b1;
					ld_dirty1 = 1'b1;
					dirty1_in = 1'b0;
					cacheline_out_ctrl = 2'b00;
					mem_resp = 1'b1;
				end
				else if(lru_out == 3'b001 | lru_out == 3'b011)
				begin
					ld_tag4 = 1'b1;
					ld_lru = 1'b1;
					lru_in = {1'b1, lru_out[1], 1'b1};
					ld_valid4 = 1'b1;
					valid4_in = 1'b1;
					ld_dirty4 = 1'b1;
					dirty4_in = 1'b0;
					cacheline_out_ctrl = 2'b11;
					mem_resp = 1'b1;
				end
				else //if(lru_out == 3'b101 | 3'111)
				begin
					ld_tag3 = 1'b1;
					ld_lru = 1'b1;
					lru_in = {1'b0, lru_out[1], 1'b1};
					ld_valid3 = 1'b1;
					valid3_in = 1'b1;
					ld_dirty3 = 1'b1;
					dirty3_in = 1'b0;
					cacheline_out_ctrl = 2'b10;
					mem_resp = 1'b1;
				end
			end
		end

		WRITE_CACHE:
		begin
			if(valid1_out == 0)
			begin
				ld_tag1 = 1'b1;
				ld_lru = 1'b1;
				lru_in = {lru_out[2], 2'b0};
				ld_valid1 = 1'b1;
				valid1_in = 1'b1;
				ld_dirty1 = 1'b1;
				dirty1_in = 1'b1;
				data_arr1_writer_en_ctrl = 2'b10;
				data_arr1_datain_ctrl = 1'b1;
				mem_resp = 1'b1;
			end
			else if(valid2_out == 0)
			begin
				ld_tag2 = 1'b1;
				ld_lru = 1'b1;
				lru_in = {lru_out[2], 1'b1, 1'b0};
				ld_valid2 = 1'b1;
				valid2_in = 1'b1;
				ld_dirty2 = 1'b1;
				dirty2_in = 1'b1;
				data_arr2_writer_en_ctrl = 2'b10;
				data_arr2_datain_ctrl = 1'b1;
				mem_resp = 1'b1;
			end
			else if(valid3_out == 0)
			begin
				ld_tag3 = 1'b1;
				ld_lru = 1'b1;
				lru_in = {1'b0, lru_out[1], 1'b1};
				ld_valid3 = 1'b1;
				valid3_in = 1'b1;
				ld_dirty3 = 1'b1;
				dirty3_in = 1'b1;
				data_arr3_writer_en_ctrl = 2'b10;
				data_arr3_datain_ctrl = 1'b1;
				mem_resp = 1'b1;
			end
			else if(valid4_out == 0)
			begin
				ld_tag4 = 1'b1;
				ld_lru = 1'b1;
				lru_in = {1'b1, lru_out[1], 1'b1};
				ld_valid4 = 1'b1;
				valid4_in = 1'b1;
				ld_dirty4 = 1'b1;
				dirty4_in = 1'b1;
				data_arr4_writer_en_ctrl = 2'b10;
				data_arr4_datain_ctrl = 1'b1;
				mem_resp = 1'b1;
			end
			else
			begin
				if(lru_out == 3'b000 | lru_out == 3'b100)
				begin
					ld_tag2 = 1'b1;
					ld_lru = 1'b1;
					lru_in = {lru_out[2], 1'b1, 1'b0};
					ld_valid2 = 1'b1;
					valid2_in = 1'b1;
					ld_dirty2 = 1'b1;
					dirty2_in = 1'b1;
					data_arr2_writer_en_ctrl = 2'b10;
					data_arr2_datain_ctrl = 1'b1;
					mem_resp = 1'b1;
				end
				else if(lru_out == 3'b010 | lru_out == 3'b110)
				begin
					ld_tag1 = 1'b1;
					ld_lru = 1'b1;
					lru_in = {lru_out[2], 2'b0};
					ld_valid1 = 1'b1;
					valid1_in = 1'b1;
					ld_dirty1 = 1'b1;
					dirty1_in = 1'b1;
					data_arr1_writer_en_ctrl = 2'b10;
					data_arr1_datain_ctrl = 1'b1;
					mem_resp = 1'b1;
				end
				else if(lru_out == 3'b001 | lru_out == 3'b011)
				begin
					ld_tag4 = 1'b1;
					ld_lru = 1'b1;
					lru_in = {1'b1, lru_out[1], 1'b1};
					ld_valid4 = 1'b1;
					valid4_in = 1'b1;
					ld_dirty4 = 1'b1;
					dirty4_in = 1'b1;
					data_arr4_writer_en_ctrl = 2'b10;
					data_arr4_datain_ctrl = 1'b1;
					mem_resp = 1'b1;
				end
				else //if(lru_out == 3'b101 | 3'b111)
				begin
					ld_tag3 = 1'b1;
					ld_lru = 1'b1;
					lru_in = {1'b0, lru_out[1], 1'b1};
					ld_valid3 = 1'b1;
					valid3_in = 1'b1;
					ld_dirty3 = 1'b1;
					dirty3_in = 1'b1;
					data_arr3_writer_en_ctrl = 2'b10;
					data_arr3_datain_ctrl = 1'b1;
					mem_resp = 1'b1;
				end
			end
		end	

		WRITE_MEM:
		begin
			if(lru_out == 3'b000 | lru_out == 3'b100)
			begin
				ld_tag2 = 1'b1;
				data_arr2_writer_en_ctrl = 2'b01;
				data_arr2_datain_ctrl = 1'b0;
				pmem_read = 1'b1;
			end
			else if(lru_out == 3'b010 | lru_out == 3'b110)
			begin
				ld_tag1 = 1'b1;
				data_arr1_writer_en_ctrl = 2'b01;
				data_arr1_datain_ctrl = 1'b0;
				pmem_read = 1'b1;
			end
			else if(lru_out == 3'b001 | lru_out == 3'b011)
			begin
				ld_tag4 = 1'b1;
				data_arr4_writer_en_ctrl = 2'b01;
				data_arr4_datain_ctrl = 1'b0;
				pmem_read = 1'b1;
			end
			else //if(lru_out == 3'b101 | 3'b111)
			begin
				ld_tag3 = 1'b1;
				data_arr3_writer_en_ctrl = 2'b01;
				data_arr3_datain_ctrl = 1'b0;
				pmem_read = 1'b1;
			end
		end

	endcase
end

always_comb begin
	unique case(state)
		
		WAIT:
		begin
			if(!(mem_read | mem_write))
				next_state = WAIT;
			else if(mem_read)
				next_state = READ_WRITE;
			else
				next_state = WRITE;
		end

		READ_WRITE:
		begin
			if(((tag1_out == mem_address[31:9] && valid1_out) | (tag2_out == mem_address[31:9] && valid2_out) | (tag3_out == mem_address[31:9] && valid3_out) | (tag4_out == mem_address[31:9] && valid4_out)) | (mem_address == '0))
				next_state = WAIT;
			else
				next_state = READ_MISS;
		end
				
		READ_MISS:
			begin
//				if(mem_read == 1)
//				begin
//					if (ROBToALL.flush_all)
//						next_state = WAIT;
					if((valid1_out == 0 | valid2_out == 0 | valid3_out == 0 | valid4_out == 0) && pmem_resp == 1)
						next_state = READ_MEM;
					else if((valid1_out == 0 | valid2_out == 0 | valid3_out == 0 | valid4_out == 0) && pmem_resp == 0)
						next_state = READ_MISS;
					else if(((lru_out == 3'b000 | lru_out == 3'b100) && dirty2_out == 1) | ((lru_out == 3'b010 | lru_out == 3'b110) && dirty1_out == 1) | ((lru_out == 3'b001 | lru_out == 3'b011) && dirty4_out == 1) 
					| ((lru_out == 3'b101 | 3'b111) && dirty3_out == 1) && pmem_resp == 1)
						next_state = WRITE_MEM;
					else if(((lru_out == 3'b000 | lru_out == 3'b100) && dirty2_out == 0) | ((lru_out == 3'b010 | lru_out == 3'b110) && dirty1_out == 0) | ((lru_out == 3'b001 | lru_out == 3'b011) && dirty4_out == 0) 
					| ((lru_out == 3'b101 | 3'b111) && dirty3_out == 0) && pmem_resp == 1)
						next_state = READ_MEM;
					else if(((lru_out == 3'b000 | lru_out == 3'b100) && dirty2_out == 0) | ((lru_out == 3'b010 | lru_out == 3'b110) && dirty1_out == 0) | ((lru_out == 3'b001 | lru_out == 3'b011) && dirty4_out == 0) 
					| ((lru_out == 3'b101 | 3'b111) && dirty3_out == 0) && pmem_resp == 0)
						next_state = READ_MISS;
//					else if(((lru_out == 3'b000 | lru_out == 3'b100) && dirty2_out == 1) | ((lru_out == 3'b010 | lru_out == 3'b110) && dirty1_out == 1) | ((lru_out == 3'b001 | lru_out == 3'b011) && dirty4_out == 1) 
//					| ((lru_out == 3'b101 | 3'b111) && dirty3_out == 1) && pmem_resp == 1)
//						next_state = WRITE_MEM;
					else if(((lru_out == 3'b000 | lru_out == 3'b100) && dirty2_out == 1) | ((lru_out == 3'b010 | lru_out == 3'b110) && dirty1_out == 1) | ((lru_out == 3'b001 | lru_out == 3'b011) && dirty4_out == 1) 
					| ((lru_out == 3'b101 | 3'b111) && dirty3_out == 1) && pmem_resp == 0)
						next_state = READ_MISS;
					else
						next_state = READ_MISS;
			end
		//end
			
			WRITE:
			begin
				if(((tag1_out == mem_address[31:9] && valid1_out) | (tag2_out == mem_address[31:9] && valid2_out) | (tag3_out == mem_address[31:9] && valid3_out) | (tag4_out == mem_address[31:9] && valid4_out)))
				next_state = WAIT;
				else 
				begin
					if((valid1_out == 0 | valid2_out == 0 | valid3_out == 0 | valid4_out == 0) && pmem_resp == 1)
						next_state = WRITE_CACHE;
					else if((valid1_out == 0 | valid2_out == 0 | valid3_out == 0 | valid4_out == 0) && pmem_resp == 0)
						next_state = WRITE;
					else if(((lru_out == 3'b000 | lru_out == 3'b100) && dirty2_out == 0) | ((lru_out == 3'b010 | lru_out == 3'b110) && dirty1_out == 0) | ((lru_out == 3'b001 | lru_out == 3'b011) && dirty4_out == 0) 
					| ((lru_out == 3'b101 | 3'b111) && dirty3_out == 0) && pmem_resp == 1)
						next_state = WRITE_CACHE;
					else if(((lru_out == 3'b000 | lru_out == 3'b100) && dirty2_out == 0) | ((lru_out == 3'b010 | lru_out == 3'b110) && dirty1_out == 0) | ((lru_out == 3'b001 | lru_out == 3'b011) && dirty4_out == 0) 
					| ((lru_out == 3'b101 | 3'b111) && dirty3_out == 0) && pmem_resp == 0)
						next_state = WRITE;
					else if(((lru_out == 3'b000 | lru_out == 3'b100) && dirty2_out == 1) | ((lru_out == 3'b010 | lru_out == 3'b110) && dirty1_out == 1) | ((lru_out == 3'b001 | lru_out == 3'b011) && dirty4_out == 1) 
					| ((lru_out == 3'b101 | 3'b111) && dirty3_out == 1) && pmem_resp == 1)
						next_state = WRITE_MEM;
					else if(((lru_out == 3'b000 | lru_out == 3'b100) && dirty2_out == 1) | ((lru_out == 3'b010 | lru_out == 3'b110) && dirty1_out == 1) | ((lru_out == 3'b001 | lru_out == 3'b011) && dirty4_out == 1) 
					| ((lru_out == 3'b101 | 3'b111) && dirty3_out == 1) && pmem_resp == 0)
						next_state = WRITE;
					else
						next_state = WRITE;
				end	
			end
		
		READ_MEM:
		begin
			next_state = WAIT;
		end

		WRITE_CACHE:
		begin
			next_state = WAIT;
		end

		WRITE_MEM:
		begin
			if(mem_write == 1 && pmem_resp == 1)
				next_state = WRITE_CACHE;
			else if(mem_write == 1 && pmem_resp == 0)
				next_state = WRITE_MEM;
			else if(mem_read == 1 && pmem_resp == 1)
				next_state = READ_MEM;
			else if(mem_read == 1 && pmem_resp == 0)
				next_state = WRITE_MEM;
			else
				next_state = WRITE_MEM;
		end
	
	endcase
end

endmodule : cache_control
