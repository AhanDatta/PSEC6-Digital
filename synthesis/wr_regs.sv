module wr_regs (
    input logic [6:0] addr,
    input logic [7:0] wdata,
    input logic is_write,
    input logic spi_clk,
    input logic csb,
    input logic rstn,

    output logic [7:0] vco_digital_band, //address 1
    output logic [7:0] trigger_channel_mask, //address 2
    output logic [7:0] instruction, //address 3, resets on csb
    output logic [7:0] mode, //address 4
    output logic [7:0] disc_polarity, //address 5
    output logic [7:0] ref_clk_sel, //address 6
    output logic [7:0] slow_mode, //address 7
    output logic [7:0] trigger_delay, //address 8

    output logic poci_spi
);



endmodule