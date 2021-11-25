module fetch_unit (
    input clk,
    input rst,

    input logic [31:0] mem_rdata,
    input mem_resp,
    input logic commit_inst_q,                   // commit signal from instruction scheduler to pop an inst.

    input logic [1:0] pcmux_sel,
    input logic [31:0] pc_new,
    input logic is_op_br,
    input rv_structs::data_bus_CMP_br data_bus_CMP_br,

    output logic mem_read,
    output logic [31:0] mem_address,

    output logic inst_q_empty,

    output logic [31:0] inst1,                   // undecoded instruction at commit_ptr
    output logic [31:0] pc_out_val
);

logic load_mar, load_inst_q, load_pc;
logic [31:0] pc_in, pc_out, mar_in, pc_out_q, pc_out_q_1, pc_in_q;
logic inst_q_full, inst_q_pc_full, inst_q_pc_empty;

logic load_target_pc;
logic target_pc_in, target_pc_out;

assign pc_out_val = pc_out_q_1;
// assign pc_in = data_bus_CMP_br.valid ? data_bus_CMP_br.value : (pcmux_sel ? pc_new : pc_out + 4);
// assign pc_in = pc_out + 4;

enum int unsigned {
    FETCH1,
    FETCH2,
    FETCH1_br,
    FETCH2_br
} curr_state, next_state;

// assign mar_in = pc_out;
// assign pc_in = data_bus_CMP_br.valid ? (data_bus_CMP_br.value ? data_bus_CMP_br.br_pc_out : pc_out + 4) : pc_out + 4;

always_comb begin : CURR_STATE_LOGIC
    load_mar = 1'b0;
    load_inst_q = 1'b0;
    load_pc = 1'b0;
    mem_read = 1'b0;
    target_pc_in = '0;
    load_target_pc = '0;
    pc_in = '0;
    mar_in = '0;
    pc_in_q = '0;

    unique case (curr_state)
        FETCH1  :   begin
            if (~is_op_br) begin
                load_mar = 1'b1;
                mar_in = pc_out;
            end
        end

        FETCH2  :   begin
            mem_read = 1'b1;
            if (mem_resp) begin
                pc_in = pc_out + 4;
                load_pc = 1'b1;
                pc_in_q = pc_out;
                load_inst_q = 1'b1;
            end
        end

        FETCH1_br   :   begin
            if (data_bus_CMP_br.valid) begin
                mar_in = data_bus_CMP_br.value ? data_bus_CMP_br.br_pc_out : pc_out;
                load_mar = 1'b1;
            end
        end

        FETCH2_br   :   begin
            mem_read = 1'b1;
            if (mem_resp) begin
                pc_in = mem_address + 4;
                load_pc = 1'b1;
                pc_in_q = mem_address;
                load_inst_q = 1'b1;
            end
        end
    endcase
end

always_comb begin : NEXT_STATE_LOGIC
    next_state = curr_state;

    unique case (curr_state)
        FETCH1  :   begin
            if (is_op_br) next_state = FETCH1_br;
            else next_state  = FETCH2;
        end    
        FETCH2  :   next_state = mem_resp ? FETCH1 : FETCH2;       // target pc resolved
        FETCH1_br  :   next_state = data_bus_CMP_br.valid ? FETCH2_br : FETCH1_br;
        FETCH2_br   :   next_state = mem_resp ? FETCH1 : FETCH2_br;
    endcase
end

always_ff @(posedge clk) begin : NEXT_STATE_ASSIGNMENT
    if (rst)
        curr_state <= FETCH1;
    else
        curr_state <= next_state;
end

pc_reg pc (clk, rst, load_pc, pc_in, pc_out);
register MAR (clk, rst, load_mar, mar_in, mem_address);
register #(.width(1)) target_pc (clk, rst, load_target_pc, target_pc_in,  target_pc_out);
inst_q inst_q (clk, rst, load_inst_q, commit_inst_q, mem_rdata, inst, inst1, inst_q_full, inst_q_empty);
inst_q inst_q_pc (clk, rst, load_inst_q, commit_inst_q, pc_in_q, pc_out_q, pc_out_q_1, inst_q_pc_full, inst_q_pc_empty);

endmodule : fetch_unit

/*

This code works well for magic memory

logic load_mar, load_inst_q, load_pc;
logic [31:0] pc_in, pc_out, mar_in;

logic inst_q_full;

assign load_mar = ~inst_q_full; 
assign load_pc = ~inst_q_full;            

assign load_inst_q = (~inst_q_full & mem_resp & ~rst) ? 1'b1 : 1'b0;
assign pc_in = pc_out + 4;
assign mar_in = pc_out;

pc_reg pc (clk, rst, load_pc, pc_in, pc_out);
register MAR (clk, rst, load_mar, mar_in, mem_address);
inst_q inst_q (clk, rst, load_inst_q, commit_inst, mem_rdata, inst, inst_q_full);

always_ff @(posedge clk) begin
    mem_read = ~inst_q_full & ~rst;
end 
*/