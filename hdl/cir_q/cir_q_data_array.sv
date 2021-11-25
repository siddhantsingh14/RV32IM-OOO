module cir_q_data_array #(
    parameter s_offset = 5,
    parameter s_index = 5
)
(
    input clk,
    input rst,
    input read,
    input write,
    input [s_index-1:0] rindex,
    input [s_index-1:0] windex,
    input [s_index-1:0] commit_index,
    input [2**s_offset-1:0] datain,
    output logic [2**s_offset-1:0] dataout,
    output logic [2**s_offset-1:0] dataout_commit
);

// localparam s_line   = 8*s_mask;
localparam entry_size = 2**s_offset;
localparam num_sets = 2**s_index;

logic [entry_size-1:0] data [num_sets-1:0] /* synthesis ramstyle = "logic" */;
logic [entry_size-1:0] _dataout;

assign dataout = _dataout;
assign dataout_commit = data[commit_index];

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
    end
end

endmodule : cir_q_data_array