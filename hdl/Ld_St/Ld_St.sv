import Ld_St_structs::*;
import rv_structs::*;
import rob_entry_structs::*;

module Ld_St(
    input clk,
    input rst,

    input Ld_St_structs::IQtoLD_ST IQtoLD_ST, 

    input rv_structs::data_bus bus[5],
    input Ld_St_structs::LD_ST_bus LD_ST_bus,//bus from ld_st unit
    input rv_structs::data_bus_ld_st data_bus_ld_st,//ALU bus ONLY for mem address
   input rv_structs::data_bus_CMP data_bus_CMP,
    input rob_entry_structs::rob_to_regfile rob_to_regfile,
    input logic commit,//from controller

    output logic cir_q_full, cir_q_empty,
    output logic ld_st_data_at_commit,
    output logic [31:0] mem_address_data_at_commit,
    output logic [7:0] src_rob_mem_address_data_at_commit,//mask 3
    output logic valid_mem_address_data_at_commit,
    output logic [31:0] write_data_at_commit,
    output logic [7:0] src_rob_data_at_commit,//mask 3
    output logic src_valid_data_at_commit,
    output logic [7:0] dest_rob_data_at_commit,//mask 3
    output logic [3:0] funct3_data_at_commit
);

// localparam entry_size = 2**cir_q_offset;
// localparam num_entries = 2**cir_q_index;

localparam LD_ST_cir_q_offset = 0;
localparam LD_ST_cir_q_index = 5;

localparam mem_addr_cir_q_offset = 5;
localparam mem_addr_cir_q_index = 5;

localparam mem_addr_src_cir_q_offset = 3;//check
localparam mem_addr_src_cir_q_index = 5;

localparam valid_mem_address_data_cir_q_offset = 0;
localparam valid_mem_address_data_cir_q_index = 5;

localparam write_data_cir_q_offset = 5;
localparam write_data_cir_q_index = 5;

localparam src_rob_data_cir_q_offset = 3;//check
localparam src_rob_data_cir_q_index = 5;

localparam valid_data_cir_q_offset = 0;
localparam valid_data_cir_q_index = 5;

localparam des_rob_data_cir_q_offset = 3;//check
localparam des_rob_data_cir_q_index = 5;

localparam funct3_data_cir_q_offset = 2;//check
localparam funct3_cir_q_index = 5;

Ld_St_structs::LD_ST_cirq LD_ST_cirq;
Ld_St_structs::mem_address_cirq mem_address_cirq;
Ld_St_structs::src_rob_mem_address_cirq src_rob_mem_address_cirq;
Ld_St_structs::valid_mem_address_cirq valid_mem_address_cirq;
Ld_St_structs::write_data_cirq write_data_cirq;
Ld_St_structs::src_rob_cirq src_rob_cirq;
Ld_St_structs::valid_cirq valid_cirq;
Ld_St_structs::dest_rob_cirq dest_rob_cirq;
Ld_St_structs::funct3_cirq funct3_cirq;

Ld_St_structs::look_up_rob look_up_src[8];
Ld_St_structs::output_look_up_rob output_look_up_src[8];
Ld_St_structs::look_up_valid look_up_valid_src[8];
Ld_St_structs::output_look_up_valid output_look_up_valid_src[8];
Ld_St_structs::look_up_rob look_up_mem_addr;
Ld_St_structs::output_look_up_rob output_look_up_mem_addr;
Ld_St_structs::look_up_valid look_up_valid_mem_addr;
Ld_St_structs::output_look_up_valid output_look_up_valid_mem_addr;
Ld_St_structs::update_32 update_write_data[8];
Ld_St_structs::update_1 update_valid[8];
Ld_St_structs::update_32 update_mem_address;
Ld_St_structs::update_1 update_valid_mem_address;

Ld_St_structs::buffer_bus buffer_bus[9];

assign cir_q_full = LD_ST_cirq.cir_q_full;
assign cir_q_empty = LD_ST_cirq.cir_q_empty;

