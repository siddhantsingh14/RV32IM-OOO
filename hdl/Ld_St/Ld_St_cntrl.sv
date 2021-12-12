import Ld_St_structs::*;
module mem_controller (
    input clk,
    input rst,

    input logic cir_q_empty,
    input logic ld_st_data_at_commit,
    input logic [31:0] mem_address_data_at_commit,
    input logic [7:0] src_rob_mem_address_data_at_commit,
    input logic valid_mem_address_data_at_commit,
    input logic [31:0] write_data_at_commit,
    input logic [7:0] src_rob_data_at_commit,
    input logic src_valid_data_at_commit,
    input logic [7:0] dest_rob_data_at_commit,
    input logic [3:0] funct3_data_at_commit,

    output logic commit,
    output Ld_St_structs::LD_ST_bus LD_ST_bus,
    /*memory*/
    output logic pmem_read,
    input logic [31:0] pmem_rdata,

    input logic pmem_resp,
    output logic [31:0] pmem_address,

    output logic pmem_write,
    output logic [31:0] pmem_wdata,
    output logic [3:0] mem_byte_enable
        /*memory*/
);

enum int unsigned {
    COMMIT_POLL,//wait for mem resp and for validity
    COMMIT_ACTION,
    COMMIT_LD,//commit here 
    COMMIT_ST,//commit here
	 WAIT,
	 WAIT2
} curr_state, next_state;

always_comb
begin
	if(pmem_resp)
	begin
		if(ld_st_data_at_commit)
		 begin//store
			  LD_ST_bus.valid = 1'b1;
			  LD_ST_bus.st = 1'b1;
			  LD_ST_bus.dest_rob = dest_rob_data_at_commit[4:0];
		 end
		 else//load
		 begin
			  LD_ST_bus.valid = 1'b1;
           LD_ST_bus.dest_rob = dest_rob_data_at_commit[4:0];
			  LD_ST_bus.st = 1'b0;
           case (funct3_data_at_commit)
                4'b0000://lb
                begin
                    case(mem_address_data_at_commit[1:0])
			            2'b00: LD_ST_bus.value = {{24{pmem_rdata[7]}}, pmem_rdata[7:0]};
			            2'b01: LD_ST_bus.value = {{24{pmem_rdata[15]}}, pmem_rdata[15:8]};
			            2'b10: LD_ST_bus.value = {{24{pmem_rdata[23]}}, pmem_rdata[23:16]};
			            2'b11: LD_ST_bus.value = {{24{pmem_rdata[31]}}, pmem_rdata[31:24]};
			        endcase
                end

                4'b0001://lh
                begin
                    case(mem_address_data_at_commit[1:0])
                        2'b00: LD_ST_bus.value = {{16{pmem_rdata[15]}}, pmem_rdata[15:0]};
                        2'b10: LD_ST_bus.value = {{16{pmem_rdata[31]}}, pmem_rdata[31:16]};
                        default: LD_ST_bus.value = '0;
                    endcase
                end

                default: LD_ST_bus.value = pmem_rdata;//lw
            endcase
		 end
	end
	else
	begin
		LD_ST_bus.valid = '0;
      LD_ST_bus.dest_rob = '0;
		LD_ST_bus.st = '0;
		LD_ST_bus.value = '0;
	end
end

always_comb
begin
    pmem_read = 1'b0;
    pmem_address = '0;
    pmem_write = 1'b0;
    pmem_wdata = '0;
    mem_byte_enable = 4'b1111;
    commit = 1'b0;
