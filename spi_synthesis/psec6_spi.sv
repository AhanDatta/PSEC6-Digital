module psec6_spi (
    //external inputs
    input logic rstn,
    input logic spi_clk,
    input logic pico,
    input logic csb,
    input logic trigger_in, //tells the chip to stop sampling, sets clk_enable = 0

    //internal signal input
    input logic pll_locked, //read from address 10

    //output to readout mux
    output logic poci_spi,

    //output to clock blocks
    output logic clk_enable,
    output logic [5:0] vco_digital_band, //address 1
    output logic [4:0] ref_clk_sel, //address 6
    output logic slow_mode, //address 7
    output logic pll_switch, //address 9, activates on-chip pll

    //output to channel digital
    output logic [7:0] trigger_channel_mask, //address 2
    
    //set in address 3
    output logic inst_rst, //instruction 1
    output logic inst_readout, //instruction 2
    output logic inst_start, //instruction 3

    output logic [1:0] mode, //address 4
    output logic [7:0] disc_polarity, //address 5
    output logic [5:0] trigger_delay //address 8
);

    logic [7:0] byte_deser;
    logic [6:0] addr;
    logic [7:0] wdata;
    logic is_write;
    logic [1:0] instruction;

    serdes input_deserializer (
        .spi_clk (spi_clk),
        .pico (pico),
        .csb (csb),
        .rstn (rstn),

        .byte_deser(byte_deser)
    );

    addr_logic addressing_logic (
        .spi_clk (spi_clk),
        .csb (csb),
        .rstn (rstn),
        .byte_deser (byte_deser),
        .pico (pico),

        .is_write (is_write),
        .addr (addr),
        .wdata (wdata)
    );

    wr_regs data_registers (
        .spi_clk(spi_clk),
        .csb (csb),
        .rstn (rstn),

        .is_write (is_write),
        .addr (addr),
        .wdata (wdata),
        .pll_locked (pll_locked),

        .vco_digital_band (vco_digital_band),
        .trigger_channel_mask (trigger_channel_mask),
        .instruction (instruction),
        .mode (mode),
        .disc_polarity (disc_polarity),
        .ref_clk_sel (ref_clk_sel),
        .slow_mode (slow_mode),
        .trigger_delay (trigger_delay),
        .pll_switch (pll_switch),

        .poci_spi (poci_spi)
    );

    inst_driver instruction_pulse_gen (
        .inst_reg (instruction),
        .csb (csb),
        .rstn (rstn),
        .inst_stop (trigger_in),

        .inst_rst (inst_rst),
        .inst_readout (inst_readout),
        .inst_start (inst_start),
        .clk_enable (clk_enable)
    );

endmodule