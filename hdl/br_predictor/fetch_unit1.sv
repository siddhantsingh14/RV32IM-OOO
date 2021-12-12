import sched_structs::*;
import rv_structs::*;

module fetch_unit1(
    input clk,
    input rst,

    input logic [31:0] mem_rdata,
    input mem_resp,
    input logic commit_inst_q,                   // commit signal from instruction scheduler to pop an inst.

    input rv_structs::data_bus_CMP_br data_bus_CMP_br,
    input sched_structs::ROBToALL ROBToALL,
    
    output logic mem_read,
    output logic [31:0] mem_address,
    output logic commit_br_st_q,

    output logic inst_q_empty,

    output logic [31:0] inst1,                   // undecoded instruction at commit_ptr
    output logic [31:0] pc_out_val,

    output sched_structs::FetchToROB FetchToROB
);

logic load_pc, load_mar, read_bht, val_br_bus, check_bht, mispredicted, load_predicted_pc;
logic [31:0] pc_reg_in, pc_reg_out, mar_reg_in, mar_reg_out, inst;
logic [31:0] pc_curr, pc_curr_br_bus, predicted_pc, pc_out_br_bus;
logic load_inst_q, inst_q_full, inst_q_pc_full, inst_q_pc_empty;
logic [31:0] pc_in_q, pc_out_q, pc_out_q_1, predicted_pc_in, predicted_pc_out; 
logic load_restart_pc, rst_inst_q;
logic [31:0] restart_pc_in, restart_pc_out, restart_pc;
logic load_flush, flush_in, flush_out;
logic predictor_is_jump;

assign pc_out_val = pc_out_q_1;
assign mem_address = mar_reg_out;
assign rst_inst_q = rst | ROBToALL.flush_all;

enum int unsigned {
    FETCH1,
    FETCH1_MISPREDICT,
    FETCH2,
    FETCH2_MISPREDICT,
    FETCH1_CORRECTION
}   curr_state, next_state;