always_ff @(posedge clk)
begin
    if(rst)
    begin
        // LD_ST_cirq.issue <= '0;
        // LD_ST_cirq.commit <= '0;
        // LD_ST_cirq.datain_issue <= '0;
        // mem_address_cirq.issue <= '0;
        // mem_address_cirq.commit <= '0;
        // mem_address_cirq.datain_issue <= '0;
        // src_rob_mem_address_cirq.issue <= '0;
        // src_rob_mem_address_cirq.commit <= '0;
        // src_rob_mem_address_cirq.datain_issue <= '0;
        // valid_mem_address_cirq.issue <= '0;
        // valid_mem_address_cirq.commit <= '0;
        // valid_mem_address_cirq.datain_issue <= '0;
        // write_data_cirq.issue <= '0;
        // write_data_cirq.commit <= '0;
        // write_data_cirq.datain_issue <= '0;
        // src_rob_cirq.issue <= '0;
        // src_rob_cirq.commit <= '0;
        // src_rob_cirq.datain_issue <= '0;
        // valid_cirq.issue <= '0;
        // valid_cirq.commit <= '0;
        // valid_cirq.datain_issue <= '0;
        // dest_rob_cirq.issue <= '0;
        // dest_rob_cirq.commit <= '0;
        // dest_rob_cirq.datain_issue <= '0;//
        // funct3_cirq.issue <= '0;
        // funct3_cirq.commit <= '0;
        // funct3_cirq.datain_issue <= '0;
        for(int i = 0; i < 8; i++)
        begin
            look_up_src[i].rob_idx <= '0;
            look_up_src[i].valid <= '0;
            look_up_valid_src[i].value <= '0;
            look_up_valid_src[i].valid <= '0;
            buffer_bus[i].data <= '0;
            buffer_bus[i].valid <= '0;
        end
		  look_up_mem_addr.rob_idx <= '0;
		  look_up_mem_addr.valid <= '0;
	     look_up_valid_mem_addr.value <= '0;
		  look_up_valid_mem_addr.valid <= '0;
		  buffer_bus[8].data <= '0;
        buffer_bus[8].valid <= '0;

    end
    else
    begin
        // if(IQtoLD_ST.issue)	//issue is not working
        // begin
        //     LD_ST_cirq.issue <= IQtoLD_ST.issue;
        //     mem_address_cirq.issue <= IQtoLD_ST.issue;
        //     src_rob_mem_address_cirq.issue <= IQtoLD_ST.issue;
        //     valid_mem_address_cirq.issue <= IQtoLD_ST.issue;
        //     write_data_cirq.issue <= IQtoLD_ST.issue;
        //     src_rob_cirq.issue <= IQtoLD_ST.issue;
        //     valid_cirq.issue <= IQtoLD_ST.issue;
        //     dest_rob_cirq.issue <= IQtoLD_ST.issue;
        //     funct3_cirq.issue <= IQtoLD_ST.issue;

        //     LD_ST_cirq.datain_issue <= IQtoLD_ST.ld_st;
        //     mem_address_cirq.datain_issue <= IQtoLD_ST.mem_addr;
        //     src_rob_mem_address_cirq.datain_issue <= {3'd0, IQtoLD_ST.src_rob_mem_addr};
        //     valid_mem_address_cirq.datain_issue <= IQtoLD_ST.valid_src_mem_addr;
        //     write_data_cirq.datain_issue <= IQtoLD_ST.write_data;
        //     src_rob_cirq.datain_issue <= {3'd0, IQtoLD_ST.src_rob_write_data};
        //     valid_cirq.datain_issue <= IQtoLD_ST.src_valid_write_data;
        //     dest_rob_cirq.datain_issue <= {3'd0, IQtoLD_ST.dest_rob};
        //     funct3_cirq.datain_issue <= {1'b0, IQtoLD_ST.funct3};
        // end
        // else if(~IQtoLD_ST.issue)
        // begin
        //     LD_ST_cirq.issue <= '0;
        //     mem_address_cirq.issue <= '0;
        //     src_rob_mem_address_cirq.issue <= '0;
        //     valid_mem_address_cirq.issue <= '0;
        //     write_data_cirq.issue <= '0;
        //     src_rob_cirq.issue <= '0;
        //     valid_cirq.issue <= '0;
        //     dest_rob_cirq.issue <= '0;
        //     funct3_cirq.issue <= '0;

        //     LD_ST_cirq.datain_issue <= '0;
        //     mem_address_cirq.datain_issue <= '0;
        //     src_rob_mem_address_cirq.datain_issue <= '0;
        //     valid_mem_address_cirq.datain_issue <= '0;
        //     write_data_cirq.datain_issue <= '0;
        //     src_rob_cirq.datain_issue <= '0;
        //     valid_cirq.datain_issue <= '0;
        //     dest_rob_cirq.datain_issue <= '0;
        //     funct3_cirq.datain_issue <= '0;
        // end

        if(bus[0].valid)
        begin
            buffer_bus[0].data <= bus[0].value;
            buffer_bus[0].valid <= bus[0].valid;
            look_up_src[0].rob_idx <= {3'd0, bus[0].dest_rob};
            look_up_src[0].valid <= bus[0].valid;
            look_up_valid_src[0].value <= 1'b1;
            look_up_valid_src[0].valid <= 1'b1;
            // look_up_mem_addr[0].rob_idx <= {3'd0, bus[0].dest_rob};
            // look_up_mem_addr[0].valid <= bus[0].valid;
            // look_up_valid_mem_addr[0].value <= 1'b1;
            // look_up_valid_mem_addr[0].valid <= 1'b1;
        end
        else if(~bus[0].valid)
        begin
            buffer_bus[0].data <= '0;
            buffer_bus[0].valid <= '0;
            look_up_src[0].rob_idx <= '0;
            look_up_src[0].valid <= '0;
            look_up_valid_src[0].value <= '0;
            look_up_valid_src[0].valid <= '0;
            // look_up_mem_addr[0].rob_idx <= '0;
            // look_up_mem_addr[0].valid <= '0;
            // look_up_valid_mem_addr[0].value <= '0;
            // look_up_valid_mem_addr[0].valid <= '0;
        end

        if(bus[1].valid)
        begin
            buffer_bus[1].data <= bus[1].value;
            buffer_bus[1].valid <= bus[1].valid;
            look_up_src[1].rob_idx <= {3'd0, bus[1].dest_rob};
            look_up_src[1].valid <= bus[1].valid;
            look_up_valid_src[1].value <= 1'b1;
            look_up_valid_src[1].valid <= 1'b1;
            // look_up_mem_addr[1].rob_idx <= {3'd0, bus[1].dest_rob};
            // look_up_mem_addr[1].valid <= bus[1].valid;
            // look_up_valid_mem_addr[1].value <= 1'b1;
            // look_up_valid_mem_addr[1].valid <= 1'b1;
        end
        else if(~bus[1].valid)
        begin
            buffer_bus[1].data <= '0;
            buffer_bus[1].valid <= '0;
            look_up_src[1].rob_idx <= '0;
            look_up_src[1].valid <= '0;
            look_up_valid_src[1].value <= '0;
            look_up_valid_src[1].valid <= '0;
            // look_up_mem_addr[1].rob_idx <= '0;
            // look_up_mem_addr[1].valid <= '0;
            // look_up_valid_mem_addr[1].value <= '0;
            // look_up_valid_mem_addr[1].valid <= '0;
        end

        if(bus[2].valid)
        begin
            buffer_bus[2].data <= bus[2].value;
            buffer_bus[2].valid <= bus[2].valid;
            look_up_src[2].rob_idx <= {3'd0, bus[2].dest_rob};
            look_up_src[2].valid <= bus[2].valid;
            look_up_valid_src[2].value <= 1'b1;
            look_up_valid_src[2].valid <= 1'b1;
            // look_up_mem_addr[2].rob_idx <= {3'd0, bus[2].dest_rob};
            // look_up_mem_addr[2].valid <= bus[2].valid;
            // look_up_valid_mem_addr[2].value <= 1'b1;
            // look_up_valid_mem_addr[2].valid <= 1'b1;
        end
        else if(~bus[2].valid)
        begin
            buffer_bus[2].data <= '0;
            buffer_bus[2].valid <= '0;
            look_up_src[2].rob_idx <= '0;
            look_up_src[2].valid <= '0;
            look_up_valid_src[2].value <= '0;
            look_up_valid_src[2].valid <= '0;
            // look_up_mem_addr[2].rob_idx <= '0;
            // look_up_mem_addr[2].valid <= '0;
            // look_up_valid_mem_addr[2].value <= '0;
            // look_up_valid_mem_addr[2].valid <= '0;
        end

        if(bus[3].valid)
        begin
            buffer_bus[3].data <= bus[3].value;
            buffer_bus[3].valid <= bus[3].valid;
            look_up_src[3].rob_idx <= {3'd0, bus[3].dest_rob};
            look_up_src[3].valid <= bus[3].valid;
            look_up_valid_src[3].value <= 1'b1;
            look_up_valid_src[3].valid <= 1'b1;
            // look_up_mem_addr[3].rob_idx <= {3'd0, bus[3].dest_rob};
            // look_up_mem_addr[3].valid <= bus[3].valid;
            // look_up_valid_mem_addr[3].value <= 1'b1;
            // look_up_valid_mem_addr[3].valid <= 1'b1;
        end
        else if(~bus[3].valid)
        begin
            buffer_bus[3].data <= '0;
            buffer_bus[3].valid <= '0;
            look_up_src[3].rob_idx <= '0;
            look_up_src[3].valid <= '0;
            look_up_valid_src[3].value <= '0;
            look_up_valid_src[3].valid <= '0;
            // look_up_mem_addr[3].rob_idx <= '0;
            // look_up_mem_addr[3].valid <= '0;
            // look_up_valid_mem_addr[3].value <= '0;
            // look_up_valid_mem_addr[3].valid <= '0;
        end

        if(bus[4].valid)
        begin
            buffer_bus[4].data <= bus[4].value;
            buffer_bus[4].valid <= bus[4].valid;
            look_up_src[4].rob_idx <= {3'd0, bus[4].dest_rob};
            look_up_src[4].valid <= bus[4].valid;
            look_up_valid_src[4].value <= 1'b1;
            look_up_valid_src[4].valid <= 1'b1;
            // look_up_mem_addr[4].rob_idx <= {3'd0, bus[4].dest_rob};
            // look_up_mem_addr[4].valid <= bus[4].valid;
            // look_up_valid_mem_addr[4].value <= 1'b1;
            // look_up_valid_mem_addr[4].valid <= 1'b1;
        end
        else if(~bus[4].valid)
        begin
            buffer_bus[4].data <= '0;
            buffer_bus[4].valid <= '0;
            look_up_src[4].rob_idx <= '0;
            look_up_src[4].valid <= '0;
            look_up_valid_src[4].value <= '0;
            look_up_valid_src[4].valid <= '0;
            // look_up_mem_addr[4].rob_idx <= '0;
            // look_up_mem_addr[4].valid <= '0;
            // look_up_valid_mem_addr[4].value <= '0;
            // look_up_valid_mem_addr[4].valid <= '0;
        end
        
        if(LD_ST_bus.valid)
        begin
            buffer_bus[5].data <= LD_ST_bus.value;
            buffer_bus[5].valid <= LD_ST_bus.valid;
            look_up_src[5].rob_idx <= {3'd0, LD_ST_bus.dest_rob};
            look_up_src[5].valid <= LD_ST_bus.valid;
            look_up_valid_src[5].value <= 1'b1;
            look_up_valid_src[5].valid <= 1'b1;
            // look_up_mem_addr[5].rob_idx <= {3'd0, LD_ST_bus.dest_rob};
            // look_up_mem_addr[5].valid <= LD_ST_bus.valid;
            // look_up_valid_mem_addr[5].value <= 1'b1;
            // look_up_valid_mem_addr[5].valid <= 1'b1;
        end
        else if(~LD_ST_bus.valid)
        begin
            buffer_bus[5].data <= '0;
            buffer_bus[5].valid <= '0;
            look_up_src[5].rob_idx <= '0;
            look_up_src[5].valid <= '0;
            look_up_valid_src[5].value <= '0;
            look_up_valid_src[5].valid <= '0;
            // look_up_mem_addr[5].rob_idx <= '0;
            // look_up_mem_addr[5].valid <= '0;
            // look_up_valid_mem_addr[5].value <= '0;
            // look_up_valid_mem_addr[5].valid <= '0;
        end

        if(data_bus_CMP.valid)
        begin
            buffer_bus[6].data <= data_bus_CMP.value;
            buffer_bus[6].valid <= data_bus_CMP.valid;
            look_up_src[6].rob_idx <= {3'd0, data_bus_CMP.dest_rob};
            look_up_src[6].valid <= data_bus_CMP.valid;
            look_up_valid_src[6].value <= 1'b1;
            look_up_valid_src[6].valid <= 1'b1;
            // look_up_mem_addr[5].rob_idx <= {3'd0, LD_ST_bus.dest_rob};
            // look_up_mem_addr[5].valid <= LD_ST_bus.valid;
            // look_up_valid_mem_addr[5].value <= 1'b1;
            // look_up_valid_mem_addr[5].valid <= 1'b1;
        end
        else if(~data_bus_CMP.valid)
        begin
            buffer_bus[6].data <= '0;
            buffer_bus[6].valid <= '0;
            look_up_src[6].rob_idx <= '0;
            look_up_src[6].valid <= '0;
            look_up_valid_src[6].value <= '0;
            look_up_valid_src[6].valid <= '0;
            // look_up_mem_addr[5].rob_idx <= '0;
            // look_up_mem_addr[5].valid <= '0;
            // look_up_valid_mem_addr[5].value <= '0;
            // look_up_valid_mem_addr[5].valid <= '0;
        end

        if(rob_to_regfile.valid)
        begin
            buffer_bus[7].data <= rob_to_regfile.value;
            buffer_bus[7].valid <= rob_to_regfile.valid;
            look_up_src[7].rob_idx <= {3'd0, rob_to_regfile.rob_idx};
            look_up_src[7].valid <= rob_to_regfile.valid;
            look_up_valid_src[7].value <= 1'b1;
            look_up_valid_src[7].valid <= 1'b1;
            // look_up_mem_addr[5].rob_idx <= {3'd0, LD_ST_bus.dest_rob};
            // look_up_mem_addr[5].valid <= LD_ST_bus.valid;
            // look_up_valid_mem_addr[5].value <= 1'b1;
            // look_up_valid_mem_addr[5].valid <= 1'b1;
        end
        else if(~rob_to_regfile.valid)
        begin
            buffer_bus[7].data <= '0;
            buffer_bus[7].valid <= '0;
            look_up_src[7].rob_idx <= '0;
            look_up_src[7].valid <= '0;
            look_up_valid_src[7].value <= '0;
            look_up_valid_src[7].valid <= '0;
            // look_up_mem_addr[5].rob_idx <= '0;
            // look_up_mem_addr[5].valid <= '0;
            // look_up_valid_mem_addr[5].value <= '0;
            // look_up_valid_mem_addr[5].valid <= '0;
        end

        if(data_bus_ld_st.valid)
        begin
            buffer_bus[8].data <= data_bus_ld_st.value;
            buffer_bus[8].valid <= data_bus_ld_st.valid;
            look_up_mem_addr.rob_idx <= {3'd0, data_bus_ld_st.dest_rob};
            look_up_mem_addr.valid <= data_bus_ld_st.valid;
            look_up_valid_mem_addr.value <= 1'b1;
            look_up_valid_mem_addr.valid <= 1'b1;
        end
        else if(~data_bus_ld_st.valid)
        begin
            buffer_bus[8].data <= '0;
            buffer_bus[8].valid <= '0;
            look_up_mem_addr.rob_idx <= '0;
            look_up_mem_addr.valid <= '0;
            look_up_valid_mem_addr.value <= '0;
            look_up_valid_mem_addr.valid <= '0;
        end

        // if(commit)
        // begin
        //     LD_ST_cirq.commit <= 1'b1;
        //     mem_address_cirq.commit <= 1'b1;
        //     src_rob_mem_address_cirq.commit <= 1'b1;
        //     valid_mem_address_cirq.commit <= 1'b1;
        //     write_data_cirq.commit <= 1'b1;
        //     src_rob_cirq.commit <= 1'b1;
        //     valid_cirq.commit <= 1'b1;
        //     dest_rob_cirq.commit <= 1'b1;
        //     funct3_cirq.commit <= 1'b1;
        // end
		//   else if(~commit)
		//   begin
		// 	LD_ST_cirq.commit <= 1'b0;
        //     mem_address_cirq.commit <= 1'b0;
        //     src_rob_mem_address_cirq.commit <= 1'b0;
        //     valid_mem_address_cirq.commit <= 1'b0;
        //     write_data_cirq.commit <= 1'b0;
        //     src_rob_cirq.commit <= 1'b0;
        //     valid_cirq.commit <= 1'b0;
        //     dest_rob_cirq.commit <= 1'b0;
        //     funct3_cirq.commit <= 1'b0;
		//   end
    end
end

always_comb
begin

    LD_ST_cirq.issue = '0;
        LD_ST_cirq.commit = '0;
        LD_ST_cirq.datain_issue = '0;
        mem_address_cirq.issue = '0;
        mem_address_cirq.commit = '0;
        mem_address_cirq.datain_issue = '0;
        src_rob_mem_address_cirq.issue = '0;
        src_rob_mem_address_cirq.commit = '0;
        src_rob_mem_address_cirq.datain_issue = '0;
        valid_mem_address_cirq.issue = '0;
        valid_mem_address_cirq.commit = '0;
        valid_mem_address_cirq.datain_issue = '0;
        write_data_cirq.issue = '0;
        write_data_cirq.commit = '0;
        write_data_cirq.datain_issue = '0;
        src_rob_cirq.issue = '0;
        src_rob_cirq.commit = '0;
        src_rob_cirq.datain_issue = '0;
        valid_cirq.issue = '0;
        valid_cirq.commit = '0;
        valid_cirq.datain_issue = '0;
        dest_rob_cirq.issue = '0;
        dest_rob_cirq.commit = '0;
        dest_rob_cirq.datain_issue = '0;//
        funct3_cirq.issue = '0;
        funct3_cirq.commit = '0;
        funct3_cirq.datain_issue = '0;

    if(IQtoLD_ST.issue)	//issue is not working
        begin
            LD_ST_cirq.issue = IQtoLD_ST.issue;
            mem_address_cirq.issue = IQtoLD_ST.issue;
            src_rob_mem_address_cirq.issue = IQtoLD_ST.issue;
            valid_mem_address_cirq.issue = IQtoLD_ST.issue;
            write_data_cirq.issue = IQtoLD_ST.issue;
            src_rob_cirq.issue = IQtoLD_ST.issue;
            valid_cirq.issue = IQtoLD_ST.issue;
            dest_rob_cirq.issue = IQtoLD_ST.issue;
            funct3_cirq.issue = IQtoLD_ST.issue;

            LD_ST_cirq.datain_issue = IQtoLD_ST.ld_st;
            mem_address_cirq.datain_issue = IQtoLD_ST.mem_addr;
            src_rob_mem_address_cirq.datain_issue = {3'd0, IQtoLD_ST.src_rob_mem_addr};
            valid_mem_address_cirq.datain_issue = IQtoLD_ST.valid_src_mem_addr;
            write_data_cirq.datain_issue = IQtoLD_ST.write_data;
            src_rob_cirq.datain_issue = {3'd0, IQtoLD_ST.src_rob_write_data};
            valid_cirq.datain_issue = IQtoLD_ST.src_valid_write_data;
            dest_rob_cirq.datain_issue = {3'd0, IQtoLD_ST.dest_rob};
            funct3_cirq.datain_issue = {1'b0, IQtoLD_ST.funct3};
        end
        else// if(~IQtoLD_ST.issue)
        begin
            LD_ST_cirq.issue = '0;
            mem_address_cirq.issue = '0;
            src_rob_mem_address_cirq.issue = '0;
            valid_mem_address_cirq.issue = '0;
            write_data_cirq.issue = '0;
            src_rob_cirq.issue = '0;
            valid_cirq.issue = '0;
            dest_rob_cirq.issue = '0;
            funct3_cirq.issue = '0;

            LD_ST_cirq.datain_issue = '0;
            mem_address_cirq.datain_issue = '0;
            src_rob_mem_address_cirq.datain_issue = '0;
            valid_mem_address_cirq.datain_issue = '0;
            write_data_cirq.datain_issue = '0;
            src_rob_cirq.datain_issue = '0;
            valid_cirq.datain_issue = '0;
            dest_rob_cirq.datain_issue = '0;
            funct3_cirq.datain_issue = '0;
        end

    if(commit)
        begin
            LD_ST_cirq.commit = 1'b1;
            mem_address_cirq.commit = 1'b1;
            src_rob_mem_address_cirq.commit = 1'b1;
            valid_mem_address_cirq.commit = 1'b1;
            write_data_cirq.commit = 1'b1;
            src_rob_cirq.commit = 1'b1;
            valid_cirq.commit = 1'b1;
            dest_rob_cirq.commit = 1'b1;
            funct3_cirq.commit = 1'b1;
        end
	else //if(~commit)
		  begin
			LD_ST_cirq.commit = 1'b0;
            mem_address_cirq.commit = 1'b0;
            src_rob_mem_address_cirq.commit = 1'b0;
            valid_mem_address_cirq.commit = 1'b0;
            write_data_cirq.commit = 1'b0;
            src_rob_cirq.commit = 1'b0;
            valid_cirq.commit = 1'b0;
            dest_rob_cirq.commit = 1'b0;
            funct3_cirq.commit = 1'b0;
		  end
end

always_comb
begin
    for(int i = 0; i <= 7; i++)
    begin
        if(output_look_up_src[i].valid && output_look_up_valid_src[i].valid)
        begin
            update_write_data[i].valid = output_look_up_src[i].valid;
            update_write_data[i].update_data = buffer_bus[i].data;

            update_valid[i].valid = output_look_up_src[i].valid;
            update_valid[i].update_data = 1'b1;
            for(int j = 0; j < 32; j++)
            begin
                if(output_look_up_src[i].que_write_idx[j] == 1'b1 && output_look_up_valid_src[i].que_write_idx[j] == 1'b0)
                begin
                    update_write_data[i].que_write_idx[j] = 1'b1;
                    update_valid[i].que_write_idx[j] = 1'b1;
                end
                else
                begin
                    update_write_data[i].que_write_idx[j] = 1'b0;
                    update_valid[i].que_write_idx[j] = 1'b0;
                end
            end
        end
        else
        begin
            update_write_data[i].valid = '0;
            update_write_data[i].update_data = '0;
			update_write_data[i].que_write_idx = '0;
            update_valid[i].que_write_idx = '0;
            update_valid[i].valid = '0;
            update_valid[i].update_data = '0;
        end

        // if(output_look_up_mem_addr[i].valid && output_look_up_valid_mem_addr[i].valid)
        // begin
        //     update_mem_address[i].valid = output_look_up_mem_addr[i].valid;
        //     update_mem_address[i].update_data = buffer_bus[i].data;

        //     update_valid_mem_address[i].valid = output_look_up_mem_addr[i].valid;
        //     update_valid_mem_address[i].update_data = 1'b1;
        //     for(int j = 0; j < 32; j++)
        //     begin
        //         if(output_look_up_mem_addr[i].que_write_idx[j] == 1'b1 && output_look_up_valid_mem_addr[i].que_write_idx[j] == 1'b0)
        //         begin
        //             update_mem_address[i].que_write_idx[j] = 1'b1;
        //             update_valid_mem_address[i].que_write_idx[j] = 1'b1;
        //         end
        //         else
        //         begin
        //             update_mem_address[i].que_write_idx[j] = 1'b0;
        //             update_valid_mem_address[i].que_write_idx[j] = 1'b0;
        //         end
        //     end
        // end
		//   else
        // begin
        //     update_mem_address[i].valid = '0;
        //     update_mem_address[i].update_data = '0;
		// 		update_mem_address[i].que_write_idx = '0;
        //     update_valid_mem_address[i].que_write_idx = '0;
        //     update_valid_mem_address[i].valid = '0;
        //     update_valid_mem_address[i].update_data = '0;
        // end
    end
end

always_comb 
begin
    if(output_look_up_mem_addr.valid && output_look_up_valid_mem_addr.valid)
    begin
        update_mem_address.valid = output_look_up_mem_addr.valid;
        update_mem_address.update_data = buffer_bus[8].data;

        update_valid_mem_address.valid = output_look_up_mem_addr.valid;
        update_valid_mem_address.update_data = 1'b1;
        for(int j = 0; j < 32; j++)
        begin
            if(output_look_up_mem_addr.que_write_idx[j] == 1'b1 && output_look_up_valid_mem_addr.que_write_idx[j] == 1'b0)
            begin
                update_mem_address.que_write_idx[j] = 1'b1;
                update_valid_mem_address.que_write_idx[j] = 1'b1;
            end
            else
            begin
                update_mem_address.que_write_idx[j] = 1'b0;
                update_valid_mem_address.que_write_idx[j] = 1'b0;
            end
        end
    end
    else
    begin
        update_mem_address.valid = '0;
        update_mem_address.update_data = '0;
            update_mem_address.que_write_idx = '0;
        update_valid_mem_address.que_write_idx = '0;
        update_valid_mem_address.valid = '0;
        update_valid_mem_address.update_data = '0;
    end
    
end

cir_q_ld_st #(
    .cir_q_offset(LD_ST_cir_q_offset),
    .cir_q_index(LD_ST_cir_q_index)
)
ld_st(
    .clk(clk),
    .rst(rst),
    //.update_index(LD_ST_cirq.update_index_0),

    .issue(LD_ST_cirq.issue),                                // Signal to initiate an issue => issue_ptr++ 
    .commit(LD_ST_cirq.commit),                               // Signal to initiate a commit => commit_ptr++
    //.update(LD_ST_cirq.update_0),                               // Signal to initiate entry update on a broadcast

    .datain_issue(LD_ST_cirq.datain_issue),
    //.datain_update(LD_ST_cirq.datain_update_0),
    
    //.dataout(LD_ST_cirq.dataout),
    .cir_q_full(LD_ST_cirq.cir_q_full), 
    .cir_q_empty(LD_ST_cirq.cir_q_empty),
    // output logic commit_ready,                      // Output signal to signify that we can commit the entry at commit_ptr but not actually committing it
    //SIGNALS I NEED FROM BASE CIRQs
    .look_up(),
    .output_look_up(),
    .update_1(),
	.update_32(),
    .look_up_valid(),
    .output_look_up_valid(),
    .look_up_mem_address(),
    .output_look_up_mem_address(),
    .look_up_valid_mem_address(),
    .output_look_up_valid_mem_address(),
    .update_32_mem_addr(),
    .update_1_mem_addr(),

    .data_at_commit(ld_st_data_at_commit)//output
);

cir_q_ld_st #(
    .cir_q_offset(mem_addr_cir_q_offset),
    .cir_q_index(mem_addr_cir_q_index)
)
mem_address(
    .clk(clk),
    .rst(rst),

    .issue(mem_address_cirq.issue),                                // Signal to initiate an issue => issue_ptr++ 
    .commit(mem_address_cirq.commit),                               // Signal to initiate a commit => commit_ptr++

    .datain_issue(mem_address_cirq.datain_issue),
    
    //.dataout(mem_address_cirq.dataout),
    .cir_q_full(mem_address_cirq.cir_q_full), 
    .cir_q_empty(mem_address_cirq.cir_q_empty),
    // output logic commit_ready,                      // Output signal to signify that we can commit the entry at commit_ptr but not actually committing it
    //SIGNALS I NEED FROM BASE CIRQs
    //.update_mem_address(update_mem_address),
    .look_up(),
    .output_look_up(),
	.update_1(),
	.update_32(),
    .look_up_valid(),
    .output_look_up_valid(),
    .look_up_mem_address(),
    .output_look_up_mem_address(),
    .look_up_valid_mem_address(),
    .output_look_up_valid_mem_address(),
    .update_32_mem_addr(update_mem_address),
    .update_1_mem_addr(),

    .data_at_commit(mem_address_data_at_commit)//output
);

cir_q_ld_st #(
    .cir_q_offset(mem_addr_src_cir_q_offset),
    .cir_q_index(mem_addr_src_cir_q_index)
)
src_mem_address(
    .clk(clk),
    .rst(rst),
    // .update_index(src_rob_cirq.update_index_0),

    .issue(src_rob_mem_address_cirq.issue),                                // Signal to initiate an issue => issue_ptr++ 
    .commit(src_rob_mem_address_cirq.commit),                               // Signal to initiate a commit => commit_ptr++
    // .update(src_rob_mem_address_cirq.update_0),                               // Signal to initiate entry update on a broadcast

    .datain_issue(src_rob_mem_address_cirq.datain_issue),
    // .datain_update(src_rob_mem_address_cirq.datain_update_0),
    
    //.dataout(src_rob_mem_address_cirq.dataout),
    .cir_q_full(src_rob_mem_address_cirq.cir_q_full), 
    .cir_q_empty(src_rob_mem_address_cirq.cir_q_empty),
    // output logic commit_ready,                      // Output signal to signify that we can commit the entry at commit_ptr but not actually committing it
    //SIGNALS I NEED FROM BASE CIRQs

    .look_up(),
    .output_look_up(),
    .update_1(),
	 .update_32(),
    .look_up_valid(),
    .output_look_up_valid(),
    .look_up_mem_address(look_up_mem_addr),
    .output_look_up_mem_address(output_look_up_mem_addr),
    .look_up_valid_mem_address(),
    .output_look_up_valid_mem_address(),
    .update_32_mem_addr(),
    .update_1_mem_addr(),

    .data_at_commit(src_rob_mem_address_data_at_commit)//output
);

cir_q_ld_st #(
    .cir_q_offset(valid_mem_address_data_cir_q_offset),
    .cir_q_index(valid_mem_address_data_cir_q_index)
)
valid_mem_address(
    .clk(clk),
    .rst(rst),
    // .update_index(valid_mem_address_cirq.update_index_0),

    .issue(valid_mem_address_cirq.issue),                                // Signal to initiate an issue => issue_ptr++ 
    .commit(valid_mem_address_cirq.commit),                               // Signal to initiate a commit => commit_ptr++
    // .update(valid_mem_address_cirq.update_0),                               // Signal to initiate entry update on a broadcast

    .datain_issue(valid_mem_address_cirq.datain_issue),
    // .datain_update(valid_mem_address_cirq.datain_update_0),
    
    //.dataout(valid_mem_address_cirq.dataout),
    .cir_q_full(valid_mem_address_cirq.cir_q_full), 
    .cir_q_empty(valid_mem_address_cirq.cir_q_empty),
    // output logic commit_ready,                      // Output signal to signify that we can commit the entry at commit_ptr but not actually committing it
    //SIGNALS I NEED FROM BASE CIRQs

    //.update_valid(update_valid),
    .look_up(),
    .output_look_up(),
    .update_1(),
	 .update_32(),
    .look_up_valid(),
    .output_look_up_valid(),
       .look_up_mem_address(),
    .output_look_up_mem_address(),
    .look_up_valid_mem_address(look_up_valid_mem_addr),
    .output_look_up_valid_mem_address(output_look_up_valid_mem_addr),
    .update_32_mem_addr(),
    .update_1_mem_addr(update_valid_mem_address),
    
    .data_at_commit(valid_mem_address_data_at_commit)//output
);

cir_q_ld_st #(
    .cir_q_offset(write_data_cir_q_offset),
    .cir_q_index(write_data_cir_q_index)
)
write_data(
    .clk(clk),
    .rst(rst),
    // .update_index(write_data_cirq.update_index_0),

    .issue(write_data_cirq.issue),                                // Signal to initiate an issue => issue_ptr++ 
    .commit(write_data_cirq.commit),                               // Signal to initiate a commit => commit_ptr++
    // .update(write_data_cirq.update_0),                               // Signal to initiate entry update on a broadcast

    .datain_issue(write_data_cirq.datain_issue),
    // .datain_update(write_data_cirq.datain_update_0),
    
    //.dataout(write_data_cirq.dataout),
    .cir_q_full(write_data_cirq.cir_q_full), 
    .cir_q_empty(write_data_cirq.cir_q_empty),
    // output logic commit_ready,                      // Output signal to signify that we can commit the entry at commit_ptr but not actually committing it
    //SIGNALS I NEED FROM BASE CIRQs
    //.update_write_data(update_write_data),
    .look_up(),
    .output_look_up(),
	 .update_1(),
	 .update_32(update_write_data),
    .look_up_valid(),
    .output_look_up_valid(),
       .look_up_mem_address(),
    .output_look_up_mem_address(),
    .look_up_valid_mem_address(),
    .output_look_up_valid_mem_address(),
    .update_32_mem_addr(),
    .update_1_mem_addr(),

    .data_at_commit(write_data_at_commit)//output
);

cir_q_ld_st #(
    .cir_q_offset(src_rob_data_cir_q_offset),
    .cir_q_index(src_rob_data_cir_q_index)
)
src_rob(
    .clk(clk),
    .rst(rst),
    // .update_index(src_rob_cirq.update_index_0),

    .issue(src_rob_cirq.issue),                                // Signal to initiate an issue => issue_ptr++ 
    .commit(src_rob_cirq.commit),                               // Signal to initiate a commit => commit_ptr++
    // .update(src_rob_cirq.update_0),                               // Signal to initiate entry update on a broadcast

    .datain_issue(src_rob_cirq.datain_issue),
    // .datain_update(src_rob_cirq.datain_update_0),
    
    //.dataout(src_rob_cirq.dataout),
    .cir_q_full(src_rob_cirq.cir_q_full), 
    .cir_q_empty(src_rob_cirq.cir_q_empty),
    // output logic commit_ready,                      // Output signal to signify that we can commit the entry at commit_ptr but not actually committing it
    //SIGNALS I NEED FROM BASE CIRQs
    .look_up(look_up_src),
    .output_look_up(output_look_up_src),
    .update_1(),
	 .update_32(),
    .look_up_valid(),
    .output_look_up_valid(),
       .look_up_mem_address(),
    .output_look_up_mem_address(),
    .look_up_valid_mem_address(),
    .output_look_up_valid_mem_address(),
    .update_32_mem_addr(),
    .update_1_mem_addr(),

    .data_at_commit(src_rob_data_at_commit)//output
);

cir_q_ld_st #(
    .cir_q_offset(valid_data_cir_q_offset),
    .cir_q_index(valid_data_cir_q_index)
)
valid_src(
    .clk(clk),
    .rst(rst),
    // .update_index(valid_cirq.update_index_0),

    .issue(valid_cirq.issue),                                // Signal to initiate an issue => issue_ptr++ 
    .commit(valid_cirq.commit),                               // Signal to initiate a commit => commit_ptr++
    // .update(valid_cirq.update_0),                               // Signal to initiate entry update on a broadcast

    .datain_issue(valid_cirq.datain_issue),
    // .datain_update(valid_cirq.datain_update_0),
    
    //.dataout(valid_cirq.dataout),
    .cir_q_full(valid_cirq.cir_q_full), 
    .cir_q_empty(valid_cirq.cir_q_empty),
    // output logic commit_ready,                      // Output signal to signify that we can commit the entry at commit_ptr but not actually committing it
    //SIGNALS I NEED FROM BASE CIRQs

    // .update_valid(update_valid),
    .look_up(),
    .output_look_up(),
	 .update_1(update_valid),
	 .update_32(),
    .look_up_valid(look_up_valid_src),
    .output_look_up_valid(output_look_up_valid_src),
       .look_up_mem_address(),
    .output_look_up_mem_address(),
    .look_up_valid_mem_address(),
    .output_look_up_valid_mem_address(),
    .update_32_mem_addr(),
    .update_1_mem_addr(),

    .data_at_commit(src_valid_data_at_commit)//output
);

cir_q_ld_st #(
    .cir_q_offset(des_rob_data_cir_q_offset),
    .cir_q_index(des_rob_data_cir_q_index)
)
des_rob(
    .clk(clk),
    .rst(rst),
    // .update_index(dest_rob_cirq.update_index_0),

    .issue(dest_rob_cirq.issue),                                // Signal to initiate an issue => issue_ptr++ 
    .commit(dest_rob_cirq.commit),                               // Signal to initiate a commit => commit_ptr++
    // .update(dest_rob_cirq.update_0),                               // Signal to initiate entry update on a broadcast

    .datain_issue(dest_rob_cirq.datain_issue),
    // .datain_update(dest_rob_cirq.datain_update_0),
    
    //.dataout(dest_rob_cirq.dataout),
    .cir_q_full(dest_rob_cirq.cir_q_full), 
    .cir_q_empty(dest_rob_cirq.cir_q_empty),
    // output logic commit_ready,                      // Output signal to signify that we can commit the entry at commit_ptr but not actually committing it
    //SIGNALS I NEED FROM BASE CIRQs
    .look_up(),
    .output_look_up(),
    .update_1(),
	 .update_32(),
    .look_up_valid(),
    .output_look_up_valid(),
       .look_up_mem_address(),
    .output_look_up_mem_address(),
    .look_up_valid_mem_address(),
    .output_look_up_valid_mem_address(),
    .update_32_mem_addr(),
    .update_1_mem_addr(),

    .data_at_commit(dest_rob_data_at_commit)//output
);

cir_q_ld_st #(
    .cir_q_offset(funct3_data_cir_q_offset),
    .cir_q_index(funct3_cir_q_index)
)
funct3(
    .clk(clk),
    .rst(rst),
    // .update_index(dest_rob_cirq.update_index_0),

    .issue(funct3_cirq.issue),                                // Signal to initiate an issue => issue_ptr++ 
    .commit(funct3_cirq.commit),                               // Signal to initiate a commit => commit_ptr++
    // .update(funct3_cirq.update_0),                               // Signal to initiate entry update on a broadcast

    .datain_issue(funct3_cirq.datain_issue),
    // .datain_update(funct3_cirq.datain_update_0),
    
    //.dataout(funct3_cirq.dataout),
    .cir_q_full(funct3_cirq.cir_q_full), 
    .cir_q_empty(funct3_cirq.cir_q_empty),
    // output logic commit_ready,                      // Output signal to signify that we can commit the entry at commit_ptr but not actually committing it
    //SIGNALS I NEED FROM BASE CIRQs
    .look_up(),
    .output_look_up(),
    .update_1(),
	 .update_32(),
    .look_up_valid(),
    .output_look_up_valid(),
       .look_up_mem_address(),
    .output_look_up_mem_address(),
    .look_up_valid_mem_address(),
    .output_look_up_valid_mem_address(),
    .update_32_mem_addr(),
    .update_1_mem_addr(),

    .data_at_commit(funct3_data_at_commit)//output
);

endmodule : Ld_St