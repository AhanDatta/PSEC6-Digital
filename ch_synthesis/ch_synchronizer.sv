//Simple 1FF synchronizer of async trigger to FCLK (5GHz) domain
module trigger_synchronizer (
    input logic FCLK,
    input logic RSTB,
    input logic trigger_async,
    
    output logic trigger_sync
);
    logic sync_stage1;
    logic sync_stage2;
    
    always_ff @(posedge FCLK or negedge RSTB) begin
        if (!RSTB) begin
            sync_stage1 <= 1'b0;
            sync_stage2 <= 1'b0;
        end else begin
            sync_stage1 <= trigger_async;
            sync_stage2 <= sync_stage1;
        end
    end
    
    assign trigger_sync = sync_stage2;

endmodule