`include "../hdl/cir_q/cir_q.sv"
`define LOG $error("%s", s);  $fdisplay(fd, "%s", s)
module cir_q_tb;
    string s;
    int fd;

    bit clk, rst, issue, commit, update;
    bit cir_q_full, cir_q_empty, l_commit_dbg;
    bit [4:0] issue_ptr_dbg, commit_ptr_dbg;
    bit [4:0] rindex_dbg, windex_dbg, update_index;
    bit [31:0] datain_issue, datain_update, dataout;

    always #5 clk =  (clk === 1'b0);

    default clocking cb @(posedge clk);
        input issue_ptr_dbg, commit_ptr_dbg, l_commit_dbg;
        input cir_q_full, cir_q_empty, rindex_dbg, windex_dbg;
        output rst, issue, commit, update, datain_issue, datain_update, update_index;
    endclocking

    cir_q dut(.*);

    initial begin
        fd = $fopen("./cir_q_ver_log.txt", "w");
        if (fd == 0) begin
            $error("%s %0d: Unable to create/open log file(s)",
                            `__FILE__, `__LINE__);
            $exit;
        end
    end 

    final begin
        $fclose(fd);
    end

    task reset;
        cb.issue <= 1'b0;
        cb.commit <= 1'b0;
        cb.update <= 1'b0;
        cb.rst <= 1'b1;
        ##5;

        cb.rst <= 1'b0;
        ##5;

        assert (cb.cir_q_empty) else begin
            $sformat(s, "@%0t TB : cir_q_empty mismatch on reset", $time);
            `LOG;
        end
    endtask : reset

    task issue_1_test;
        cb.issue <= 1'b1;
        ##1;
        cb.issue <= 1'b0;
        ##1;

        assert (cb.issue_ptr_dbg == 1) else begin
            $sformat(s, "@%0t TB : issue_ptr mismatch on 1 issue", $time);
            `LOG;
        end

        assert (cb.cir_q_empty == 0) else begin
            $sformat(s, "@%0t TB : cir_q_empty mismatch on 1 issue", $time);
            `LOG;
        end

        assert (cb.cir_q_full == 0) else begin
            $sformat(s, "@%0t TB : cir_q_full mismatch on 1 issue", $time);
            `LOG;
        end        
    endtask : issue_1_test

    task commit_1_test;
        cb.commit <= 1'b1;
        ##1;
        cb.commit <= 1'b0;
        ##1;

        assert(cb.l_commit_dbg == 1) else begin
            $sformat(s, "@%0t TB : l_commit_dbg mismatch on 1 commit", $time);
            `LOG;
        end

        assert (cb.cir_q_empty == 1) else begin
            $sformat(s, "@%0t TB : cir_q_empty mismatch on 1 commit", $time);
            `LOG;
        end
    endtask

    task issue_3_commit_3_test();
        // @(cb.cir_q_empty);
        for (int i = 0; i < 3; i++) begin
            cb.issue <= 1'b1;
            ##1;
            cb.issue <= 1'b0;
            ##1;
        end
        for (int i = 0; i < 3; i++) begin
            cb.commit <= 1'b1;
            ##1;
            cb.commit <= 1'b0;
            ##1;
        end

        assert (cb.cir_q_empty == 1) else begin
            $sformat(s, "@%0t TB : cir_q_empty mismatch on 3 issues, and 3 commits", $time);
            `LOG;
        end
    endtask : issue_3_commit_3_test

    // Test 32 Issues
    task issue_32_test;
        for (int i = 0; i < 32; i++) begin
            cb.issue <= 1'b1;
            ##1;
            cb.issue <= 1'b0;
            ##1;
        end

        assert (cb.cir_q_empty == 0) else begin
            $sformat(s, "@%0t TB : cir_q_empty mismatch on 1 commit", $time);
            `LOG;
        end

        assert (cb.cir_q_full == 1) else begin
            $sformat(s, "@%0t TB : cir_q_full mismatch on 32 commits", $time);
            `LOG;
        end
    endtask : issue_32_test

    task issue_overflow_test;
        cb.issue <= 1'b1;
        ##1;
        cb.issue <= 1'b0;
        ##1;

        assert(cb.cir_q_full) else begin
            $sformat(s, "@%0t TB : cir_q not full on issue overflow", $time);
                `LOG;
        end

        assert(cb.issue_ptr_dbg == 0) else begin   
            $sformat(s, "@%0t TB : incorrect issue_ptr on issue overflow", $time);
                `LOG;
        end

        assert(cb.commit_ptr_dbg == 0) else begin
            $sformat(s, "@%0t TB : commit_ptr changed on issue", $time);
                `LOG;
        end

    endtask: issue_overflow_test

    // Test 32 Commits after 32 Issues
    task commit_32_test;
        for (int i = 0; i < 32; i++) begin
            cb.commit <= 1'b1;
            ##1;
            cb.commit <= 1'b0;
            ##1;
        end

        assert(cb.issue_ptr_dbg == 0) else begin
            $sformat(s, "@%0t TB : issue_ptr mismatch on 32 Commits", $time);
                `LOG;
        end

        assert(cb.commit_ptr_dbg == 0) else begin // Because cir_q is empty now, we cannot simulate circularity for commit_ptr
            $sformat(s, "@%0t TB : commit_ptr mismatch on 32 Commits", $time);
                `LOG;
        end

        assert (cb.cir_q_empty == 1) else begin
            $sformat(s, "@%0t TB : cir_q_empty mismatch on 32 Commits", $time);
            `LOG;
        end

        assert (cb.cir_q_full == 0) else begin
            $sformat(s, "@%0t TB : cir_q_full mismatch on 32 Commits", $time);
            `LOG;
        end
    endtask: commit_32_test

    task commit_overflow_test();
        cb.commit <= 1'b1;
        ##1;
        cb.commit <= 1'b0;
        ##1;

        assert(cb.cir_q_empty == 1) else begin
            $sformat(s, "@%0t TB : cir_q_empty mismatch on 32 Commits", $time);
            `LOG;
        end

        assert(cb.commit_ptr_dbg == 0) else begin
            $sformat(s, "@%0t TB : commit_ptr_dbg mismatch on 32 Commits", $time);
            `LOG;
        end
    endtask

    task cir_q_full_test();
        issue_32_test();

        for (int i = 0; i < 6; i++) begin
            cb.commit <= 1'b1;
            ##1;
            cb.commit <= 1'b0;
            ##1;
        end

        for (int i = 0; i < 6; i++) begin
            cb.issue <= 1'b1;
            ##1;
            cb.issue <= 1'b0;
            ##1;
        end

        assert (cb.cir_q_full == 1) else begin
            $sformat(s, "@%0t TB : cir_q_full mismatch on cir_q Full Test", $time);
            `LOG;
        end
    endtask

    task simul_issue_commit();
        issue_1_test();

        for (int i = 0; i < 31; i++) begin
            cb.issue <= 1'b1;
            cb.commit <= 1'b1;
            ##1;
            cb.issue <= 1'b0;
            cb.commit <= 1'b0;
            ##1;
        end

        cb.commit <= 1'b1;
        ##1;
        cb.commit <= 1'b0;
        ##1;

        assert (cb.issue_ptr_dbg == 0 & cb.commit_ptr_dbg == 0) else begin
            $sformat(s, "@%0t TB : issue_ptr_dbg, commit_ptr_dbg mismatch on simul_issue_commit", $time);
            `LOG;
        end

        assert(cb.cir_q_empty == 1) else begin
            $sformat(s, "@%0t TB : cir_q_empty mismatch on simul_issue_commit", $time);
            `LOG;
        end

        assert(cb.cir_q_full == 0) else begin
            $sformat(s, "@%0t TB : cir_q_full mismatch on simul_issue_commit", $time);
            `LOG;
        end
    endtask

    task update_test();
        issue_32_test();

        update_index <= 8;
        update <= 1'b1;
        ##1;
        update <= 1'b0;
        ##1;

        commit_32_test();

        assert(cb.cir_q_empty == 1) else begin
            $sformat(s, "@%0t TB : cir_q_empty mismatch on simul_issue_commit", $time);
            `LOG;
        end
    endtask

    initial begin
        $display("Resetting");
        reset();

        /* Comment out every other block before executing block x; x = 1,2,3,4 */

        // Block 1
        // $display("Single Issue Test");
        // issue_1_test();
        // $display("Single Commit Test");
        // commit_1_test();
        // @(cb iff cb.cir_q_empty);
        // $display("3 Issues 3 Commits Test");
        // issue_3_commit_3_test();
        // @(cb iff cb.cir_q_empty);

        // Block 2
        // @(cb iff cb.cir_q_empty);
        // $display("32 Issues Test");
        // issue_32_test();
        // @(cb iff cb.cir_q_full);
        // $display("Issue Overflow Test");
        // issue_overflow_test();
        // $display("32 Commits Test");
        // commit_32_test();
        // $display("Commit Overflow Test");
        // commit_overflow_test();
        // @(cb iff cb.cir_q_empty);

        // Block 3
        // @(cb iff cb.cir_q_empty);
        // $display("32 Issues Test");
        // issue_32_test();
        // $display("1 Commit Test");
        // commit_1_test();

        // Block 4
        // @(cb iff cb.cir_q_empty);
        // $display("cir_q Full Test : 32 Issues, 6 Commits, 6 Issues");
        // cir_q_full_test();

        // Block 5
        // $display("Simultaneous Issues, Commit Test");
        // simul_issue_commit();

        // Block 6
        $display("Update Test");
        update_test();

        $display("Tests complete");
        $finish;
    end

endmodule : cir_q_tb



