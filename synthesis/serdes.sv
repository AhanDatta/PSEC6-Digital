module serdes (
    input logic spi_clk, //deserialization clk
    input logic pico, //data to deser
    input logic csb, //chip select, spi localized reset, active low
    input logic rstn, //chip wide active low reset

    output logic [7:0] byte_deser //output from shift register
);
    logic full_rstn;
    assign full_rstn = csb && rstn;

    always_ff @(posedge sclk or negedge full_rstn) begin
        if (!full_rstn) begin
            byte_deser <= 8'b0;
        end
        else begin
            byte_deser <= {byte_deser[6:0], pico};
        end
    end
endmodule