module readout_mux (
    input logic [7:0] poci_ch, //timestamps from channels
    input logic poci_spi, //from SPI itself
    input logic csb,
    input logic rstn,
    input logic [6:0] addr, //used to control the mux

    output logic poci
);

endmodule