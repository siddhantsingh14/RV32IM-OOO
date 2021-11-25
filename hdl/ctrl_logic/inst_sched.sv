import rv_structs::*;
import sched_structs::*;
import Ld_St_structs::*;

module inst_sched(
    input clk, 
    input rst, 

    input logic [31:0] pc_out_val,      // IQ   -> Fetch Unit
    input logic [31:0] inst,        // IQ   -> SCHD
    input logic rob_q_full,         // ROB  -> SCHD
    input logic [4:0] rob_issue_ptr,      // ROB  -> SCHD
    input logic inst_q_empty,       // IQ   -> SCHD

    input logic [1:0] RS_unit1, RS_unit2, RS_unit3, RS_unit4, RS_unit5, // RS   -> IQ
    input logic [1:0] RS_unit6, 

    input rv_structs::data_bus bus[5],
    
    input sched_structs::RFtoIQ RFtoIQ,
    input logic br_RS_full,
    input logic ld_st_RS_full,
    
    output logic commit_inst_q,           // SCHD -> IQ
    output logic [31:0] pc_new,
    output logic [1:0] pcmux_sel,               // IQ   -> Fetch Unit
    output logic is_op_br,                          

    output sched_structs::IQtoRF IQtoRF,
    output sched_structs::IQtoROB IQtoROB,
    output Ld_St_structs::IQtoLD_ST IQtoLD_ST,

    output rv_structs::IQtoRS IQtoRS,   // IQ   -> RS
    // output rv_structs::IQtoRS_br IQtoRS_br,
    // output Ld_St_structs::IQtoLD_ST IQtoLD_ST //issue, ld/st, mem_addr, write_data, src_rob, valid for ST; dest Rob for LD
    output rv_structs::IQtoRS_br IQtoRS_br,
    output sched_structs::IQtoRS_ld_st IQtoRS_ld_st
);

logic [2:0] funct3;
logic [6:0] funct7;
rv32i_opcode opcode;
logic [31:0] i_imm;
logic [31:0] s_imm;
logic [31:0] b_imm;
logic [31:0] u_imm;
logic [31:0] j_imm;
logic [4:0] rs1;
logic [4:0] rs2;
logic [4:0] rd;
logic br_en_inst_schd;
logic RS_availability_flag;
logic RS_availability_flag_cmp;

logic [31:0] br_CMP_a, br_CMP_b, br_ALU_a, br_ALU_b, br_ALU_out;
logic load_br_CMP, load_br_ALU;

arith_funct3_t arith_funct3;
branch_funct3_t branch_funct3;
load_funct3_t load_funct3;

