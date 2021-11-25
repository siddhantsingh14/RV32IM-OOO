// //the rob has 4 data entries, The DR, Done bit, Valid bit and the value that it stores. 
// import rob_entry_structs::*;    //importing the structs
// import rv_structs::*;
// import sched_structs::*;

// module testing_top(
//     input clk,
//     input rst,
    
//     input rv_structs::IQtoRS IQtoRS,
//     input sched_structs::IQtoRF IQtoRF,
//     // input rv_structs::data_bus bus[5],   //need to add inputs from the Instr. Scheduler. Will need the following signals. DR REGISTER, ISSUE SIGNAL
//     // input [4:0] DR_entry_issue,
//     // input issue,
//     input sched_structs::IQtoROB IQtoROB,
//     output rob_entry_structs::rob_to_regfile rob_regfile_bus,    //can create an array to increase the bus size
//     output logic cir_q_full, cir_q_empty
// );


// logic [1:0] RS_unit1, RS_unit2, RS_unit3, RS_unit4, RS_unit5;
// logic [4:0] issue_mod_out, commit_mod_out;
// logic commit_ready, commit;
// sched_structs::RFtoIQ RFtoIQ;
// // rob_entry_structs::rob_to_regfile rob_regfile_bus;
// rv_structs::data_bus bus[5];
// // logic cir_q_full, cir_q_empty;

// rob rob_inst(.*);

// commit_controller controller_inst(.*);

// regfile regfile_inst(.*);

// RS_ALU reservation_station_inst(.*);

// endmodule