module btb #(
    parameter btb_offset = 5,
    parameter btb_index = 9
)(
    input clk,
    input rst,

    input logic read,
    input logic check, 
    input logic write,
    
    input logic [31:0] pc_curr,           // pc_curr
    input logic [31:0] pc_curr_update,      // pc_curr_update
    input logic [31:0] pc_out_br_bus,     // pc_out_br_bus

    output logic [31:0] pc_out_btb,
    output logic [31:0] pc_out_check
);

localparam entry_size = 2**btb_offset;
localparam num_entries = 2**btb_index;

logic [entry_size-1:0] data [num_entries-1:0];
logic [entry_size-1:0] _dataout;
logic [btb_index-1:0] rindex, windex;

assign rindex = pc_curr[(btb_index + 1) : 2];
assign windex = pc_curr_update[(btb_index + 1) : 2];
// assign pc_out_btb = _dataout;

always_comb begin 
    pc_out_check = '0;
    pc_out_btb = '0;

    if (check) pc_out_check = data[windex];
    if (read) pc_out_btb = data[rindex];
end

always_ff @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < num_entries; ++i)
            data[i] <= '0;
    end
    else begin
        // if (read)
        //     _dataout <= data[rindex];
        
        if (write)
            data[windex] <= pc_out_br_bus;
    end
end

endmodule : btb