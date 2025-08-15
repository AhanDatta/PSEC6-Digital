module latched_rw_reg (
    input logic rstn,
    input logic [7:0] reset_val,
    input logic [7:0] data,
    input logic latch_en,
    output logic [7:0] stored_data
);
    always_latch begin
        if (!rstn) begin
            stored_data = reset_val;
        end
        else if (latch_en) begin
            stored_data = data;
        end
    end
endmodule