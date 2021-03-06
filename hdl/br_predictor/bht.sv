module twobit_history_predictor #(
    parameter bht_index = 12
)(
    input clk, 
    input rst,

    input read,
    input check,
    input logic [31:0] pc_curr,
    input logic [31:0] pc_curr_update,
    input logic [31:0] pc_out_br_bus,
    input logic was_taken_not_taken,
    input logic was_jump,

    output logic [31:0] predicted_pc,
    output logic mispredicted,
    output logic [31:0] restart_pc
);

localparam bht_entry_size = 10;

logic [bht_index-1:0] rindex_bht, windex_bht, cindex_bht;
logic read_bht, update_bht, check_bht, is_taken_not_taken, predicted_taken_not_taken;
logic read_btb, update_btb, check_btb;
logic [31:0] pc_out_btb, pc_out_btb_check;
logic [1:0] pc_curr_hist, hist_update;
logic [7:0] counters, new_counters;
logic [9:0] datain_update_bht;

always_comb begin 
    read_bht = 1'b0;
    check_bht = 1'b0;
    rindex_bht = '0;
    cindex_bht = '0;
    windex_bht = '0;
    mispredicted = 1'b0;
    new_counters = '0;
    datain_update_bht = '0;
    hist_update = '0;
    update_bht = 1'b0;
    update_btb = 1'b0;
    read_btb = 1'b0;
    predicted_pc = '0;
    check_btb = 1'b0;
    restart_pc = '0;

    if (read) begin
        read_bht = 1'b1;
        read_btb = 1'b1; 
        rindex_bht = pc_curr[(bht_index + 1) : 2];
        if (is_taken_not_taken) predicted_pc = pc_out_btb;
        else predicted_pc = pc_curr + 4;
    end

    if (check) begin            // initiated by fetch unit on valid data_bus_CMP_br
        check_bht = 1'b1;
        cindex_bht = pc_curr_update[(bht_index + 1) : 2];
        check_btb = 1'b1;
        if ((predicted_taken_not_taken != was_taken_not_taken) | ((pc_out_btb_check != pc_out_br_bus) & was_taken_not_taken == 1'b1 & predicted_taken_not_taken == 1'b1)) begin
            mispredicted = 1'b1;
            restart_pc = pc_curr_update;
            windex_bht = cindex_bht;
            hist_update = {{pc_curr_hist[0]}, {was_taken_not_taken}};
            if (was_taken_not_taken) begin          // update counters based on pc_curr_hist
                unique case (pc_curr_hist)          // increment counter if pc_curr was taken (correction on misprediction)
                    2'b00   :   new_counters = {counters[7] | counters[6], (~counters[6]) | counters[7], counters[5:0]};
                    2'b01   :   new_counters = {counters[7:6], counters[5] | counters[4], (~counters[4]) | counters[5], counters[3:0]};
                    2'b10   :   new_counters = {counters[7:4], counters[3] | counters[2], (~counters[2]) | counters[3], counters[1:0]};
                    2'b11   :   new_counters = {counters[7:2], counters[1] | counters[0], (~counters[0]) | counters[1]};
                endcase
            end else begin
                unique case (pc_curr_hist)          // decrement counter if pc_curr was not taken (correction on misprediction)
                    2'b00   :   new_counters = {counters[7] & counters[6], (~counters[6]) & counters[7], counters[5:0]};
                    2'b01   :   new_counters = {counters[7:6], counters[5] & counters[4], (~counters[4]) & counters[5], counters[3:0]};
                    2'b10   :   new_counters = {counters[7:4], counters[3] & counters[2], (~counters[2]) & counters[3], counters[1:0]};
                    2'b11   :   new_counters = {counters[7:2], counters[1] & counters[0], (~counters[0]) & counters[1]};
                endcase
            end
            datain_update_bht = {hist_update, new_counters};
            if (was_jump) datain_update_bht = {2'b11, 8'b00000011};
            update_bht = 1'b1;
            update_btb = 1'b1;
        end else begin  // TODO::if not mispredicted, check history and update to 'strongly' if 'weakly'
            if (was_taken_not_taken) begin
                if ((pc_curr_hist == 2'b00) & (counters[7:6] == 2'b10)) begin
                    new_counters = {2'b11, counters[5:0]};
                    datain_update_bht = {pc_curr_hist, new_counters};
                    update_bht = 1'b1;
                end
                else if ((pc_curr_hist == 2'b01) & (counters[5:4] == 2'b10)) begin
                    new_counters = {counters[7:6], 2'b11, counters[3:0]};
                    datain_update_bht = {pc_curr_hist, new_counters};
                    update_bht = 1'b1;
                end
                else if ((pc_curr_hist == 2'b10) & (counters[5:4] == 2'b10)) begin
                    new_counters = {counters[7:4], 2'b11, counters[1:0]};
                    datain_update_bht = {pc_curr_hist, new_counters};
                    update_bht = 1'b1;
                end
                else if ((pc_curr_hist == 2'b11) & (counters[5:4] == 2'b10)) begin
                    new_counters = {counters[7:2], 2'b11};
                    datain_update_bht = {pc_curr_hist, new_counters};
                    update_bht = 1'b1;
                end
            end 
            else if (~was_taken_not_taken) begin
                if ((pc_curr_hist == 2'b00) & (counters[7:6] == 2'b01)) begin
                    new_counters = {2'b00, counters[5:0]};
                    datain_update_bht = {pc_curr_hist, new_counters};
                    update_bht = 1'b1;
                end
                else if ((pc_curr_hist == 2'b01) & (counters[5:4] == 2'b01)) begin
                    new_counters = {counters[7:6], 2'b00, counters[3:0]};
                    datain_update_bht = {pc_curr_hist, new_counters};
                    update_bht = 1'b1;
                end
                else if ((pc_curr_hist == 2'b10) & (counters[5:4] == 2'b01)) begin
                    new_counters = {counters[7:4], 2'b00, counters[1:0]};
                    datain_update_bht = {pc_curr_hist, new_counters};
                    update_bht = 1'b1;
                end
                else if ((pc_curr_hist == 2'b11) & (counters[5:4] == 2'b01)) begin
                    new_counters = {counters[7:2], 2'b00};
                    datain_update_bht = {pc_curr_hist, new_counters};
                    update_bht = 1'b1;
                end
            end
        end
    end
end

bht #(.index(bht_index)) history_table (clk, rst, read_bht, update_bht, check_bht, rindex_bht, windex_bht, cindex_bht, datain_update_bht, is_taken_not_taken, predicted_taken_not_taken, pc_curr_hist, counters);
btb target_buffer (clk, rst, read_btb, check_btb, update_btb, pc_curr, pc_curr_update, pc_out_br_bus, pc_out_btb, pc_out_btb_check);

endmodule : twobit_history_predictor

// assign update_bht = ;
// assign rindex_bht = pc_curr[(bht_index + 1) : 2];
// assign windex = pc_curr_update[(bht_index + 1) : 2];
// assign predicted_pc = is_taken_not_taken ? 