//    LD_ST_bus.valid = 1'b0;
//    LD_ST_bus.value = '0;
//    LD_ST_bus.dest_rob = '0;
//	 LD_ST_bus.st = 1'b0;

    unique case (curr_state)
        COMMIT_POLL:    ;

        COMMIT_ACTION:
        begin
            if(!cir_q_empty)
            begin
                if(ld_st_data_at_commit)
                begin//store
                    if(src_valid_data_at_commit && valid_mem_address_data_at_commit)
                    begin
                        pmem_write = 1'b1;
                        // pmem_wdata = write_data_at_commit;
                        pmem_address = {mem_address_data_at_commit[31:2], 2'b00};
                        case(funct3_data_at_commit)
                        4'b0000: begin
                            mem_byte_enable = {4'b0001 << mem_address_data_at_commit[1:0]};
                            unique case(mem_address_data_at_commit[1:0])
                                2'b00: pmem_wdata = write_data_at_commit;
                                2'b01: pmem_wdata = write_data_at_commit<<8;
                                2'b10: pmem_wdata = write_data_at_commit<<16;
                                2'b11: pmem_wdata = write_data_at_commit<<24;
                            endcase
                        end
                        4'b0001: begin
                            mem_byte_enable = {4'b0011 << mem_address_data_at_commit[1:0]};
                            unique case(mem_address_data_at_commit[1:0])
                                2'b00: pmem_wdata = write_data_at_commit;
                                2'b01: pmem_wdata = write_data_at_commit<<16;
                            endcase
                        end
                        4'b0010: begin
                            mem_byte_enable = '1;
                            pmem_wdata = write_data_at_commit;
                        end
                        endcase
                    end
                    else
                    begin
                        pmem_write = 1'b0;
                        pmem_wdata = '0;
                        pmem_address = '0;
                    end
                end
                else//load
                begin
                    if(valid_mem_address_data_at_commit)
                    begin
                        pmem_read = 1'b1;
                        pmem_address = {mem_address_data_at_commit[31:2], 2'b00};
                    end
                    else
                    begin
                        pmem_read = 1'b0;
                        pmem_address = '0;
                    end
                end
            end
            else
            begin
                pmem_read = 1'b0;
                pmem_address = '0;
                pmem_write = 1'b0;
                pmem_wdata = '0;
            end
        end

        COMMIT_ST:
        begin
            commit = 1'b1;
            pmem_write = 1'b0;
            pmem_wdata = '0;
            pmem_address = '0;
//            LD_ST_bus.valid = 1'b1;
//            LD_ST_bus.st = 1'b1;
        end

        COMMIT_LD:
        begin
            commit = 1'b1;
            pmem_read = 1'b0;
            pmem_address = '0;
//            LD_ST_bus.valid = 1'b1;
//            LD_ST_bus.dest_rob = dest_rob_data_at_commit[4:0];
//			   LD_ST_bus.st = 1'b0;
//            case (funct3_data_at_commit)
//                4'b0000://lb
//                begin
//                    case(mem_address_data_at_commit[1:0])
//			            2'b00: LD_ST_bus.value = {{24{pmem_rdata[7]}}, pmem_rdata[7:0]};
//			            2'b01: LD_ST_bus.value = {{24{pmem_rdata[15]}}, pmem_rdata[15:8]};
//			            2'b10: LD_ST_bus.value = {{24{pmem_rdata[23]}}, pmem_rdata[23:16]};
//			            2'b11: LD_ST_bus.value = {{24{pmem_rdata[31]}}, pmem_rdata[31:24]};
//			        endcase
//                end
//
//                4'b0001://lh
//                begin
//                    case(mem_address_data_at_commit[1:0])
//                        2'b00: LD_ST_bus.value = {{16{pmem_rdata[15]}}, pmem_rdata[15:0]};
//                        2'b10: LD_ST_bus.value = {{16{pmem_rdata[31]}}, pmem_rdata[31:16]};
//                        default: LD_ST_bus.value = '0;
//                    endcase
//                end
//
//                default: LD_ST_bus.value = pmem_rdata;//lw
//            endcase
        end

    endcase
end

always_comb
begin
    unique case (curr_state)
        COMMIT_POLL:
        begin
            if(!cir_q_empty)
            // begin
                // if(ld_st_data_at_commit)
                // begin//store
                    // if(src_valid_data_at_commit && pmem_resp && valid_mem_address_data_at_commit)
                next_state = COMMIT_ACTION;
            else
                next_state = COMMIT_POLL;
                // end
                // else//load
            //     begin
            //         if(pmem_resp && valid_mem_address_data_at_commit)
            //             next_state = COMMIT_ACTION;
            //         else
            //             next_state = COMMIT_POLL;
            //     end
            // end
            // else
            //     next_state = COMMIT_POLL;
        end

        COMMIT_ACTION:
        begin
            if(!cir_q_empty)
            begin
                if(ld_st_data_at_commit)
                begin//store
                    if(src_valid_data_at_commit && pmem_resp && valid_mem_address_data_at_commit)
                        next_state = COMMIT_ST;
                    else
                        next_state = COMMIT_ACTION;
                end
                else//load
                begin
                    if(pmem_resp && valid_mem_address_data_at_commit)
                        next_state = COMMIT_LD;
                    else
                        next_state = COMMIT_ACTION;
                end
            end
            else
                next_state = COMMIT_POLL;
        end
		  
        COMMIT_ST:
            next_state = WAIT;

        COMMIT_LD:
            next_state = WAIT;
				
		  WAIT:
				next_state = WAIT2;
			
		  WAIT2:
				next_state = COMMIT_POLL;

    endcase
end


always_ff @(posedge clk )
begin
    if (rst)
        curr_state <= COMMIT_POLL;
    else
        curr_state <= next_state;
end

endmodule : mem_controller