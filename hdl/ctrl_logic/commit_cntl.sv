module commit_controller (
    input clk,
    input rst,

    input commit_ready,
    input cir_q_empty,
    // input [4:0] possible_commits,                   // commit signal from instruction scheduler to pop an inst.

    output logic commit
);


always_ff @(posedge clk) begin 
    if(rst)
        commit<=1'b0;
    else begin
        if(cir_q_empty)
            commit<=1'b0;
        else if(commit_ready)
            commit<=1'b1;
        else
            commit<=1'b0;
    end
    
end

endmodule