module wr_regs (
    input logic spi_clk,
    input logic csb,
    input logic rstn,
    input logic is_write,
    input logic [6:0] addr,
    input logic [7:0] wdata,
    input logic pll_locked, //address 10, comes from pll block, read only

    output logic [5:0] vco_digital_band, //address 1
    output logic [7:0] trigger_channel_mask, //address 2
    output logic [1:0] instruction, //address 3, resets on csb
    output logic [1:0] mode, //address 4
    output logic [7:0] disc_polarity, //address 5
    output logic [4:0] ref_clk_sel, //address 6
    output logic slow_mode, //address 7
    output logic [5:0] trigger_delay, //address 8
    output logic pll_switch, //address 9, activates on-chip pll

    output logic poci_spi
);

    logic full_rstn;

    //internal registers to handle width changes
    logic [7:0] int_vco_digital_band; 
    logic [7:0] int_trigger_channel_mask; 
    logic [7:0] int_instruction; 
    logic [7:0] int_mode; 
    logic [7:0] int_disc_polarity; 
    logic [7:0] int_ref_clk_sel; 
    logic [7:0] int_slow_mode; 
    logic [7:0] int_trigger_delay; 
    logic [7:0] int_pll_switch; 
    logic [7:0] int_pll_locked; 

    //previous address to facilitate writing
    logic [6:0] prev_addr;

    //latch signal for each SPI reg
    logic [8:0] data_reg_latch_signal;
    logic [8:0] data_reg_addr_latch_signal;
    logic data_reg_wdata_flag_latch_signal;

    //clock counter to latch at the proper time
    logic [15:0] spi_clk_counter;

    assign full_rstn = rstn & csb;

    //WRITING LOGIC
    //-------------------------------------------------------------------------------------------------------------------------------------------------
    assign data_reg_latch_signal = data_reg_addr_latch_signal & {9{data_reg_wdata_flag_latch_signal}}; //both address and data must be present to write

    //connect outputs with proper widths, taking lower-significance bits
    always_comb begin
        vco_digital_band = int_vco_digital_band[5:0];   
        trigger_channel_mask = int_trigger_channel_mask;
        instruction = int_instruction[1:0];             
        mode = int_mode[1:0];                          
        disc_polarity = int_disc_polarity;             
        ref_clk_sel = int_ref_clk_sel[4:0];           
        slow_mode = int_slow_mode[0];                 
        trigger_delay = int_trigger_delay[5:0];        
        pll_switch = int_pll_switch[0];  
        int_pll_locked = {7'b0, pll_locked};             
    end 

    //clock counter for spi_clk to create latch
    always_ff @(posedge spi_clk or negedge full_rstn) begin
        if (!full_rstn) begin
            spi_clk_counter <= '0;
            prev_addr <= '0;
        end
        else begin
            spi_clk_counter <= spi_clk_counter + 1;
            prev_addr <= addr;
        end 
    end

    //we are in a data-writing portion of the cycle, and we should write
    assign data_reg_wdata_flag_latch_signal = is_write && (spi_clk_counter%8 == 0) && (spi_clk_counter != '0) && (spi_clk_counter != 16'd8); 

    //generate the correct latch based on the address
    always_comb begin
        unique case (prev_addr)
            7'd1: data_reg_addr_latch_signal = 9'b0_0000_0001; //vco_digital_band
            7'd2: data_reg_addr_latch_signal = 9'b0_0000_0010; //trigger_channel_mask
            7'd3: data_reg_addr_latch_signal = 9'b0_0000_0100; //instruction
            7'd4: data_reg_addr_latch_signal = 9'b0_0000_1000; //mode
            7'd5: data_reg_addr_latch_signal = 9'b0_0001_0000; //disc_polarity
            7'd6: data_reg_addr_latch_signal = 9'b0_0010_0000; //ref_clk_sel
            7'd7: data_reg_addr_latch_signal = 9'b0_0100_0000; //slow_mode
            7'd8: data_reg_addr_latch_signal = 9'b0_1000_0000; //trigger_delay
            7'd9: data_reg_addr_latch_signal = 9'b1_0000_0000; //pll_switch
            default: data_reg_addr_latch_signal = '0;
        endcase
    end

    //READING LOGIC:
    //----------------------------------------------------------------------------------------------------------------------------------------------------
    //everything read msb to lsb, from the address provided
    always_comb begin
        unique case (addr)
            7'd1: poci_spi = int_vco_digital_band[7-(spi_clk_counter%8)];
            7'd2: poci_spi = int_trigger_channel_mask[7-(spi_clk_counter%8)]; 
            7'd3: poci_spi = int_instruction[7-(spi_clk_counter%8)];
            7'd4: poci_spi = int_mode[7-(spi_clk_counter%8)];
            7'd5: poci_spi = int_disc_polarity[7-(spi_clk_counter%8)];
            7'd6: poci_spi = int_ref_clk_sel[7-(spi_clk_counter%8)];
            7'd7: poci_spi = int_slow_mode[7-(spi_clk_counter%8)];
            7'd8: poci_spi = int_trigger_delay[7-(spi_clk_counter%8)];
            7'd9: poci_spi = int_pll_switch[7-(spi_clk_counter%8)];
            7'd10: poci_spi = int_pll_locked[7-(spi_clk_counter%8)];
            default: poci_spi = '0;
        endcase
    end 

    //all data stored here
    latched_rw_reg vco_digital_band_reg (.rstn (rstn), .reset_val (8'b00111111), .data(wdata), .latch_en(data_reg_latch_signal[0]), .stored_data(int_vco_digital_band));
    latched_rw_reg trigger_channel_mask_reg (.rstn (rstn), .reset_val (8'b11111111), .data(wdata), .latch_en(data_reg_latch_signal[1]), .stored_data(int_trigger_channel_mask));
    latched_rw_reg instruction_reg (.rstn (full_rstn), .reset_val (8'b00000000), .data(wdata), .latch_en(data_reg_latch_signal[2]), .stored_data(int_instruction)); //uses full rstn as to generate pulse
    latched_rw_reg mode_reg (.rstn (rstn), .reset_val (8'b00000011), .data(wdata), .latch_en(data_reg_latch_signal[3]), .stored_data(int_mode));
    latched_rw_reg disc_oplarity_reg (.rstn (rstn), .reset_val (8'b00000000), .data(wdata), .latch_en(data_reg_latch_signal[4]), .stored_data(int_disc_polarity));
    latched_rw_reg ref_clk_sel_reg (.rstn (rstn), .reset_val (8'b00000010), .data(wdata), .latch_en(data_reg_latch_signal[5]), .stored_data(int_ref_clk_sel));
    latched_rw_reg slow_mode_reg (.rstn (rstn), .reset_val (8'b00000000), .data(wdata), .latch_en(data_reg_latch_signal[6]), .stored_data(int_slow_mode));
    latched_rw_reg trigger_delay_reg (.rstn (rstn), .reset_val (8'b00000000), .data(wdata), .latch_en(data_reg_latch_signal[7]), .stored_data(int_trigger_delay));
    latched_rw_reg pll_switch_reg (.rstn (rstn), .reset_val (8'b00000001), .data(wdata), .latch_en(data_reg_latch_signal[8]), .stored_data(int_pll_switch));
endmodule