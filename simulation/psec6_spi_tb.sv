`timescale 1ns/1ps

module psec6_spi_tb ();


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
            if (i == 7) begin
                rbyte = '0;
            end
            else begin
                rbyte[i] = poci_spi; //Read MSB -> LSB
            end
            
            //Rising edge of clock
            spi_clk = 1'b1;
            #(clk_period/2);
        end
        
        //Final falling edge to catch data
        spi_clk = 1'b0;
        rbyte[0] = poci_spi;
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
        assert(rbyte == 8'b0);
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
        assert(rbyte == 8'b0);
        //data to 0000_0011
        send_byte_spi (
            .data_byte (8'b0), 
            .clk_period (clk_period), //assume 40 MHz spi_clk
            .rbyte(rbyte)
        );
        cs = 0;
        #25; //stops another instruction coming directly after

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

        //writing 3 to vco_digital_band (1)
        write_data (
            .addr (7'd1),
            .wdata (8'd3),
            .clk_period (25),
            .rbyte (rdata)
        );

        //writing start (3) to instruction (3)
        write_data (
            .addr (7'd3),
            .wdata (8'd3),
            .clk_period (25),
            .rbyte (rdata)
        );
        assert(clk_enable == 1'b1); //checks clk_enable works as expected

        //ending sampling with trigger_in
        trigger_in = 1;
        #25;
        trigger_in = 0;
        assert(clk_enable == 1'b0); //clk_enable should go low on trigger_in high 

        //reading from vco_digital_band (1) non-destructively
        read_data (
            .addr(7'd1),
            .clk_period(25),
            .rbyte(rdata)
        );

        //writing reset instruction (1) to instruction reg (3)
        write_data (
            .addr (7'd3),
            .wdata (8'd1),
            .clk_period (25),
            .rbyte (rdata)
        );

        //writing readout instruction (2) to instruction reg (3)
        write_data (
            .addr (7'd3),
            .wdata (8'd2),
            .clk_period (25),
            .rbyte (rdata)
        );
    end 

endmodule