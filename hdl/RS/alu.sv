import rv_structs::*;

module alu
(
    input rv_structs::RStoALU RStoALU[6],

    output rv_structs::data_bus bus[5]
);

always_comb
begin

    for(int i = 0; i < 5; i++)
    begin
        if(RStoALU[i].ld_alu)
        begin
            bus[i].valid = 1'b1;
            bus[i].dest_rob = RStoALU[i].rob_idx;
            unique case (RStoALU[i].alu_op)
                3'b000:  bus[i].value = RStoALU[i].alu_src1 + RStoALU[i].alu_src2;
                3'b001:  bus[i].value = RStoALU[i].alu_src1 << RStoALU[i].alu_src2;
                3'b010:  bus[i].value = $signed(RStoALU[i].alu_src1) >>> RStoALU[i].alu_src2[4:0];
                3'b011:  bus[i].value = RStoALU[i].alu_src1 - RStoALU[i].alu_src2;
                3'b100:  bus[i].value = RStoALU[i].alu_src1 ^ RStoALU[i].alu_src2;
                3'b101:  bus[i].value = RStoALU[i].alu_src1 >> RStoALU[i].alu_src2[4:0];
                3'b110:  bus[i].value = RStoALU[i].alu_src1 | RStoALU[i].alu_src2;
                3'b111:  bus[i].value = RStoALU[i].alu_src1 & RStoALU[i].alu_src2;
            endcase
        end
        else
        begin
            bus[i].valid = 1'b0;
            bus[i].dest_rob = '0;
            bus[i].value = '0;
        end
    end

    
end
endmodule

module cmp
(
    input rv_structs::RStoCMP RStoCMP,

    output rv_structs::data_bus_CMP data_bus_CMP
);

always_comb
begin
    if(RStoCMP.ld_cmp)
    begin
        data_bus_CMP.valid = 1'b1;
        data_bus_CMP.dest_rob = RStoCMP.rob_idx;
        unique case (RStoCMP.cmp_op)
            3'b000: data_bus_CMP.value = (RStoCMP.cmp_src1 == RStoCMP.cmp_src2);
            3'b001: data_bus_CMP.value = (RStoCMP.cmp_src1 != RStoCMP.cmp_src2);
            3'b100: data_bus_CMP.value = ($signed(RStoCMP.cmp_src1)<$signed(RStoCMP.cmp_src2));
            3'b101: data_bus_CMP.value = ($signed(RStoCMP.cmp_src1)>=$signed(RStoCMP.cmp_src2));
            3'b110: data_bus_CMP.value = (RStoCMP.cmp_src1<RStoCMP.cmp_src2);
            3'b111: data_bus_CMP.value = (RStoCMP.cmp_src1>=RStoCMP.cmp_src2);
        endcase
    end
    else
    begin
        data_bus_CMP.valid = 1'b0;
        data_bus_CMP.dest_rob = '0;
        data_bus_CMP.value = '0;
    end
end
endmodule

module cmp_br
(
    input rv_structs::RStoCMP_br RStoCMP_br,

    output rv_structs::data_bus_CMP_br data_bus_CMP_br
);

always_comb
begin
    if(RStoCMP_br.ld_cmp)
    begin
        data_bus_CMP_br.valid = 1'b1;
        data_bus_CMP_br.br_pc_out = RStoCMP_br.br_pc_in1_value + RStoCMP_br.br_pc_in2_value;
        data_bus_CMP_br.pc = RStoCMP_br.pc;
        data_bus_CMP_br.is_jump = RStoCMP_br.is_jump;
        data_bus_CMP_br.is_jump_r = RStoCMP_br.is_jump_r;
		  data_bus_CMP_br.dest_rob = RStoCMP_br.rob_idx;
        unique case (RStoCMP_br.cmp_op)
            3'b000: data_bus_CMP_br.value = (RStoCMP_br.cmp_src1 == RStoCMP_br.cmp_src2);
            3'b001: data_bus_CMP_br.value = (RStoCMP_br.cmp_src1 != RStoCMP_br.cmp_src2);
            3'b100: data_bus_CMP_br.value = ($signed(RStoCMP_br.cmp_src1)<$signed(RStoCMP_br.cmp_src2));
            3'b101: data_bus_CMP_br.value = ($signed(RStoCMP_br.cmp_src1)>=$signed(RStoCMP_br.cmp_src2));
            3'b110: data_bus_CMP_br.value = (RStoCMP_br.cmp_src1<RStoCMP_br.cmp_src2);
            3'b111: data_bus_CMP_br.value = (RStoCMP_br.cmp_src1>=RStoCMP_br.cmp_src2);
        endcase
    end
    else
    begin
        data_bus_CMP_br.valid = 1'b0;
        data_bus_CMP_br.br_pc_out = '0;
        data_bus_CMP_br.value = '0;
		  data_bus_CMP_br.dest_rob = '0;
    end
end

endmodule

module alu_ld_st
(
    input rv_structs::RStoALU_ld_st RStoALU_ld_st,

    output rv_structs::data_bus_ld_st data_bus_ld_st
);

always_comb
begin

    if(RStoALU_ld_st.ld_alu)
    begin
        data_bus_ld_st.valid = 1'b1;
        data_bus_ld_st.dest_rob = RStoALU_ld_st.rob_idx;
        unique case (RStoALU_ld_st.alu_op)
            3'b000:  data_bus_ld_st.value = RStoALU_ld_st.alu_src1 + RStoALU_ld_st.alu_src2;
            3'b001:  data_bus_ld_st.value = RStoALU_ld_st.alu_src1 << RStoALU_ld_st.alu_src2;
            3'b010:  data_bus_ld_st.value = $signed(RStoALU_ld_st.alu_src1) >>> RStoALU_ld_st.alu_src2[4:0];
            3'b011:  data_bus_ld_st.value = RStoALU_ld_st.alu_src1 - RStoALU_ld_st.alu_src2;
            3'b100:  data_bus_ld_st.value = RStoALU_ld_st.alu_src1 ^ RStoALU_ld_st.alu_src2;
            3'b101:  data_bus_ld_st.value = RStoALU_ld_st.alu_src1 >> RStoALU_ld_st.alu_src2[4:0];
            3'b110:  data_bus_ld_st.value = RStoALU_ld_st.alu_src1 | RStoALU_ld_st.alu_src2;
            3'b111:  data_bus_ld_st.value = RStoALU_ld_st.alu_src1 & RStoALU_ld_st.alu_src2;
        endcase
    end
    else
    begin
        data_bus_ld_st.valid = 1'b0;
        data_bus_ld_st.dest_rob = '0;
        data_bus_ld_st.value = '0;
    end
end
endmodule