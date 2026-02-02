module spi_frontend (
    //local power
    inout DVDD,
    inout DVSS,

    //raw inputs from pads
    input logic spi_clk,
    input logic pico,
    input logic cs,
    input logic rstn,

    //data used in WR regs
    output logic is_write,
    output logic [6:0] addr,
    output logic [7:0] wdata
);

    logic [7:0] byte_deser;

    serdes input_deserializer (
        .DVDD(DVDD),
        .DVSS(DVSS),

        .spi_clk (spi_clk),
        .pico (pico),
        .cs (cs),
        .rstn (rstn),

        .byte_deser(byte_deser)
    );

    addr_logic addressing_logic (
        .DVDD(DVDD),
        .DVSS(DVSS),

        .spi_clk (spi_clk),
        .cs (cs),
        .rstn (rstn),
        .byte_deser (byte_deser),

        .is_write (is_write),
        .addr (addr),
        .wdata (wdata)
    );

endmodule