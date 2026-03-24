module latched_rw_reg #(
    parameter logic [7:0] RESET_VAL = 8'h00
) (
    input logic spi_clk,   // Add spi_clk as an input!
    input logic rstn,
    input logic [7:0] data,
    input logic latch_en,
    output logic [7:0] stored_data
);
    //triggers safely on the negedge, avoiding the need for cycle 17
    always_ff @(negedge spi_clk or negedge rstn) begin
        if (!rstn) begin
            stored_data <= RESET_VAL;
        end
        else if (latch_en) begin
            stored_data <= data;
        end
    end
endmodule