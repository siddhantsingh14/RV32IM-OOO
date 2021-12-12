import sched_structs::*;
import rob_entry_structs::*; 

module regfile (
    input clk, 
    input rst,
    input sched_structs::IQtoRF IQtoRF,

    output sched_structs::RFtoIQ RFtoIQ,
    input rob_entry_structs::rob_to_regfile rob_regfile_bus,
    input sched_structs::ROBToALL ROBToALL
);

logic [31:0] data [32];
logic data_valid [32];      // On commit data_valid 1, on issue data_valid is 0
logic [4:0] commit_rob_idx [32];



always_ff @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < 32; i++) begin
            data[i] <= '0;
            commit_rob_idx[i] <= '0;
            data_valid[i] <= 1'b1;
        end
    end

    else if(ROBToALL.flush_all) begin
        if(rob_regfile_bus.valid)   begin
            if((rob_regfile_bus.regfile_idx !='0))  begin
                data[rob_regfile_bus.regfile_idx] <= rob_regfile_bus.value;
            end
        end
        for (int i = 0; i < 32; i++) begin
            commit_rob_idx[i] <= '0;
            data_valid[i] <= 1'b1;
        end
    end

    else begin
        if((IQtoRF.write)&(rob_regfile_bus.valid) & (IQtoRF.rd == rob_regfile_bus.regfile_idx) )    begin   //write to data but not valid
            if(IQtoRF.rd== '0)  begin
                data[rob_regfile_bus.regfile_idx] <= '0;
                commit_rob_idx[rob_regfile_bus.regfile_idx] <= '0;
                data_valid[rob_regfile_bus.regfile_idx] <= 1'b1;
            end
            else begin
                data[rob_regfile_bus.regfile_idx] <= rob_regfile_bus.value;
                commit_rob_idx[rob_regfile_bus.regfile_idx] <= IQtoRF.rob_index;
                data_valid[rob_regfile_bus.regfile_idx] <= 1'b0;
            end
        end
        else if (IQtoRF.write) begin                                     // write ROB index on an inst. issue
            if(IQtoRF.rd== '0)  begin
                commit_rob_idx[IQtoRF.rd] <= '0;
                data_valid[IQtoRF.rd] <= '1;
            end
            else begin
                commit_rob_idx[IQtoRF.rd] <= IQtoRF.rob_index;
                data_valid[IQtoRF.rd] <= 1'b0;
            end            
        end



        // RegFile Writes on Commits logic goes here
        else if((rob_regfile_bus.valid))   begin
            if((commit_rob_idx[rob_regfile_bus.regfile_idx] == rob_regfile_bus.rob_idx) & (rob_regfile_bus.regfile_idx !='0))    begin   //this is the latest commit that the regfile is looking for, so commit
                data[rob_regfile_bus.regfile_idx] <= rob_regfile_bus.value;
                data_valid[rob_regfile_bus.regfile_idx] <= 1'b1;
            end
            else begin
                if((rob_regfile_bus.regfile_idx !='0))  begin
                    data[rob_regfile_bus.regfile_idx] <= rob_regfile_bus.value;
                    data_valid[rob_regfile_bus.regfile_idx] <= 1'b0;
                end
                else begin
                    data[rob_regfile_bus.regfile_idx] <= '0;
                    data_valid[rob_regfile_bus.regfile_idx] <= 1'b1;
                end
            end
        end
    end
end

always_comb begin
    RFtoIQ = '{default: '0};
    
    if (IQtoRF.lookup_regfile_1) begin
        RFtoIQ.lookup_valid_1 = 1'b1;
        RFtoIQ.valid_1 = IQtoRF.reg_idx_1 == '0 ? 1'b1 : data_valid[IQtoRF.reg_idx_1];      // if lookup is R0, then always valid as R0 = '0
        RFtoIQ.val_1 =  IQtoRF.reg_idx_1 == '0 ? '0 : (data_valid[IQtoRF.reg_idx_1] == '0) ? commit_rob_idx[IQtoRF.reg_idx_1] :data[IQtoRF.reg_idx_1];

        if(rob_regfile_bus.valid & (rob_regfile_bus.rob_idx==RFtoIQ.val_1) &(rob_regfile_bus.regfile_idx==IQtoRF.reg_idx_1) & ~RFtoIQ.valid_1)   begin
            RFtoIQ.valid_1=1'b1;
            RFtoIQ.val_1=rob_regfile_bus.value;
        end
    end

    if (IQtoRF.lookup_regfile_2) begin
        RFtoIQ.lookup_valid_2 = 1'b1;
        RFtoIQ.valid_2 = IQtoRF.reg_idx_2 == '0 ? 1'b1 : data_valid[IQtoRF.reg_idx_2];
        RFtoIQ.val_2 = IQtoRF.reg_idx_2 == '0 ? '0 : (data_valid[IQtoRF.reg_idx_2] == '0) ? commit_rob_idx[IQtoRF.reg_idx_2] :data[IQtoRF.reg_idx_2];

        if(rob_regfile_bus.valid & ((rob_regfile_bus.rob_idx==RFtoIQ.val_2)&(rob_regfile_bus.regfile_idx==IQtoRF.reg_idx_2)) & ~RFtoIQ.valid_2)   begin
            RFtoIQ.valid_2=1'b1;
            RFtoIQ.val_2=rob_regfile_bus.value;
        end
    end
end

endmodule