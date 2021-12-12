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

    input logic [1:0] RS_unit1, RS_unit2, RS_unit3, RS_unit4, RS_unit5, // ALU
    input logic [1:0] RS_unit6,     // CMP
    input logic [1:0] RS_unit7, RS_unit8,     // Special br RS

    input rv_structs::data_bus bus[5],
    
    input sched_structs::RFtoIQ RFtoIQ,
    input logic br_RS_full,
    input logic ld_st_RS_full,
    input logic ROBtoIQ_br_jump_present,
    input logic br_st_q_empty,              //br_st_manager -> Inst. Sched.
    input logic br_st_q_full,
    
    output logic commit_inst_q,           // SCHD -> IQ
    output logic [31:0] pc_new,
    output logic [1:0] pcmux_sel,               // IQ   -> Fetch Unit
    output logic is_op_br,  

    output logic issue_br_st_q,            // Inst. Sched. -> br_st_manager                        

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

logic [9:0] freeRSALU;
logic [1:0] freeRSCMP;
logic [3:0] freeRSBR;

arith_funct3_t arith_funct3;
branch_funct3_t branch_funct3;
load_funct3_t load_funct3;

assign freeRSALU = {RS_unit1, RS_unit2, RS_unit3, RS_unit4, RS_unit5};
assign freeRSCMP = RS_unit6;
assign freeRSBR = {RS_unit7, RS_unit8};

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
	pc_new = '0;
    is_op_br = 1'b0;
    issue_br_st_q = 1'b0;

    IQtoRF = '{default: '0};
    IQtoROB = '{default: '0};
    IQtoRS = '{default: '0};
    IQtoLD_ST = '{default: '0};
    IQtoRS_br = '{default: '0};
    IQtoRS_ld_st = '{default: '0};

    if (~rob_q_full & ~inst_q_empty & ~br_st_q_full) begin

        commit_inst_q = 1'b1;       // increment commit_ptr in IQ; bound to change further down the combinational logic
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
        op_load, op_jalr,
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

        op_lui, op_jal,
        op_auipc:   ;
        endcase

        // RegFile look-up done. Issue inst. to RS, ROB, and RF
        if ((RFtoIQ.lookup_valid_1 | RFtoIQ.lookup_valid_2) | (opcode == op_lui) | (opcode == op_auipc) | (opcode == op_jal)) begin
            unique case (opcode)
            op_load :   begin
                if (ld_st_RS_full | ~br_st_q_empty) commit_inst_q = 1'b0;
                else begin
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
            end

            op_store:   begin
                if (ld_st_RS_full | ~br_st_q_empty) commit_inst_q = 1'b0;
                else begin
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
                IQtoLD_ST.funct3 = load_funct3;

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
            end

            op_imm  :   begin
                unique case (arith_funct3)
                    slt     :   begin
                        if (freeRSCMP == '1) commit_inst_q = 1'b0;
                        IQtoRS.alu_ops = 3'b100;       // TODO:: cmp module
                    end
                    sltu    :   begin
                        if (freeRSCMP == '1) commit_inst_q = 1'b0;
                        IQtoRS.alu_ops = 3'b110;
                    end
                    sr      :   begin
                        if (freeRSALU == '1) commit_inst_q = 1'b0;
                        IQtoRS.alu_ops = funct7[5] ? 3'b010 : 3'b101; 
                    end
                    add, sll, axor, aor,
                    aand    :   begin
                        if (freeRSALU == '1) commit_inst_q = 1'b0;
                        IQtoRS.alu_ops = funct3;
                    end
                endcase

                if (commit_inst_q) begin
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
            end

            op_reg  :   begin
                unique case (arith_funct3)
                    slt     :   begin
                        if (freeRSCMP == '1) commit_inst_q = 1'b0;
                        IQtoRS.alu_ops = 3'b100; 
                    end    
                    sltu    :   begin
                        if (freeRSCMP == '1) commit_inst_q = 1'b0;
                        IQtoRS.alu_ops = 3'b110;
                    end
                    sr      :   begin
                        if (freeRSALU == '1) commit_inst_q = 1'b0;
                        IQtoRS.alu_ops = funct7[5] ? 3'b010 : 3'b101;
                    end 
                    sll, axor, aor,
                    aand    :   begin
                        if (freeRSALU == '1) commit_inst_q = 1'b0;
                        IQtoRS.alu_ops = funct3;
                    end
                    add     :   begin
                        if (freeRSALU == '1) commit_inst_q = 1'b0;
                        IQtoRS.alu_ops = funct7[5] ? 3'b011 : 3'b000;
                    end
                endcase

                if (commit_inst_q) begin
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
                is_op_br = 1'b1;

                if (br_RS_full == '1) commit_inst_q = 1'b0;
                else begin
                IQtoRS_br.alu_ops = funct3;
                issue_br_st_q = 1'b1;

                if (RFtoIQ.valid_1) begin
                    IQtoRS_br.src1_valid = 1'b1;
                    IQtoRS_br.src1_value = RFtoIQ.val_1;
                end
                else begin
                    IQtoRS_br.src1_valid = 1'b0;
                    IQtoRS_br.src1_rob = RFtoIQ.val_1[4:0];
                end
                if (RFtoIQ.valid_2) begin
                    IQtoRS_br.src2_valid = 1'b1;
                    IQtoRS_br.src2_value = RFtoIQ.val_2;
                end
                else begin
                    IQtoRS_br.src2_valid = 1'b0;
                    IQtoRS_br.src2_rob = RFtoIQ.val_2[4:0];
                end

                IQtoROB.dr = rd;
                IQtoROB.rob_issue = 1'b1;
                IQtoROB.is_br = 1'b1;

                IQtoRS_br.load_RS = 1'b1;
                IQtoRS_br.br_pc_in1_value = pc_out_val;
                IQtoRS_br.br_pc_in2_value = b_imm;
                IQtoRS_br.br_pc_in1_valid = 1'b1;
                IQtoRS_br.br_pc_in2_valid = 1'b1;
                IQtoRS_br.pc = pc_out_val;
                IQtoRS_br.dest_rob = rob_issue_ptr;

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
            end

            op_jal  :   begin
                if (br_RS_full == '1) commit_inst_q = 1'b0;
                else begin
                    issue_br_st_q = 1'b1;
                    IQtoRS_br.load_RS = 1'b1;
                    IQtoRS_br.is_jump = 1'b1;
                    IQtoRS_br.dest_rob = rob_issue_ptr;
                    IQtoRS_br.alu_ops = 3'b000;
                    IQtoRS_br.src1_valid = 1'b1;
                    IQtoRS_br.src1_value = '0;
                    IQtoRS_br.src2_valid = 1'b1;
                    IQtoRS_br.src2_value = '0;
                    IQtoRS_br.br_pc_in1_valid = 1'b1;
                    IQtoRS_br.br_pc_in2_valid = 1'b1;
                    IQtoRS_br.br_pc_in1_value = pc_out_val;
                    IQtoRS_br.br_pc_in2_value = j_imm;
                    IQtoRS_br.pc = pc_out_val;

                    IQtoRF.rd = rd;
                    IQtoRF.rob_index = rob_issue_ptr;
                    IQtoRF.write = 1'b1;

                    IQtoROB.dr = rd;
                    IQtoROB.rob_issue = 1'b1;
                    IQtoROB.load_imm = 1'b1;
                    IQtoROB.load_imm_val = pc_out_val + 4;
                    IQtoROB.is_jump = 1'b1;
                end
            end

            op_jalr :   begin
                if (br_RS_full == '1) commit_inst_q = 1'b0;
                else begin
                    issue_br_st_q = 1'b1;
                    IQtoRS_br.load_RS = 1'b1;
                    IQtoRS_br.is_jump_r = 1'b1;
                    IQtoRS_br.dest_rob = rob_issue_ptr;
                    IQtoRS_br.alu_ops = 3'b000;
                    IQtoRS_br.src1_valid = 1'b1;
                    IQtoRS_br.src1_value = '0;
                    IQtoRS_br.src2_valid = 1'b1;
                    IQtoRS_br.src2_value = '0;

                    if(RFtoIQ.valid_1) begin             // RegFile responded and operand 1 is ready
                        IQtoRS_br.br_pc_in1_value = RFtoIQ.val_1; 
                        IQtoRS_br.br_pc_in1_valid = 1'b1;  
                    end
                    else begin                          // RegFile responded but operand 1 is not ready
                        IQtoRS_br.br_pc_in1_rob = RFtoIQ.val_1[4:0];
                        IQtoRS_br.br_pc_in1_valid = 1'b0;  
                    end

                    IQtoRS_br.br_pc_in2_valid = 1'b1;
                    IQtoRS_br.br_pc_in2_value = i_imm;
                    IQtoRS_br.pc = pc_out_val;

                    for (int i = 0; i < 5; i++) begin
                        if (bus[i].valid & ~RFtoIQ.valid_1 & (bus[i].dest_rob == RFtoIQ.val_1[4:0])) begin
                            IQtoRS_br.br_pc_in1_value = bus[i].value;
                            IQtoRS_br.br_pc_in1_valid = 1'b1;
                        end
                    end

                    IQtoRF.rd = rd;
                    IQtoRF.rob_index = rob_issue_ptr;
                    IQtoRF.write = 1'b1;

                    IQtoROB.dr = rd;
                    IQtoROB.rob_issue = 1'b1;
                    IQtoROB.load_imm = 1'b1;
                    IQtoROB.is_jump = 1'b1;
                    IQtoROB.load_imm_val = pc_out_val + 4;
                end
            end
            endcase

            if (~freeRSBR[3])
                IQtoRS_br.RS_sel = 0;
            else if (~freeRSBR[1])
                IQtoRS_br.RS_sel = 2;
            else if (~freeRSBR[2])
                IQtoRS_br.RS_sel = 1;
            else if (~freeRSBR[0])
                IQtoRS_br.RS_sel = 3; 

            if(~freeRSALU[9])
                IQtoRS.RS_sel = 0;
            else if(~freeRSALU[7])
                IQtoRS.RS_sel = 2;
            else if(~freeRSALU[5])
                IQtoRS.RS_sel = 4;
            else if(~freeRSALU[3])
                IQtoRS.RS_sel = 6;
            else if(~freeRSALU[1])
                IQtoRS.RS_sel = 8;
            else if(~freeRSALU[8])
                IQtoRS.RS_sel = 1;
            else if(~freeRSALU[6])
                IQtoRS.RS_sel = 3;
            else if(~freeRSALU[4])
                IQtoRS.RS_sel = 5;
            else if(~freeRSALU[2])
                IQtoRS.RS_sel = 7;
            else if(~freeRSALU[0])
                IQtoRS.RS_sel = 9;
             

            if (opcode == op_imm | opcode == op_reg) begin
                if (arith_funct3 == slt | arith_funct3 == sltu) begin
                    unique case(freeRSCMP)
                        2'b00   :   IQtoRS.RS_sel = 10;
                        2'b01   :   IQtoRS.RS_sel = 10;
                        2'b10   :   IQtoRS.RS_sel = 11;
                        2'b11   :   ;
                    endcase
                end
            end
        
        end
    end
end

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