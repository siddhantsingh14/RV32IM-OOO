module bht #(
    parameter index = 5
)(
    input clk,
    input rst,

    input logic read,
    input logic update,
    input logic check,
    input logic [index-1:0] rindex,
    input logic [index-1:0] windex,
    input logic [index-1:0] cindex,

    input logic [9:0] datain_update,

    output logic is_taken_not_taken,
    output logic predicted_taken_not_taken,
    output logic [1:0] pc_curr_hist,
    output logic [7:0] counters
);

localparam num_entries = 2**index;

logic [9:0] data [num_entries-1:0];
logic [9:0] _dataout; 

always_comb begin
    is_taken_not_taken = 1'b0;
    predicted_taken_not_taken = 1'b0;
    pc_curr_hist = '0;
    counters  = '0;

    if (read) begin          // read returns whether pc_curr is a 'taken branch' or a 'not taken branch'
        unique case (data[rindex][9:8])     // check history and return 'taken' if 'weakly' or 'strongly taken'
            2'b00   :   if ((data[rindex][7:6] == 2'b10) | (data[rindex][7:6] == 2'b11)) is_taken_not_taken = 1'b1;
            2'b01   :   if ((data[rindex][5:4] == 2'b10) | (data[rindex][5:4] == 2'b11)) is_taken_not_taken = 1'b1;
            2'b10   :   if ((data[rindex][3:2] == 2'b10) | (data[rindex][3:2] == 2'b11)) is_taken_not_taken = 1'b1;
            2'b11   :   if ((data[rindex][1:0] == 2'b10) | (data[rindex][1:0] == 2'b11)) is_taken_not_taken = 1'b1;
        endcase
    end

    // if (update) begin
    //     unique case (data[windex][9:8])     // check history and update it on misprediction

    //     endcase 
    // end

    if (check) begin
        unique case (data[cindex][9:8])     // check history and return 'taken' if 'weakly' or 'strongly taken'
            2'b00   :   if ((data[cindex][7:6] == 2'b10) | (data[cindex][7:6] == 2'b11)) predicted_taken_not_taken = 1'b1;
            2'b01   :   if ((data[cindex][5:4] == 2'b10) | (data[cindex][5:4] == 2'b11)) predicted_taken_not_taken = 1'b1;
            2'b10   :   if ((data[cindex][3:2] == 2'b10) | (data[cindex][3:2] == 2'b11)) predicted_taken_not_taken = 1'b1;
            2'b11   :   if ((data[cindex][1:0] == 2'b10) | (data[cindex][1:0] == 2'b11)) predicted_taken_not_taken = 1'b1;
        endcase
        pc_curr_hist = data[cindex][9:8];
        counters = data[cindex][7:0];
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < num_entries; ++i)
            data[i] <= {2'b11, 8'b0};
    end
    else begin
        if (update) begin
            data[windex] <= datain_update;
        end
    end
end

endmodule : bht

/*
    data[9:8] => history    (NN, NT, TN, TT)
    data[7:6] => First 2BC  (for history NN)
    data[5:4] => Second 2BC (for history NT)
    data[3:2] => Third 2BC  (for history TN)
    data[1:0] => Fourth 2BC (for history TT)

    Updating histories on mispredictions:

*/