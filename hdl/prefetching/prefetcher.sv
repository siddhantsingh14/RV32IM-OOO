module prefetcher (
    input clk,
    input rst,
    input logic prefetch_enable,
    output logic prefetch_mem_read,
    output logic [31:0] prefetch_mem_addr,
    input logic prefetch_mem_resp,
    input logic [255:0] prefetch_mem_data,
    //take input from I-cache as well as to current query
    input icache_read,
    input logic [31:0] icache_addr,
    input dcache_read,
    input dcache_write
);

logic prefetch_load, load_request, same_request;
logic [31:0] prefetch_addr_in, prefetch_addr_out;
logic [31:0] latest_icache_request, icache_request;

// logic [1:0] count, count_in;

always_ff @(posedge clk) begin
    if(rst)
        latest_icache_request <= '0;
    else    begin
        if(load_request)
            latest_icache_request<=icache_request;
        else if(same_request)
            latest_icache_request <= '0;
    end
end
register prefetch_addr_incr(
    .clk(clk),
    .rst(rst),
    .load(prefetch_load),
    .in(prefetch_addr_in),
    .out(prefetch_addr_out)
	);

enum int unsigned {
    polling,
    prefetching,
    addr_incr
}   curr_state, next_state;

always_comb begin : CURR_STATE_LOGIC
    prefetch_load = '0;
    prefetch_addr_in = '0;
    prefetch_mem_read = '0;
    prefetch_mem_addr = '0;
    load_request ='0;
    same_request ='0;
    icache_request = '0;
    unique case (curr_state)
        polling:    begin
            if(icache_read & ((icache_addr + 32'h20) != prefetch_addr_out)) begin
                prefetch_load = '1;
                prefetch_addr_in = icache_addr + 32'h20;
            end
            // load_count = '1;
            // count_in = '0;
        end    //put fetch mem_read here and load the addr of the current request here so the next block is within the right instr window
        prefetching:   begin
            if(icache_read & (icache_addr !=prefetch_mem_addr)) begin
                load_request = '1;
                icache_request = icache_addr;
            end
            prefetch_mem_read = '1;
            prefetch_mem_addr = prefetch_addr_out; //set this variable
        end
        addr_incr:   begin

            if(latest_icache_request != '0) begin
                prefetch_load = '1;
                prefetch_addr_in = latest_icache_request + 32'h20;
                same_request ='1;
            end
            else begin
                prefetch_load = '1;
                prefetch_addr_in = prefetch_addr_out + 32'h20;
            end
        end
    endcase
end

always_comb begin : NEXT_STATE_LOGIC
    next_state = curr_state;

    unique case (curr_state) 
        polling        :   begin
            if(prefetch_enable) begin
                next_state = prefetching;
            end
            else begin
                next_state = polling;
            end
        end

        prefetching   :  begin
            if(prefetch_mem_resp)
                next_state = addr_incr;
            else begin
                next_state = prefetching;
            end
        end 
        addr_incr: begin
            if(~dcache_read & ~dcache_write & ~icache_read)
                next_state =prefetching;
            
            else begin
                next_state =polling;
            end        
        end
    endcase     
end

always_ff @(posedge clk) begin : NEXT_STATE_ASSIGNMENT
    if (rst) 
        curr_state <= polling;
    else 
        curr_state <= next_state;
end

endmodule