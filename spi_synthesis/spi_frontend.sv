module spi_frontend (
    input logic spi_clk,
    input logic pico,
    input logic cs,
    input logic rstn,

    output logic is_write,
    output logic [6:0] addr,
    output logic [7:0] wdata
);

    logic [7:0] byte_deser;

    serdes input_deserializer (
        .spi_clk (spi_clk),
        .pico (pico),
        .cs (cs),
        .rstn (rstn),

        .byte_deser(byte_deser)
    );

    addr_logic addressing_logic (
        .spi_clk (spi_clk),
        .cs (cs),
        .rstn (rstn),
        .byte_deser (byte_deser),
        .pico (pico),

        .is_write (is_write),
        .addr (addr),
        .wdata (wdata)
    );

endmodule