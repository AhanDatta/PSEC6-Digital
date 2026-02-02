module latched_rw_reg #(
    parameter logic [7:0] RESET_VAL = 8'h00
) (
    //local power
    inout DVDD,
    inout DVSS,

    input logic rstn,
    input logic [7:0] data,
    input logic latch_en,
    output logic [7:0] stored_data
);
    always_latch begin
        if (!rstn) begin
            stored_data = RESET_VAL;
        end
        else if (latch_en) begin
            stored_data = data;
        end
    end
endmodule