always_comb begin
    commit_inst_q = 1'b0;       
    funct3 = '0;                
    funct7 = '0;
    opcode = rv32i_opcode'('0);
    i_imm = '0;
    s_imm = '0;
    b_imm = '0;
    u_imm = '0;
    j_imm = '0;
    rs1 = '0;
    rs2 = '0;
    arith_funct3 = arith_funct3_t'('0);
    branch_funct3 = branch_funct3_t'('0);
    load_funct3 = load_funct3_t'('0);
    rd = '0;
    pcmux_sel = '0;
    // load_pc = '0;
    load_br_CMP = '0;
    load_br_ALU = '0;
    br_ALU_a = '0;
    br_ALU_b = '0;
    br_CMP_a = '0;
    br_CMP_b = '0;
	pc_new = '0;
    is_op_br = 1'b0;

    RS_availability_flag='0;
    RS_availability_flag_cmp='0;

    IQtoRF = '{default: '0};
    IQtoROB = '{default: '0};
    IQtoRS = '{default: '0};
    IQtoLD_ST = '{default: '0};
    IQtoRS_br = '{default: '0};
    IQtoRS_ld_st = '{default: '0};

    //TODO :: Add logic for checking if at least one RS is available

    if (~rob_q_full & ~inst_q_empty & ~ld_st_RS_full & ~br_RS_full & (~(RS_unit1 == '1 & RS_unit2 == '1  & RS_unit3 == '1 & RS_unit4 == '1 & RS_unit5 == '1 & RS_unit6 == '1))) begin

        commit_inst_q = 1'b1;       // increment commit_ptr in IQ
        funct3 = inst[14:12];
        funct7 = inst[31:25];
        opcode = rv32i_opcode'(inst[6:0]);
        i_imm = {{21{inst[31]}}, inst[30:20]};
        s_imm = {{21{inst[31]}}, inst[30:25], inst[11:7]};
        b_imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
        u_imm = {inst[31:12], 12'h000};
        j_imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
        rs1 = inst[19:15];
        rs2 = inst[24:20];
        rd = inst[11:7];
        arith_funct3 = arith_funct3_t'(funct3);
        branch_funct3 = branch_funct3_t'(funct3);
        load_funct3 = load_funct3_t'(funct3);

        // RegFile Look-Up here
        unique case (opcode)
        op_load,
        op_imm  :   begin
            IQtoRF.lookup_regfile_1 = 1'b1;
            IQtoRF.reg_idx_1 = rs1;
            IQtoRF.lookup_regfile_2 = 1'b0;
        end
        op_br, op_store,
        op_reg  :   begin
            IQtoRF.lookup_regfile_1 = 1'b1;
            IQtoRF.reg_idx_1 = rs1;
            IQtoRF.lookup_regfile_2 = 1'b1;
            IQtoRF.reg_idx_2 = rs2;
        end

        op_lui, 
        op_auipc:   ;
        endcase

        // RegFile look-up done. Issue inst. to RS, ROB, and RF
        if ((RFtoIQ.lookup_valid_1 | RFtoIQ.lookup_valid_2) | (opcode == op_lui) | (opcode == op_auipc)) begin
            unique case (opcode)
            op_load :   begin
                if(RFtoIQ.valid_1) begin             // RegFile responded and operand 1 is ready
                    IQtoRS_ld_st.src1_val = RFtoIQ.val_1; 
                    IQtoRS_ld_st.src1_valid = 1'b1;  
                end
                else begin                          // RegFile responded but operand 1 is not ready
                    IQtoRS_ld_st.src1_rob = RFtoIQ.val_1[4:0];
                    IQtoRS_ld_st.src1_valid = 1'b0;  
                end

                for (int i = 0; i < 5; i++) begin
                    if (bus[i].valid & ~RFtoIQ.valid_1 & (bus[i].dest_rob == RFtoIQ.val_1[4:0])) begin
                        IQtoRS_ld_st.src1_val = bus[i].value;
                        IQtoRS_ld_st.src1_valid = 1'b1;
                    end
                end

                IQtoRS_ld_st.src2_val = i_imm;
                IQtoRS_ld_st.src2_valid = 1'b1;
                IQtoRS_ld_st.load_RS = 1'b1;
                IQtoRS_ld_st.dest_rob = rob_issue_ptr;

                IQtoROB.dr = rd;
                IQtoROB.rob_issue = 1'b1;

                IQtoRF.rd = rd;
                IQtoRF.rob_index = rob_issue_ptr;
                IQtoRF.write = 1'b1;

                IQtoLD_ST.issue = 1'b1;
                IQtoLD_ST.ld_st = 1'b0;
                IQtoLD_ST.src_rob_mem_addr = rob_issue_ptr;
                IQtoLD_ST.valid_src_mem_addr = 1'b0;
                IQtoLD_ST.dest_rob = rob_issue_ptr;
                IQtoLD_ST.funct3 = load_funct3;
            end

            op_store:   begin
                if(RFtoIQ.valid_1) begin     
                    IQtoRS_ld_st.src1_val = RFtoIQ.val_1; 
                    IQtoRS_ld_st.src1_valid = 1'b1;  
                end
                else begin                  
                    IQtoRS_ld_st.src1_rob = RFtoIQ.val_1[4:0];
                    IQtoRS_ld_st.src1_valid = 1'b0;  
                end
                if(RFtoIQ.valid_2)begin     
                    IQtoLD_ST.write_data = RFtoIQ.val_2; 
                    IQtoLD_ST.src_valid_write_data = 1'b1;   
                end
                else begin                  
                    IQtoLD_ST.src_rob_write_data = RFtoIQ.val_2[4:0];
                    IQtoLD_ST.src_valid_write_data = 1'b0;
                end

                for (int i = 0; i < 5; i++) begin
                    if (bus[i].valid & ~RFtoIQ.valid_1 & (bus[i].dest_rob == RFtoIQ.val_1[4:0])) begin
                        IQtoRS_ld_st.src1_val = bus[i].value;
                        IQtoRS_ld_st.src1_valid = 1'b1;
                    end
                end

                IQtoRS_ld_st.src2_val = s_imm;
                IQtoRS_ld_st.src2_valid = 1'b1;
                IQtoRS_ld_st.load_RS = 1'b1;
                IQtoRS_ld_st.dest_rob = rob_issue_ptr;

                IQtoLD_ST.issue = 1'b1;
                IQtoLD_ST.ld_st = 1'b1;
                IQtoLD_ST.mem_addr = '0;
                IQtoLD_ST.src_rob_mem_addr = rob_issue_ptr;
                IQtoLD_ST.valid_src_mem_addr = 1'b0;
                IQtoLD_ST.dest_rob = rob_issue_ptr;

                for (int i = 0; i < 5; i++) begin
                    if (bus[i].valid & ~RFtoIQ.valid_1 & (bus[i].dest_rob == RFtoIQ.val_1[4:0])) begin
                        IQtoRS.src1_value = bus[i].value;
                        IQtoRS.src1_valid = 1'b1;
                    end
                end

                IQtoROB.dr = rd;
                IQtoROB.rob_issue = 1'b1;
                IQtoROB.load_imm = 1'b1;
                IQtoROB.load_imm_val = 'x;
                IQtoROB.is_st = '1;
            end

            op_imm  :   begin
                if(RFtoIQ.valid_1) begin             // RegFile responded and operand 1 is ready
                    IQtoRS.src1_value = RFtoIQ.val_1; 
                    IQtoRS.src1_valid = 1'b1;  
                end
                else begin                          // RegFile responded but operand 1 is not ready
                    IQtoRS.src1_rob = RFtoIQ.val_1[4:0];
                    IQtoRS.src1_valid = 1'b0;  
                end
                IQtoRS.src2_value = i_imm;
                IQtoRS.src2_valid = 1'b1;
                IQtoRS.load_RS = 1'b1;
                IQtoRS.dest_rob = rob_issue_ptr;
                unique case (arith_funct3)
                    slt     :   IQtoRS.alu_ops = 3'b100;       // TODO:: cmp module
                    sltu    :   IQtoRS.alu_ops = 3'b110;
                    sr      :   IQtoRS.alu_ops = funct7[5] ? 3'b010 : 3'b101; 
                    add, sll, axor, aor,
                    aand    :   IQtoRS.alu_ops = funct3;
                endcase
                IQtoRF.rd = rd;
                IQtoRF.rob_index = rob_issue_ptr;
                IQtoRF.write = 1'b1;
                for (int i = 0; i < 5; i++) begin
                    if (bus[i].valid & ~RFtoIQ.valid_1 & (bus[i].dest_rob == RFtoIQ.val_1[4:0])) begin
                        IQtoRS.src1_value = bus[i].value;
                        IQtoRS.src1_valid = 1'b1;
                    end
                end
                IQtoROB.dr = rd;
                IQtoROB.rob_issue = 1'b1;
            end

            op_reg  :   begin
                if(RFtoIQ.valid_1) begin     
                    IQtoRS.src1_value = RFtoIQ.val_1; 
                    IQtoRS.src1_valid = 1'b1;  
                end
                else begin                  
                    IQtoRS.src1_rob = RFtoIQ.val_1[4:0];
                    IQtoRS.src1_valid = 1'b0;  
                end
                if(RFtoIQ.valid_2)begin     
                    IQtoRS.src2_value = RFtoIQ.val_2; 
                    IQtoRS.src2_valid = 1'b1;   
                end
                else begin                  
                    IQtoRS.src2_rob = RFtoIQ.val_2[4:0];
                    IQtoRS.src2_valid = 1'b0;
                end
                IQtoRS.load_RS = 1'b1;
                IQtoRS.dest_rob = rob_issue_ptr;
                unique case (arith_funct3)
                    slt     :   IQtoRS.alu_ops = 3'b100;       
                    sltu    :   IQtoRS.alu_ops = 3'b110;
                    sr      :   IQtoRS.alu_ops = funct7[5] ? 3'b010 : 3'b101; 
                    sll, axor, aor,
                    aand    :   IQtoRS.alu_ops = funct3;
                    add     :   IQtoRS.alu_ops = funct7[5] ? 3'b011 : 3'b000;
                endcase
                IQtoRF.rd = rd;
                IQtoRF.rob_index = rob_issue_ptr;
                IQtoRF.write = 1'b1;
                for (int i = 0; i < 5; i++) begin
                    if (bus[i].valid & ~RFtoIQ.valid_1 & (bus[i].dest_rob == RFtoIQ.val_1[4:0])) begin
                        IQtoRS.src1_value = bus[i].value;
                        IQtoRS.src1_valid = 1'b1;
                    end
                    if (bus[i].valid & ~RFtoIQ.valid_2 & (bus[i].dest_rob == RFtoIQ.val_2[4:0])) begin
                        IQtoRS.src2_value = bus[i].value;
                        IQtoRS.src2_valid = 1'b1;
                    end
                end
                IQtoROB.dr = rd;
                IQtoROB.rob_issue = 1'b1;
            end

            op_lui  :   begin      
                IQtoROB.load_imm = 1'b1;
                IQtoROB.load_imm_val = u_imm;
                IQtoRF.rd = rd;
                IQtoRF.rob_index = rob_issue_ptr;
                IQtoRF.write = 1'b1;
                IQtoROB.dr = rd;
                IQtoROB.rob_issue = 1'b1;
            end

            op_auipc:   begin
                IQtoRS.src1_value = u_imm; 
                IQtoRS.src1_valid = 1'b1;
                IQtoRS.src2_value = pc_out_val; 
                IQtoRS.src2_valid = 1'b1;
                IQtoRS.load_RS = 1'b1;
                IQtoRS.dest_rob = rob_issue_ptr;
                IQtoRS.alu_ops = 3'b000;
                IQtoRF.rd = rd;
                IQtoRF.rob_index = rob_issue_ptr;
                IQtoRF.write = 1'b1;
                IQtoROB.dr = rd;
                IQtoROB.rob_issue = 1'b1;
            end
            
            
            op_br   :   begin
                IQtoRS_br.alu_ops = funct3;
                is_op_br = 1'b1;

                if (RFtoIQ.valid_1) begin
                    IQtoRS_br.src1_valid = 1'b1;
                    IQtoRS_br.src1_value = RFtoIQ.val_1;
                end
                else begin
                    IQtoRS_br.src1_valid = 1'b0;
                    IQtoRS_br.src1_value = RFtoIQ.val_1[4:0];
                end
                if (RFtoIQ.valid_2) begin
                    IQtoRS_br.src2_valid = 1'b1;
                    IQtoRS_br.src2_value = RFtoIQ.val_2;
                end
                else begin
                    IQtoRS_br.src2_valid = 1'b0;
                    IQtoRS_br.src2_value = RFtoIQ.val_2[4:0];
                end
                
                load_br_ALU = 1'b1;
                br_ALU_a = pc_out_val;
                br_ALU_b = b_imm;
                IQtoRS_br.load_RS = 1'b1;
                IQtoRS_br.br_pc_out = br_ALU_out;

                for (int i = 0; i < 5; i++) begin       // handling bus broadcasts
                    if (bus[i].valid & ~RFtoIQ.valid_1 & (bus[i].dest_rob == RFtoIQ.val_1[4:0])) begin
                        IQtoRS_br.src1_value = bus[i].value;
                        IQtoRS_br.src1_valid = 1'b1;
                    end
                    if (bus[i].valid & ~RFtoIQ.valid_2 & (bus[i].dest_rob == RFtoIQ.val_2[4:0])) begin
                        IQtoRS_br.src2_value = bus[i].value;
                        IQtoRS_br.src2_valid = 1'b1;
                    end
                end
            end
            endcase

            // TODO::logic for IQtoRS.RS_sel 
            unique case(RS_unit1)
                00: begin
                    if(~RS_availability_flag)   begin
                        IQtoRS.RS_sel = 4'd0;
                        RS_availability_flag=1'b1;
                    end
                end
                01: begin
                    if(~RS_availability_flag)   begin
                        IQtoRS.RS_sel = 4'd1;
                        RS_availability_flag=1'b1;
                    end
                end
                10: begin
                    if(~RS_availability_flag)   begin
                        IQtoRS.RS_sel = 4'd0;
                        RS_availability_flag=1'b1;
                    end
                end
                11:;
            endcase

            unique case(RS_unit2)
                00: begin
                    if(~RS_availability_flag)   begin
                        IQtoRS.RS_sel = 4'd2;
                        RS_availability_flag=1'b1;
                    end
                end
                01: begin
                    if(~RS_availability_flag)   begin
                        IQtoRS.RS_sel = 4'd3;
                        RS_availability_flag=1'b1;
                    end
                end
                10: begin
                    if(~RS_availability_flag)   begin
                        IQtoRS.RS_sel = 4'd2;
                        RS_availability_flag=1'b1;
                    end
                end
                11:;
            endcase

            unique case(RS_unit3)
                00: begin
                    if(~RS_availability_flag)   begin
                        IQtoRS.RS_sel = 4'd4;
                        RS_availability_flag=1'b1;
                    end
                end
                01: begin
                    if(~RS_availability_flag)   begin
                        IQtoRS.RS_sel = 4'd5;
                        RS_availability_flag=1'b1;
                    end
                end
                10: begin
                    if(~RS_availability_flag)   begin
                        IQtoRS.RS_sel = 4'd4;
                        RS_availability_flag=1'b1;
                    end
                end
                11:;
            endcase

            unique case(RS_unit4)
                00: begin
                    if(~RS_availability_flag)   begin
                        IQtoRS.RS_sel = 4'd6;
                        RS_availability_flag=1'b1;
                    end
                end
                01: begin
                    if(~RS_availability_flag)   begin
                        IQtoRS.RS_sel = 4'd7;
                        RS_availability_flag=1'b1;
                    end
                end
                10: begin
                    if(~RS_availability_flag)   begin
                        IQtoRS.RS_sel = 4'd6;
                        RS_availability_flag=1'b1;
                    end
                end
                11:;
            endcase

            unique case(RS_unit5)
                00: begin
                    if(~RS_availability_flag)   begin
                        IQtoRS.RS_sel = 4'd8;
                        RS_availability_flag=1'b1;
                    end
                end
                01: begin
                    if(~RS_availability_flag)   begin
                        IQtoRS.RS_sel = 4'd9;
                        RS_availability_flag=1'b1;
                    end
                end
                10: begin
                    if(~RS_availability_flag)   begin
                        IQtoRS.RS_sel = 4'd8;
                        RS_availability_flag=1'b1;
                    end
                end
                11:;
            endcase

            if (opcode == op_imm) begin
                if (arith_funct3 == 3'b010 | arith_funct3 == 3'b011) begin
                    unique case(RS_unit6)
                    00: begin
                        if(~RS_availability_flag_cmp)   begin
                            IQtoRS.RS_sel = 4'd10;
                            RS_availability_flag_cmp=1'b1;
                        end
                    end
                    01: begin
                        if(~RS_availability_flag_cmp)   begin
                            IQtoRS.RS_sel = 4'd11;
                            RS_availability_flag_cmp=1'b1;
                        end
                    end
                    10: begin
                        if(~RS_availability_flag_cmp)   begin
                            IQtoRS.RS_sel = 4'd10;
                            RS_availability_flag_cmp=1'b1;
                        end
                    end
                    11:;
                    endcase
                end
            end

            if (opcode == op_reg) begin
                if (arith_funct3 == 3'b010 | arith_funct3 == 3'b011) begin
                    unique case(RS_unit6)
                    00: begin
                        if(~RS_availability_flag_cmp)   begin
                            IQtoRS.RS_sel = 4'd10;
                            RS_availability_flag_cmp=1'b1;
                        end
                    end
                    01: begin
                        if(~RS_availability_flag_cmp)   begin
                            IQtoRS.RS_sel = 4'd11;
                            RS_availability_flag_cmp=1'b1;
                        end
                    end
                    10: begin
                        if(~RS_availability_flag_cmp)   begin
                            IQtoRS.RS_sel = 4'd10;
                            RS_availability_flag_cmp=1'b1;
                        end
                    end
                    11:;
                    endcase
                end
            end

            // TODO::logic for accepting ALU broadcasts

            // Handling IQ -> ROB
        end
    end
end

cmp_schd br_CMP_schd (load_br_CMP, branch_funct3, br_CMP_a, br_CMP_b, br_en_inst_schd);
alu_schd br_ALU_schd (load_br_ALU, br_ALU_a, br_ALU_b, br_ALU_out);

endmodule : inst_sched

/*
    Will Inst. Sched. require capture logic incase the source operand is being 
    broadcasted in the same cycle while we are trying to issue an instruction 
    with the corresponding source operand? 

    No, in the next clock cycle I expect the inst. to be in the RS. In the RS, have the
    capture logic. Also, in the next clock cycle, the value be stored in the ROB index.
    If we have 1 cycle commits, we can expect the value to be available in the same 
    clock cycle in the regfile unit, though, it has not been written to the regfile yet.
    Would be written in the next clock cycle.
*/

/* TODO
    1. Appropriate logic for selecting the correct RS (of 10)
    2. Add RS_sel logic for ALUs, and CMPs as well
    3. Logic for accepting broadcast results
*/