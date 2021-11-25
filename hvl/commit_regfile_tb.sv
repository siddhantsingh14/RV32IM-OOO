`include "../hdl/rob/testing_top.sv"
// `include "../hdl/ROB_struct.sv"
import rob_entry_structs::*;    //importing the structs
import rv_structs::*;
import sched_structs::*;
// `define LOG $error("%s", s);  $fdisplay(fd, "%s", s)
module commit_regfile_tb;

    logic clk;
    logic rst;
    rv_structs::data_bus bus[5];
    sched_structs::IQtoRF IQtoRF;
    logic [4:0] DR_entry_issue;
    logic issue;
    logic cir_q_full, cir_q_empty;
    // logic commit;
    rob_entry_structs::rob_to_regfile rob_regfile_bus;

    always #5 clk =  (clk === 1'b0);

    default clocking cb @(posedge clk);
        input cir_q_full, cir_q_empty, rob_regfile_bus;
        output bus, IQtoRF, DR_entry_issue, issue;
        output rst;
    endclocking

    testing_top dut (.*);

    task reset; //change the signals inside.
        cb.issue<=1'b0;
        // cb.commit<=1'b0;
        cb.bus[0].valid <=1'b0;
        cb.bus[1].valid <=1'b0;
        cb.bus[2].valid <=1'b0;
        cb.bus[3].valid <=1'b0;
        cb.bus[4].valid <=1'b0;
        cb.IQtoRF.write =1'b0;
        cb.IQtoRF.rd ='0;
        cb.IQtoRF.rob_index ='0;
        cb.IQtoRF.lookup_regfile_1 ='0;
        cb.IQtoRF.lookup_regfile_2 ='0;
        cb.rst <= 1'b1;
        ##5;

        cb.rst <= 1'b0;
        ##5;

        assert (cb.cir_q_empty) else begin
            $display("@%0t TB : cir_q_empty mismatch on reset", $time);
        end
    endtask : reset

    task IQ_issue;
        //IQ signals to regfile on issue
        cb.IQtoRF.write =1'b1;
        cb.IQtoRF.rd =5'd3;
        cb.IQtoRF.rob_index =5'd0;
        //IQ signals to ROB on issue
        cb.issue <= 1'b1;
        cb.DR_entry_issue <=5'd3;

        ##1
        cb.IQtoRF.write =1'b0;
        cb.issue <= 1'b0;
        $display("Issued first entry");
    endtask : IQ_issue

    task broadcast_test;
        bus[0].valid <=1'b1;
        bus[0].dest_rob <=5'd0;
        bus[0].value <=32'd156;
        ##1
        bus[0].valid <=1'b0;
        ##1

        $display("Updated first entry");

    endtask : broadcast_test

    task IQ_issue_another;
        //IQ signals to regfile on issue
        cb.IQtoRF.write =1'b1;
        cb.IQtoRF.rd =5'd3;
        cb.IQtoRF.rob_index =5'd1;
        //IQ signals to ROB on issue
        cb.issue <= 1'b1;
        cb.DR_entry_issue <=5'd3;

        ##1
        cb.IQtoRF.write =1'b0;
        cb.issue <= 1'b0;
        $display("Issued first entry");
    endtask : IQ_issue_another

    task broadcast_test_another;
        bus[0].valid <=1'b1;
        bus[0].dest_rob <=5'd1;
        bus[0].value <=32'd301;
        ##1
        bus[0].valid <=1'b0;
        ##1

        $display("Updated first entry");

    endtask : broadcast_test_another



    task test_32_issues;
        //checking issue for instruction R3, R2 +R1. Only significant for ROB is the DR R3 as the entry

        for (int i = 0; i < 32; i++) begin
            cb.IQtoRF.write =1'b1;
            cb.IQtoRF.rd =i;
            cb.IQtoRF.rob_index =i;

            cb.issue <= 1'b1;
            cb.DR_entry_issue <=i;
            ##1
            cb.IQtoRF.write =1'b0;
            cb.issue <= 1'b0;

            // ##1
            $display("Issued %d entries", i);
        end

        $display("Issued 32 entries");
        //queue should be full at this point
        assert (cb.cir_q_full) else begin
            $display("@%0t TB : cir_q_full mismatch on 32 issues", $time);
        end
    endtask : test_32_issues

    task test_updates;
        //checking issue for instruction R3, R2 +R1. Only significant for ROB is the DR R3 as the entry

        for (int i = 0; i < 5; i++) begin
            bus[i].valid <=1'b1;
            bus[i].dest_rob <=i;
            bus[i].value <=i + 200;
            ##1
            bus[i].valid <=1'b0;
            // ##1
            $display("Broadcasted %d entries", i);
        end

        $display("Broadcasted 5 entries");
        
        

    endtask : test_updates


    task test_5_issues;
        //checking issue for instruction R3, R2 +R1. Only significant for ROB is the DR R3 as the entry
        for (int i = 0; i < 5; i++) begin
            cb.IQtoRF.write =1'b1;
            cb.IQtoRF.rd =i+20;
            cb.IQtoRF.rob_index =i;

            cb.issue <= 1'b1;
            cb.DR_entry_issue <=i+20;
            ##1
            cb.IQtoRF.write =1'b0;
            cb.issue <= 1'b0;
            $display("Issued %d entries", i);
        end

        $display("Issued 5 entries");
        assert (cb.cir_q_full) else begin
            $display("@%0t TB : cir_q_full mismatch on 32 issues", $time);
        end

            

    endtask : test_5_issues

    task ooo_broadcast;

        bus[0].valid <=1'b1;
        bus[0].dest_rob <=8;
        bus[0].value <=208;

        bus[1].valid <=1'b1;
        bus[1].dest_rob <=14;
        bus[1].value <=214;

        bus[2].valid <=1'b1;
        bus[2].dest_rob <=7;
        bus[2].value <=207;

        bus[3].valid <=1'b1;
        bus[3].dest_rob <=12;
        bus[3].value <=212;
        
        bus[4].valid <=1'b1;
        bus[4].dest_rob <=5;
        bus[4].value <=205;

        ##1
        bus[0].valid <=1'b0;
        bus[1].valid <=1'b0;
        bus[2].valid <=1'b0;
        bus[3].valid <=1'b0;
        bus[4].valid <=1'b0;

        $display("Broadcasted entries 8, 14 , 7 ,12, 5");

        $display("Broadcasted 5 entries");
        $display("Testing simultaneous issue broadcast and commit");
        

        bus[0].valid <=1'b1;
        bus[0].dest_rob <=6;
        bus[0].value <=206;

        bus[1].valid <=1'b1;
        bus[1].dest_rob <=9;
        bus[1].value <=209;

        bus[2].valid <=1'b1;
        bus[2].dest_rob <=11;
        bus[2].value <=211;

        bus[3].valid <=1'b1;
        bus[3].dest_rob <=13;
        bus[3].value <=213;
        
        bus[4].valid <=1'b1;
        bus[4].dest_rob <=10;
        bus[4].value <=210;

        ##1
        bus[0].valid <=1'b0;
        bus[1].valid <=1'b0;
        bus[2].valid <=1'b0;
        bus[3].valid <=1'b0;
        bus[4].valid <=1'b0;

        ##1

        $display("Broadcasted entries 6, 9 , 11 ,13, 10");

        $display("Broadcasted 5  more entries");
        

    endtask : ooo_broadcast


    task ooo_broadcast_many;

        bus[0].valid <=1'b1;
        bus[0].dest_rob <=31;
        bus[0].value <=231;

        // bus[1].valid <=1'b1;
        // bus[1].dest_rob <=1;
        // bus[1].value <=201;

        bus[2].valid <=1'b1;
        bus[2].dest_rob <=16;
        bus[2].value <=216;

        bus[3].valid <=1'b1;
        bus[3].dest_rob <=20;
        bus[3].value <=220;
        
        bus[4].valid <=1'b1;
        bus[4].dest_rob <=23;
        bus[4].value <=223;

        ##1
        bus[0].valid <=1'b0;
        bus[1].valid <=1'b0;
        bus[2].valid <=1'b0;
        bus[3].valid <=1'b0;
        bus[4].valid <=1'b0;

        $display("Broadcasted entries 31, 1, 16, 20, 23");

        $display("Broadcasted 5 entries");
        $display("Testing simultaneous issue broadcast and commit");
        

        bus[0].valid <=1'b1;
        bus[0].dest_rob <=15;
        bus[0].value <=215;

        bus[1].valid <=1'b1;
        bus[1].dest_rob <=21;
        bus[1].value <=221;

        bus[2].valid <=1'b1;
        bus[2].dest_rob <=18;
        bus[2].value <=218;

        bus[3].valid <=1'b1;
        bus[3].dest_rob <=22;
        bus[3].value <=222;
        
        bus[4].valid <=1'b1;
        bus[4].dest_rob <=25;
        bus[4].value <=225;

        ##1
        bus[0].valid <=1'b0;
        bus[1].valid <=1'b0;
        bus[2].valid <=1'b0;
        bus[3].valid <=1'b0;
        bus[4].valid <=1'b0;

        $display("Broadcasted entries 15, 21, 18, 22, 25");

        $display("Broadcasted 5  more entries");

        bus[0].valid <=1'b1;
        bus[0].dest_rob <=26;
        bus[0].value <=226;

        bus[1].valid <=1'b1;
        bus[1].dest_rob <=29;
        bus[1].value <=229;

        bus[2].valid <=1'b1;
        bus[2].dest_rob <=30;
        bus[2].value <=230;

        bus[3].valid <=1'b1;
        bus[3].dest_rob <=28;
        bus[3].value <=228;
        
        bus[4].valid <=1'b1;
        bus[4].dest_rob <=27;
        bus[4].value <=227;

        ##1
        bus[0].valid <=1'b0;
        bus[1].valid <=1'b0;
        bus[2].valid <=1'b0;
        bus[3].valid <=1'b0;
        bus[4].valid <=1'b0;

        $display("Broadcasted entries 26, 29, 30, 28, 27");

        $display("Broadcasted 5 entries");
        $display("Testing simultaneous issue broadcast and commit");
        

        bus[0].valid <=1'b1;
        bus[0].dest_rob <=17;
        bus[0].value <=217;

        bus[1].valid <=1'b1;
        bus[1].dest_rob <=19;
        bus[1].value <=219;

        bus[2].valid <=1'b1;
        bus[2].dest_rob <=24;
        bus[2].value <=224;

        ##1
        bus[0].valid <=1'b0;
        bus[1].valid <=1'b0;
        bus[2].valid <=1'b0;

        ##1
        $display("Broadcasted entries 17, 19, 24");

        $display("Broadcasted 5  more entries");
        

    endtask : ooo_broadcast_many

    task ooo_broadcast_to_empty;

        bus[0].valid <=1'b1;
        bus[0].dest_rob <=0;
        bus[0].value <=220;

        bus[1].valid <=1'b1;
        bus[1].dest_rob <=1;
        bus[1].value <=221;

        bus[2].valid <=1'b1;
        bus[2].dest_rob <=3;
        bus[2].value <=223;

        bus[3].valid <=1'b1;
        bus[3].dest_rob <=2;
        bus[3].value <=222;
        
        bus[4].valid <=1'b1;
        bus[4].dest_rob <=4;
        bus[4].value <=224;

        ##1
        bus[0].valid <=1'b0;
        bus[1].valid <=1'b0;
        bus[2].valid <=1'b0;
        bus[3].valid <=1'b0;
        bus[4].valid <=1'b0;

        $display("Broadcasted entries 8, 14 , 7 ,12, 5");

        $display("Broadcasted 5 entries");
        

    endtask : ooo_broadcast_to_empty

    initial begin
        $display("Resetting");
        reset();
        
        // IQ_issue();
        // broadcast_test();
        
        // ##5 //waiting to see if commit happens on its own
        // $display("Waiting for commit to Regfile");
        // IQ_issue_another();
        // broadcast_test_another();
        test_32_issues();
        test_updates(); //change the loop parameter to broadcast more, but this is testing in-order completion
        // test_commits(); //change the loop parameter to commit more, but this is testing in-order completion
        ##3
        test_5_issues();    //testing issues in the spots that are opened up
        ooo_broadcast();    //testing oo completion now
        ooo_broadcast_many();
        ooo_broadcast_to_empty();
        ##30
        $display("@%0t TB: time is after waiting. Checking if commit happens on its own or not", $time);

        ##2

        $display("Tests complete");
        $finish;
    end

endmodule : commit_regfile_tb