module arbiter (
    input clk,
    input rst, 
    //from cache
    input fetch_mem_read,
    input ld_st_mem_read,
    input ld_st_mem_write,

    //from CL
    input logic resp_o,

    input [255:0] cacheline_output,

    //from cache
    input logic [31:0] fetch_mem_address,
    input logic [31:0] ld_st_mem_address,
    input logic [255:0] ld_st_mem_wdata,

    //to CL
    output logic [255:0] fetch_mem_rdata,
    output logic [255:0] prefetch_mem_data,
    output logic [255:0] ld_st_mem_rdata,
    output logic [255:0] data_wdata,

    output logic [31:0] inst_addr,
    output logic [31:0] data_addr,

    output logic inst_read,
    output logic data_read,
    output logic data_write,

    output logic fetch_mem_resp,
    output logic ld_st_mem_resp,
    output logic prefetch_mem_resp,
    output logic prefetch_enable,
    input logic prefetch_mem_read,
    input logic [31:0] prefetch_mem_addr
);

logic [255:0] prefetch_data_buffer [32];
logic [31:0] prefetch_addr_buffer [32];

logic [255:0] fetched_data;
logic [31:0] fetched_addr;
logic [4:0] buffer_pointer;
always_ff @(posedge clk) begin
    if(rst) begin
        for(int i =0; i<32; i++)    begin
            prefetch_data_buffer[i] <= '0;
            prefetch_addr_buffer[i] <= '0;
        end
        buffer_pointer<= 0;
    end
    else if(prefetch_mem_resp | fetch_mem_resp)   begin
        prefetch_data_buffer[buffer_pointer] <= fetched_data;
        prefetch_addr_buffer[buffer_pointer] <= fetched_addr;
        if(buffer_pointer == '1)
            buffer_pointer<= 0;
        else
            buffer_pointer<= buffer_pointer + 1;
    end
end

enum int unsigned {
    POLL,
    INST,
    DATA,
    PREFETCH,
    INST_BUFFER_CHECK,
    PREFETCH_BUFFER_CHECK
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
    prefetch_enable = '0;
    prefetch_mem_data ='0;
    prefetch_mem_resp='0;
    fetched_data = '0;
    fetched_addr = '0;


    unique case (curr_state)
        POLL        :   ;
        DATA        :   begin
            data_addr = ld_st_mem_address;

            if (ld_st_mem_read) data_read = 1'b1;
            else if (ld_st_mem_write) begin
                data_write = 1'b1;
                data_wdata = ld_st_mem_wdata;
            end

            if (resp_o) begin
                if (ld_st_mem_read) ld_st_mem_rdata = cacheline_output;
                ld_st_mem_resp = 1'b1;
                prefetch_enable = '1;
            end
        end
        INST        :   begin
            inst_addr = fetch_mem_address;

            if (fetch_mem_read) inst_read = 1'b1;
            if (resp_o) begin
                fetch_mem_rdata = cacheline_output;
                fetch_mem_resp = 1'b1;
                prefetch_enable = '1;
                fetched_data = cacheline_output;
                fetched_addr = inst_addr;
            end 
        end
        PREFETCH        :   begin
            inst_addr = prefetch_mem_addr;

            if (prefetch_mem_read) inst_read = 1'b1;
            if(fetch_mem_read)  begin
                for(int i =0; i<32; i++)    begin
                if(fetch_mem_address == prefetch_addr_buffer[i])    begin
                    fetch_mem_rdata = prefetch_data_buffer[i];
                    fetch_mem_resp = 1'b1;
                end
            end
            end
            if (resp_o) begin
                if(fetch_mem_read & (prefetch_mem_addr == fetch_mem_address))   begin
                    fetch_mem_rdata = cacheline_output;
                    fetch_mem_resp = 1'b1;

                    prefetch_mem_data = cacheline_output;
                    fetched_data = cacheline_output;
                    fetched_addr = prefetch_mem_addr;
                    prefetch_mem_resp = 1'b1;
                end
                else begin
                    prefetch_mem_data = cacheline_output;
                    prefetch_mem_resp = 1'b1;
                    fetched_data = cacheline_output;
                    fetched_addr = prefetch_mem_addr;
                end
            end 
        end
        INST_BUFFER_CHECK   : begin
            for(int i =0; i<32; i++)    begin
                if(fetch_mem_address == prefetch_addr_buffer[i])    begin
                    fetch_mem_rdata = prefetch_data_buffer[i];
                    fetch_mem_resp = 1'b1;
                end
            end
        end
        PREFETCH_BUFFER_CHECK   : begin
            for(int i =0; i<32; i++)    begin
                if(prefetch_mem_addr == prefetch_addr_buffer[i])    begin
                    prefetch_mem_data = prefetch_data_buffer[i];
                    prefetch_mem_resp = 1'b1;
                end
            end
        end 
    endcase
end

always_comb begin : NEXT_STATE_LOGIC
    next_state = curr_state;

    unique case (curr_state) 
        POLL        :   begin
            if (fetch_mem_read) next_state = INST_BUFFER_CHECK;
            else if (ld_st_mem_read | ld_st_mem_write) next_state = DATA;
            else if (prefetch_mem_read) next_state = PREFETCH_BUFFER_CHECK;
        end

        DATA        :   next_state = (ld_st_mem_resp) ? POLL : DATA;
        INST        :   next_state = (fetch_mem_resp) ? POLL : INST;
        PREFETCH    :   next_state = (prefetch_mem_resp) ? POLL : PREFETCH;
        INST_BUFFER_CHECK: next_state = (fetch_mem_resp) ? POLL : INST;
        PREFETCH_BUFFER_CHECK: next_state = (prefetch_mem_resp) ? POLL : PREFETCH;
    endcase     
end

always_ff @(posedge clk) begin : NEXT_STATE_ASSIGNMENT
    if (rst) 
        curr_state <= POLL;
    else 
        curr_state <= next_state;
end

endmodule