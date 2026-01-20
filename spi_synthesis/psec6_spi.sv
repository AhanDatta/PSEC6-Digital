module psec6_spi (
    //external inputs
    input logic rstn, //chip-wide reset
    input logic spi_clk,
    input logic pico,
    input logic cs, //spi specific reset
    input logic trigger_in, //tells the chip to stop sampling, sets clk_enable = 0

    //output to readout mux
    output logic [6:0] addr,
    output logic poci_spi,

    //output to test point mux
    output logic [7:0] test_point_control,

    //output to clock blocks
    output logic clk_enable,
    output logic [5:0] vco_digital_band, //address 1
    output logic [2:0] ref_clk_sel, //address 6
    output logic slow_mode, //address 7
    output logic pll_switch, //address 9, activates on-chip pll
    output logic [7:0] lpf_resistor_sel, //address 11, controls resistance of loop filter

    //output to channel digital
    output logic [7:0] trigger_channel_mask, //address 2
    output logic [1:0] mode, //address 4
    output logic [7:0] disc_polarity, //address 5
    output logic [5:0] trigger_delay, //address 8
    output logic [2:0] select_reg, //prepares correct counter for readout in digital channel
    
    //instructions set in address 3
    output logic inst_rst, //instruction 1
    output logic inst_readout, //instruction 2
    output logic inst_start //instruction 3    
);

    logic is_write;
    logic [7:0] wdata;
    logic [1:0] instruction;

    spi_frontend frontend (
        .spi_clk (spi_clk),
        .pico (pico),
        .cs (cs),
        .rstn (rstn),

        .is_write (is_write),
        .addr (addr),
        .wdata (wdata)
    );

    wr_regs data_registers (
        .spi_clk(spi_clk),
        .cs (cs),
        .rstn (rstn),

        .is_write (is_write),
        .addr (addr),
        .wdata (wdata),

        .vco_digital_band (vco_digital_band),
        .trigger_channel_mask (trigger_channel_mask),
        .instruction (instruction),
        .mode (mode),
        .disc_polarity (disc_polarity),
        .ref_clk_sel (ref_clk_sel),
        .slow_mode (slow_mode),
        .trigger_delay (trigger_delay),
        .pll_switch (pll_switch),
        .test_point_control (test_point_control),
        .lpf_resistor_sel (lpf_resistor_sel),

        .poci_spi (poci_spi)
    );

    inst_driver instruction_pulse_gen (
        .inst_reg (instruction),
        .cs (cs),
        .rstn (rstn),
        .inst_stop (trigger_in),

        .inst_rst (inst_rst),
        .inst_readout (inst_readout),
        .inst_start (inst_start),
        .clk_enable (clk_enable)
    );

    addr_to_ch_select counter_readout_select (
        .rstn (rstn),
        .cs (cs),
        .spi_clk (spi_clk),
        .addr (addr),

        .select_reg (select_reg)
    );

endmodule