always_comb begin 
    read_bht = 1'b0;
    load_mar = 1'b0;
    load_pc = 1'b0;
    pc_curr = '0;
    check_bht = 1'b0;
    mar_reg_in = '0;
    pc_reg_in = '0;
    pc_in_q = '0;
    load_inst_q = 1'b0;
    pc_curr_br_bus = '0;
    pc_out_br_bus = '0;
    val_br_bus = '0;
    mem_read = 1'b0;
    predicted_pc_in = '0;
	load_predicted_pc = 1'b0;
    load_restart_pc = 1'b0;
    restart_pc_in = '0;
    flush_in = 1'b0;
    load_flush = 1'b0;
    predictor_is_jump = 1'b0;
    commit_br_st_q = 1'b0;

    FetchToROB = '{default: '0};

    unique case (curr_state)
        FETCH1              :   begin
            mar_reg_in = pc_reg_out;
            pc_curr = pc_reg_out;
            load_mar = 1'b1;
            read_bht = 1'b1;
            load_predicted_pc = 1'b1;
            predicted_pc_in = predicted_pc;
        end
        FETCH1_CORRECTION   :   begin
            mar_reg_in = predicted_pc_out;
            pc_curr = predicted_pc_out;
            load_mar = 1'b1;
            read_bht = 1'b1;
            load_predicted_pc = 1'b1;
            predicted_pc_in = predicted_pc;
        end
        FETCH1_MISPREDICT   : begin
            mar_reg_in = restart_pc_out;
            pc_curr = restart_pc_out;
            load_mar = 1'b1;
            read_bht = 1'b1;
            load_predicted_pc = 1'b1;
            predicted_pc_in = predicted_pc;
            load_flush = 1'b1;
            flush_in = 1'b0;
        end
        FETCH2              :   begin
            if (~mispredicted) mem_read = 1'b1;
            if (mem_resp) begin
                if (~inst_q_full) begin
                    pc_reg_in = predicted_pc_out;
                    pc_in_q = mem_address;
                    mem_read = 1'b0;
                    load_pc = 1'b1;
                    load_inst_q = 1'b1;
                end
            end
            if (ROBToALL.flush_all) begin
                load_flush = 1'b1;
                flush_in = 1'b1;
            end
            if (flush_in | flush_out) load_inst_q = 1'b0;  
        end
        FETCH2_MISPREDICT   :   begin
            mem_read = 1'b1;
            if (mem_resp) begin
                if (~inst_q_full) begin
                    pc_reg_in = mem_address + 4;
                    load_pc = 1'b1;
                    mem_read = 1'b0;
                    pc_in_q = mem_address;
                    load_inst_q = 1'b1;
                end
            end
            if (ROBToALL.flush_all) begin
                load_flush = 1'b1;
                flush_in = 1'b1;
            end
            if (flush_in | flush_out) load_inst_q = 1'b0; 
        end
    endcase

    if (data_bus_CMP_br.valid) begin    // br_RS has responded with a resolved branch. Initiate check for misprediction.
        pc_curr_br_bus = data_bus_CMP_br.pc;
        pc_out_br_bus = {data_bus_CMP_br.br_pc_out[31:2], 2'b00};
        val_br_bus = data_bus_CMP_br.value;
        predictor_is_jump = data_bus_CMP_br.is_jump | data_bus_CMP_br.is_jump_r;
        check_bht = 1'b1;

        FetchToROB.br_rob_index = data_bus_CMP_br.dest_rob;
        FetchToROB.bus_valid = 1'b1;
        FetchToROB.is_jump = data_bus_CMP_br.is_jump | data_bus_CMP_br.is_jump_r;
        FetchToROB.is_mispredict = mispredicted;
        // FetchToROB.load_val = (data_bus_CMP_br.is_jump) ? '1 : '0;
        FetchToROB.target_pc = FetchToROB.is_jump ? data_bus_CMP_br.br_pc_out : (data_bus_CMP_br.value ? data_bus_CMP_br.br_pc_out : data_bus_CMP_br.pc + 4);      

        if (mispredicted) commit_br_st_q = 1'b0;
        else commit_br_st_q = 1'b1;
    end

    if (ROBToALL.flush_all) begin
        load_restart_pc = 1'b1;
        restart_pc_in = ROBToALL.target_pc;
    end

end

always_comb begin
    next_state = curr_state;

    unique case (curr_state)
        FETCH1  :		next_state = FETCH2;
        FETCH1_MISPREDICT  :   next_state = FETCH2_MISPREDICT;
        FETCH2  :   next_state = mem_resp ? FETCH1 : FETCH2;
        FETCH2_MISPREDICT   :   next_state = mem_resp ? (mispredicted ? FETCH1_MISPREDICT : FETCH1_CORRECTION) : FETCH2_MISPREDICT; 
        FETCH1_CORRECTION   :   next_state = FETCH2;
    endcase
end

always_ff @(posedge clk) begin
    if (rst)
        curr_state <= FETCH1;
    else begin
        if (ROBToALL.flush_all & (curr_state == FETCH1 | curr_state == FETCH1_MISPREDICT | curr_state == FETCH1_CORRECTION)) curr_state <= FETCH1_MISPREDICT;
        else if ((flush_in | flush_out) & ((curr_state == FETCH2 | curr_state == FETCH2_MISPREDICT) & mem_resp)) curr_state <= FETCH1_MISPREDICT;
        else curr_state <= next_state; 
    end 
end

pc_reg pc (clk, rst, load_pc, pc_reg_in, pc_reg_out);
register MAR (clk, rst, load_mar, mar_reg_in, mar_reg_out);
twobit_history_predictor predictor_1 (clk, rst, read_bht, check_bht, pc_curr, pc_curr_br_bus, pc_out_br_bus, val_br_bus, predictor_is_jump, predicted_pc, mispredicted, restart_pc);
inst_q inst_q (clk, rst_inst_q, load_inst_q, commit_inst_q, mem_rdata, inst, inst1, inst_q_full, inst_q_empty);
inst_q inst_q_pc (clk, rst_inst_q, load_inst_q, commit_inst_q, pc_in_q, pc_out_q, pc_out_q_1, inst_q_pc_full, inst_q_pc_empty);
register predicted_pc_reg (clk, rst, load_predicted_pc, predicted_pc_in, predicted_pc_out);
register restart_pc_reg (clk, rst, load_restart_pc, restart_pc_in, restart_pc_out);
register #(.width(1)) flush_reg (clk, rst, load_flush, flush_in, flush_out);

endmodule : fetch_unit1

/* Notes:

FETCH1 :-
    pc_reg holds 0x60
    mar_reg holds 0x60 in next clock cycle - FETCH2 (with mem_read on) 

    With the predictor,
        FETCH1 : pc_curr = pc_reg_out (to predictor) 
        FETCH2 : mar_reg_in = pc_reg_out and pc_reg_in = pc_next (from predictor)

    On a mispredict,
        mar_reg_in = pc of mispredicted br

*/