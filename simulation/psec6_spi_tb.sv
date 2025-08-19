`timescale 1ns/1ps

module psec6_spi_tb #(
    parameter integer SPI_CLK_PERIOD = 25,
    parameter integer NUM_R_REGS = 56
) ();


    logic rstn;
    logic spi_clk;
    logic pico;
    logic cs;
    logic trigger_in;

    logic pll_locked;

    logic poci_spi;

    //output to clock blocks
    logic clk_enable;
    logic [5:0] vco_digital_band; //address 1
    logic [4:0] ref_clk_sel; //address 6
    logic slow_mode; //address 7
    logic pll_switch; //address 9; activates on-chip pll

    //output to channel digital
    logic [7:0] trigger_channel_mask; //address 2
    logic [1:0] mode; //address 4
    logic [7:0] disc_polarity; //address 5
    logic [5:0] trigger_delay; //address 8
    logic [2:0] select_reg; //prepares correct counter for readout in digital channel
    
    //instructions set in address 3
    logic inst_rst; //instruction 1
    logic inst_readout; //instruction 2
    logic inst_start; //instruction 3   

    //SIM ONLY
    logic [7:0] wdata;
    logic [7:0] rdata;

    psec6_spi DUT (
        .rstn (rstn),
        .spi_clk (spi_clk),
        .pico (pico),
        .cs (cs),
        .trigger_in (trigger_in),

        .pll_locked (pll_locked),

        .poci_spi (poci_spi),

        .clk_enable (clk_enable),
        .vco_digital_band (vco_digital_band),
        .ref_clk_sel (ref_clk_sel),
        .slow_mode (slow_mode),
        .pll_switch (pll_switch),

        .trigger_channel_mask (trigger_channel_mask),
        .mode (mode),
        .disc_polarity (disc_polarity),
        .trigger_delay (trigger_delay),
        .select_reg (select_reg),

        .inst_rst (inst_rst),
        .inst_readout (inst_readout),
        .inst_start (inst_start)
    );

    task send_byte_spi (
        input logic [7:0] data_byte,
        input integer clk_period, //period in ns
        output logic [7:0] rbyte
    );
        // Initialize signals
        spi_clk = 1'b0;
        pico = 1'b0;

        // Send 8 bits MSB first
        for (integer i = 7; i >= 0; i = i - 1) begin
            //Set data on falling edge of clock
            spi_clk = 1'b0;
            pico = data_byte[i];  //Send MSB first
            #(clk_period/2);
            
            //Rising edge of clock
            spi_clk = 1'b1;
            #(clk_period/2);
            rbyte[i] = poci_spi; //Read MSB -> LSB
        end
        
        //Final falling edge to catch data
        spi_clk = 1'b0;
        #(clk_period/2);
        
        // Hold final state briefly
        #(clk_period/4);
    endtask

    task write_data (
        input logic[6:0] addr,
        input logic [7:0] wdata,
        input integer clk_period,
        output logic [7:0] rbyte
    );

        cs = 1;
        //address to 1 (vco_digital_band)
        send_byte_spi (
            .data_byte ({1'b1, addr}), 
            .clk_period (clk_period), //assume 40 MHz spi_clk
            .rbyte(rbyte)
        );
        assert(rbyte == 8'b0) else $error("SPI write address phase failed: Expected rbyte=0x00 during address transmission to addr=0x%02X, got rbyte=0x%02X. Check SPI protocol implementation.", addr, rbyte);
        if (rbyte == 8'b0) $display("PASS: SPI write address phase successful for addr=0x%02X", addr);
        //data to 0000_0011
        send_byte_spi (
            .data_byte (wdata), 
            .clk_period (clk_period), //assume 40 MHz spi_clk
            .rbyte(rbyte)
        );
        cs = 0;
        #25; //stops another instruction coming directly after

    endtask

    task read_data (
        input logic[6:0] addr,
        input integer clk_period,
        output logic [7:0] rbyte
    );

        cs = 1;
        //address to 1 (vco_digital_band)
        send_byte_spi (
            .data_byte ({1'b0, addr}), 
            .clk_period (clk_period), //assume 40 MHz spi_clk
            .rbyte(rbyte)
        );
        assert(rbyte == 8'b0) else $error("SPI read address phase failed: Expected rbyte=0x00 during address transmission to addr=0x%02X, got rbyte=0x%02X. Check SPI protocol implementation.", addr, rbyte);
        if (rbyte == 8'b0) $display("PASS: SPI read address phase successful for addr=0x%02X", addr);
        //data to 0000_0011
        send_byte_spi (
            .data_byte (8'b0), 
            .clk_period (clk_period), //assume 40 MHz spi_clk
            .rbyte(rbyte)
        );
        cs = 0;
        #25; //stops another instruction coming directly after, allows cs to reset

    endtask

    task timestamp_read_test (
        input integer clk_period
    );

        logic [7:0] rbyte;

        cs = 1;
        //set address to first timestamp reg (11)
        send_byte_spi (
            .data_byte ({1'b0, 7'd11}),
            .clk_period (clk_period),
            .rbyte(rbyte)
        );

        for (integer i = 0; i < NUM_R_REGS; i = i+1) begin
            send_byte_spi (
                .data_byte (8'b0),
                .clk_period (clk_period),
                .rbyte(rbyte)
            ); //move forward the address by one
            //check at end because select reg switches on first bit after address changes, namely bit 9, 17, ...
            assert(select_reg == (i%7)) else $error("Select register mismatch during readout: Expected select_reg=%0d (i=%0d mod 7), got select_reg=%0d. Register counter may not be incrementing correctly or modulo logic failed.", (i%7), i, select_reg);
            if (select_reg == (i%7)) $display("PASS: Select register correctly updated to %0d for readout iteration %0d", select_reg, i);
        end

        cs = 0;
        #25;

    endtask

    initial begin
        //initialization and reset
        pll_locked = 1;
        trigger_in = 0;
        rstn = 1;
        spi_clk = 0;
        cs = 0;
        pico = 0;
        #25;
        rstn = 0;
        #25;
        rstn = 1;

        /*
        -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        RW REGISTER TEST CASES
        -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        */

        //VCO DIGITAL BAND
        wdata = 8'h01;
        //writing wdata to vco_digital_band (1)
        write_data (
            .addr (7'd1),
            .wdata (wdata),
            .clk_period (SPI_CLK_PERIOD),
            .rbyte (rdata)
        );

        //reading from vco_digital_band (1) non-destructively
        read_data (
            .addr(7'd1),
            .clk_period(SPI_CLK_PERIOD),
            .rbyte(rdata)
        );
        assert(vco_digital_band == wdata[5:0]) else $error("VCO digital band register mismatch: Expected vco_digital_band=0x%02X (from wdata[5:0]), got vco_digital_band=0x%02X. Register write/decode may have failed.", wdata[5:0], vco_digital_band);
        if (vco_digital_band == wdata[5:0]) $display("PASS: VCO digital band register correctly written and read: 0x%02X", vco_digital_band);
        assert(rdata == wdata) else $error("SPI readback data mismatch: Expected rdata=0x%02X (original wdata), got rdata=0x%02X. SPI read operation or register storage failed.", wdata, rdata);
        if (rdata == wdata) $display("PASS: SPI readback data matches written data: 0x%02X", rdata);

        //TRIGGER CHANNEL MASK
        wdata = 8'h7f;
        write_data (
            .addr (7'd2),
            .wdata (wdata),
            .clk_period (SPI_CLK_PERIOD),
            .rbyte (rdata)
        );

        read_data (
            .addr(7'd2),
            .clk_period(SPI_CLK_PERIOD),
            .rbyte(rdata)
        );
        assert(trigger_channel_mask == wdata) else $error("Trigger Channel Mask register mismatch: Expected trigger_channel_mask=0x%02X (from wdata), got trigger_channel_mask=0x%02X. Register write/decode may have failed.", wdata, trigger_channel_mask);
        if (trigger_channel_mask == wdata) $display("PASS: Trigger Channel Mask register correctly written and read: 0x%02X", trigger_channel_mask);
        assert(rdata == wdata) else $error("SPI readback data mismatch: Expected rdata=0x%02X (original wdata), got rdata=0x%02X. SPI read operation or register storage failed.", wdata, rdata);
        if (rdata == wdata) $display("PASS: SPI readback data matches written data: 0x%02X", rdata);

        //MODE
        wdata = 8'h03;
        write_data (
            .addr (7'd4),
            .wdata (wdata),
            .clk_period (SPI_CLK_PERIOD),
            .rbyte (rdata)
        );

        read_data (
            .addr(7'd4),
            .clk_period(SPI_CLK_PERIOD),
            .rbyte(rdata)
        );
        assert(mode == wdata[1:0]) else $error("Mode register mismatch: Expected mode=0x%02X (from wdata[1:0]), got mode=0x%02X. Register write/decode may have failed.", wdata[1:0], mode);
        if (mode == wdata[1:0]) $display("PASS: Mode register correctly written and read: 0x%02X", mode);
        assert(rdata == wdata) else $error("SPI readback data mismatch: Expected rdata=0x%02X (original wdata), got rdata=0x%02X. SPI read operation or register storage failed.", wdata, rdata);
        if (rdata == wdata) $display("PASS: SPI readback data matches written data: 0x%02X", rdata);

        //DISCRIMINATOR POLARITY
        wdata = 8'haa;
        write_data (
            .addr (7'd5),
            .wdata (wdata),
            .clk_period (SPI_CLK_PERIOD),
            .rbyte (rdata)
        );

        read_data (
            .addr(7'd5),
            .clk_period(SPI_CLK_PERIOD),
            .rbyte(rdata)
        );
        assert(disc_polarity == wdata) else $error("Discriminator Polarity register mismatch: Expected disc_polarity=0x%02X (from wdata), got disc_polarity=0x%02X. Register write/decode may have failed.", wdata, disc_polarity);
        if (disc_polarity == wdata) $display("PASS: Discriminator Polarity register correctly written and read: 0x%02X", disc_polarity);
        assert(rdata == wdata) else $error("SPI readback data mismatch: Expected rdata=0x%02X (original wdata), got rdata=0x%02X. SPI read operation or register storage failed.", wdata, rdata);
        if (rdata == wdata) $display("PASS: SPI readback data matches written data: 0x%02X", rdata);

        //REFERENCE CLOCK SELECT
        wdata = 8'h10;
        write_data (
            .addr (7'd6),
            .wdata (wdata),
            .clk_period (SPI_CLK_PERIOD),
            .rbyte (rdata)
        );

        read_data (
            .addr(7'd6),
            .clk_period(SPI_CLK_PERIOD),
            .rbyte(rdata)
        );
        assert(ref_clk_sel == wdata[4:0]) else $error("Reference Clock Select register mismatch: Expected ref_clk_sel=0x%02X (from wdata[4:0]), got ref_clk_sel=0x%02X. Register write/decode may have failed.", wdata[4:0], ref_clk_sel);
        if (ref_clk_sel == wdata[4:0]) $display("PASS: Reference Clock Select register correctly written and read: 0x%02X", ref_clk_sel);
        assert(rdata == wdata) else $error("SPI readback data mismatch: Expected rdata=0x%02X (original wdata), got rdata=0x%02X. SPI read operation or register storage failed.", wdata, rdata);
        if (rdata == wdata) $display("PASS: SPI readback data matches written data: 0x%02X", rdata);

        //SLOW MODE
        wdata = 8'h01;
        write_data (
            .addr (7'd7),
            .wdata (wdata),
            .clk_period (SPI_CLK_PERIOD),
            .rbyte (rdata)
        );

        read_data (
            .addr(7'd7),
            .clk_period(SPI_CLK_PERIOD),
            .rbyte(rdata)
        );
        assert(slow_mode == wdata[0]) else $error("Slow Mode register mismatch: Expected slow_mode=0x%02X (from wdata[0]), got slow_mode=0x%02X. Register write/decode may have failed.", wdata[0], slow_mode);
        if (slow_mode == wdata[0]) $display("PASS: Slow Mode register correctly written and read: 0x%02X", slow_mode);
        assert(rdata == wdata) else $error("SPI readback data mismatch: Expected rdata=0x%02X (original wdata), got rdata=0x%02X. SPI read operation or register storage failed.", wdata, rdata);
        if (rdata == wdata) $display("PASS: SPI readback data matches written data: 0x%02X", rdata);

        //TRIGGER DELAY
        wdata = 8'h00;
        write_data (
            .addr (7'd8),
            .wdata (wdata),
            .clk_period (SPI_CLK_PERIOD),
            .rbyte (rdata)
        );

        read_data (
            .addr(7'd8),
            .clk_period(SPI_CLK_PERIOD),
            .rbyte(rdata)
        );
        assert(trigger_delay == wdata[5:0]) else $error("Trigger Delay register mismatch: Expected trigger_delay=0x%02X (from wdata[5:0]), got trigger_delay=0x%02X. Register write/decode may have failed.", wdata[5:0], trigger_delay);
        if (trigger_delay == wdata[5:0]) $display("PASS: Trigger Delay register correctly written and read: 0x%02X", trigger_delay);
        assert(rdata == wdata) else $error("SPI readback data mismatch: Expected rdata=0x%02X (original wdata), got rdata=0x%02X. SPI read operation or register storage failed.", wdata, rdata);
        if (rdata == wdata) $display("PASS: SPI readback data matches written data: 0x%02X", rdata);

        //PLL SWITCH
        wdata = 8'h01;
        write_data (
            .addr (7'd9),
            .wdata (wdata),
            .clk_period (SPI_CLK_PERIOD),
            .rbyte (rdata)
        );

        read_data (
            .addr(7'd9),
            .clk_period(SPI_CLK_PERIOD),
            .rbyte(rdata)
        );
        assert(pll_switch == wdata[0]) else $error("PLL Switch register mismatch: Expected pll_switch=0x%02X (from wdata[0]), got pll_switch=0x%02X. Register write/decode may have failed.", wdata[0], pll_switch);
        if (pll_switch == wdata[0]) $display("PASS: PLL Switch register correctly written and read: 0x%02X", pll_switch);
        assert(rdata == wdata) else $error("SPI readback data mismatch: Expected rdata=0x%02X (original wdata), got rdata=0x%02X. SPI read operation or register storage failed.", wdata, rdata);
        if (rdata == wdata) $display("PASS: SPI readback data matches written data: 0x%02X", rdata);

        /*
        -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        INSTRUCTION TEST CASES
        -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        */

        //writing reset instruction (1) to instruction reg (3)
        write_data (
            .addr (7'd3),
            .wdata (8'd1),
            .clk_period (SPI_CLK_PERIOD),
            .rbyte (rdata)
        );

        //writing readout instruction (2) to instruction reg (3)
        write_data (
            .addr (7'd3),
            .wdata (8'd2),
            .clk_period (SPI_CLK_PERIOD),
            .rbyte (rdata)
        );

        //writing start (3) to instruction (3)
        write_data (
            .addr (7'd3),
            .wdata (8'd3),
            .clk_period (SPI_CLK_PERIOD),
            .rbyte (rdata)
        );
        assert(clk_enable == 1'b1) else $error("Clock enable activation failed: Expected clk_enable=1 after writing start instruction (3) to address 3, got clk_enable=%b. Start instruction decode or clock control logic may be faulty.", clk_enable);
        if (clk_enable == 1'b1) $display("PASS: Clock enable successfully activated after start instruction");

        //ending sampling with trigger_in
        trigger_in = 1;
        #25;
        trigger_in = 0;
        assert(clk_enable == 1'b0) else $error("Clock enable deactivation failed: Expected clk_enable=0 after trigger_in pulse, got clk_enable=%b. Trigger input handling or sampling stop logic may be faulty.", clk_enable);
        if (clk_enable == 1'b0) $display("PASS: Clock enable successfully deactivated after trigger_in pulse");

        /*
        -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        TIMESTAMP READOUT TEST CASES
        -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        */

        timestamp_read_test (
            .clk_period (SPI_CLK_PERIOD)
        );
    end 

endmodule