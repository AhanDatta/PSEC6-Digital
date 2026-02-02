module serdes (
    input logic spi_clk, //deserialization clk
    input logic pico, //data to deser
    input logic cs, //chip select active high, local spi reset active low
    input logic rstn, //chip wide active low reset

    output logic [7:0] byte_deser //output from shift register
);
    logic full_rstn;
    assign full_rstn = cs && rstn;

    always_ff @(posedge spi_clk or negedge full_rstn) begin
        if (!full_rstn) begin
            byte_deser <= 8'b0;
        end
        else begin
            byte_deser <= {byte_deser[6:0], pico};
        end
    end
endmodule