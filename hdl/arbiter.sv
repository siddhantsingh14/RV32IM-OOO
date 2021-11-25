module arbiter (
    input clk,
    input rst, 

    input fetch_mem_read,
    input ld_st_mem_read,
    input ld_st_mem_write,
    
    input logic inst_resp,
    input logic data_resp,

    input [31:0] inst_rdata,
    input [31:0] data_rdata,

    input logic [31:0] fetch_mem_address,
    input logic [31:0] ld_st_mem_address,
    input logic [31:0] ld_st_mem_wdata,

    output logic [31:0] fetch_mem_rdata,
    output logic [31:0] ld_st_mem_rdata,
    output logic [31:0] data_wdata,

    output logic [31:0] inst_addr,
    output logic [31:0] data_addr,

    output logic inst_read,
    output logic data_read,
    output logic data_write,

    output logic fetch_mem_resp,
    output logic ld_st_mem_resp  
);
enum int unsigned {
    POLL,
    INST,
    INST_DATA,
    DATA,
    HOLD_INST_DATA,
    HOLD_DATA,
    HOLD_INST
}   curr_state, next_state;

always_comb begin : CURR_STATE_LOGIC
    inst_read = 1'b0;
    data_read = 1'b0;

    data_write = 1'b0;
    fetch_mem_resp = 1'b0;
    ld_st_mem_resp = 1'b0;
    fetch_mem_rdata = '0;
    ld_st_mem_rdata = '0;
    data_wdata = '0;
    inst_addr = '0;
    data_addr = '0;

    unique case (curr_state)
        POLL        :   ;
        INST_DATA   :   begin
            inst_addr = fetch_mem_address;

            if (fetch_mem_read) inst_read = 1'b1;
            if (inst_resp) begin
                fetch_mem_rdata = inst_rdata;
                fetch_mem_resp = 1'b1;
            end
        end
        DATA        :   begin
            data_addr = ld_st_mem_address;

            if (ld_st_mem_read) data_read = 1'b1;
            else if (ld_st_mem_write) begin
                data_write = 1'b1;
                data_wdata = ld_st_mem_wdata;
            end

            if (data_resp) begin
                if (ld_st_mem_read) ld_st_mem_rdata = data_rdata;
                ld_st_mem_resp = 1'b1;
            end
        end
        INST        :   begin
            inst_addr = fetch_mem_address;

            if (fetch_mem_read) inst_read = 1'b1;
            if (inst_resp) begin
                fetch_mem_rdata = inst_rdata;
                fetch_mem_resp = 1'b1;
            end 
        end
        HOLD_INST_DATA,
        HOLD_DATA,
        HOLD_INST   :   ;
    endcase
end

always_comb begin : NEXT_STATE_LOGIC
    next_state = curr_state;

    unique case (curr_state) 
        POLL        :   begin
            if ((fetch_mem_read) & (ld_st_mem_read | ld_st_mem_write)) next_state = INST_DATA; 
            else if (fetch_mem_read) next_state = INST;
            else if (ld_st_mem_read | ld_st_mem_write) next_state = DATA;
        end

        INST_DATA   :   next_state = (fetch_mem_resp) ? HOLD_INST_DATA : INST_DATA;
        HOLD_INST_DATA: next_state = (~inst_resp) ? DATA : HOLD_INST_DATA;
        DATA        :   next_state = (ld_st_mem_resp) ? HOLD_DATA : DATA;
        HOLD_DATA   :   next_state = (~data_resp) ? POLL : HOLD_DATA;
        INST        :   next_state = (fetch_mem_resp) ? HOLD_INST : INST;
        HOLD_INST   :   next_state = (~inst_resp) ? POLL : HOLD_INST;
    endcase     
end

always_ff @(posedge clk) begin : NEXT_STATE_ASSIGNMENT
    if (rst) 
        curr_state <= POLL;
    else 
        curr_state <= next_state;
end

endmodule