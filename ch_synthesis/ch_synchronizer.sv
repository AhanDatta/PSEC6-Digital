//Simple 1FF synchronizer of async trigger to FCLK (5GHz) domain
module trigger_synchronizer (
    input logic FCLK,
    input logic RSTB,
    input logic trigger_async,
    
    output logic trigger_sync
);
    
    always_ff @(posedge FCLK or negedge RSTB) begin
        if (!RSTB) begin
            trigger_sync <= 1'b0;
        end else begin
            trigger_sync <= trigger_async;
        end
    end

endmodule