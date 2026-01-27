module wr_regs #(
    parameter integer NUM_WR_REGS = 11,
    //reset values, see overleaf for descriptions
    parameter logic [7:0] VCO_DIGITAL_BAND_RST_VAL = 8'h3f,
    parameter logic [7:0] TRIGGER_CHANNEL_MASK_RST_VAL = 8'hff,
    parameter logic [7:0] INSTRUCTION_RST_VAL = 8'h00,
    parameter logic [7:0] MODE_RST_VAL = 8'h03,
    parameter logic [7:0] DISC_POLARITY_RST_VAL = 8'hff,
    parameter logic [7:0] REF_CLK_SEL_RST_VAL = 8'h04,
    parameter logic [7:0] SLOW_MODE_RST_VAL = 8'h00,
    parameter logic [7:0] PFD_SWITCH_RST_VAL = 8'h01,
    parameter logic [7:0] PLL_SWITCH_RST_VAL = 8'h00,
    parameter logic [7:0] TEST_POINT_CONTROL_RST_VAL = 8'h00,
    parameter logic [7:0] LPF_RESISTOR_SEL_RST_VAL = 8'h1f
) (
    input logic spi_clk,
    input logic cs,
    input logic rstn,
    input logic is_write,
    input logic [6:0] addr,
    input logic [7:0] wdata,

    output logic [5:0] vco_digital_band, //address 1
    output logic [7:0] trigger_channel_mask, //address 2
    output logic [1:0] instruction, //address 3, resets on csb
    output logic [1:0] mode, //address 4
    output logic [7:0] disc_polarity, //address 5
    output logic [2:0] ref_clk_sel, //address 6
    output logic slow_mode, //address 7
    output logic pfd_switch, //address 8
    output logic pll_switch, //address 9, activates on-chip pll
    output logic [7:0] test_point_control, //address 10, choses test point
    output logic [7:0] lpf_resistor_sel, //address 11, controls resistance of loop filter

    output logic poci_spi
);

    logic full_rstn;

    //data to be read out over 8 clk cycles
    logic [7:0] rdata;
    logic rdata_ready_flag; //flag for spi_clk_counter in the right state to shift data

    //internal registers to handle width changes
    logic [7:0] int_vco_digital_band; 
    logic [7:0] int_trigger_channel_mask; 
    logic [7:0] int_instruction; 
    logic [7:0] int_mode; 
    logic [7:0] int_disc_polarity; 
    logic [7:0] int_ref_clk_sel; 
    logic [7:0] int_slow_mode; 
    logic [7:0] int_pfd_switch; 
    logic [7:0] int_pll_switch; 
    logic [7:0] int_test_point_control;
    logic [7:0] int_lpf_resistor_sel; 

    //previous addresses to facilitate writing
    logic [6:0] addr_one;
    logic [6:0] addr_two;

    //latch signal for each SPI reg
    logic [NUM_WR_REGS-1:0] data_reg_latch_signal;
    logic [NUM_WR_REGS-1:0] data_reg_addr_latch_signal;
    logic data_reg_wdata_flag_latch_signal;

    //clock counter to latch data at the proper time
    logic [15:0] spi_clk_counter;

    assign full_rstn = rstn & cs;

    //WRITING LOGIC
    //-------------------------------------------------------------------------------------------------------------------------------------------------
    assign data_reg_latch_signal = data_reg_addr_latch_signal & {NUM_WR_REGS{data_reg_wdata_flag_latch_signal}}; //both address and data must be present to write

    //connect outputs with proper widths, taking lower-significance bits
    always_comb begin
        vco_digital_band = int_vco_digital_band[5:0];   
        trigger_channel_mask = int_trigger_channel_mask;
        instruction = int_instruction[1:0];             
        mode = int_mode[1:0];                          
        disc_polarity = int_disc_polarity;             
        ref_clk_sel = int_ref_clk_sel[2:0];           
        slow_mode = int_slow_mode[0];                 
        pfd_switch = int_pfd_switch[0];        
        pll_switch = int_pll_switch[0];  
        test_point_control = int_test_point_control;
        lpf_resistor_sel = int_lpf_resistor_sel;             
    end 

    //clock counter for spi_clk to create latch
    //also tracks previous address for latch
    always_ff @(posedge spi_clk or negedge full_rstn) begin
        if (!full_rstn) begin
            spi_clk_counter <= '0;
            addr_one <= '0;
            addr_two <= '0;
        end
        else begin
            spi_clk_counter <= spi_clk_counter + 1;
            addr_one <= addr;
            addr_two <= addr_one;
        end 
    end

    //we are in a data-writing portion of the cycle, and we should write
    assign data_reg_wdata_flag_latch_signal = is_write && (spi_clk_counter%8 == 0) && (spi_clk_counter != '0) && (spi_clk_counter != 16'd8); 

    //generate the correct latch based on the address
    always_comb begin
        unique case (addr_two)
            7'd1: data_reg_addr_latch_signal = 'b000_0000_0001; //vco_digital_band
            7'd2: data_reg_addr_latch_signal = 'b000_0000_0010; //trigger_channel_mask
            7'd3: data_reg_addr_latch_signal = 'b000_0000_0100; //instruction
            7'd4: data_reg_addr_latch_signal = 'b000_0000_1000; //mode
            7'd5: data_reg_addr_latch_signal = 'b000_0001_0000; //disc_polarity
            7'd6: data_reg_addr_latch_signal = 'b000_0010_0000; //ref_clk_sel
            7'd7: data_reg_addr_latch_signal = 'b000_0100_0000; //slow_mode
            7'd8: data_reg_addr_latch_signal = 'b000_1000_0000; //pfd_switch
            7'd9: data_reg_addr_latch_signal = 'b001_0000_0000; //pll_switch
            7'd10: data_reg_addr_latch_signal = 'b010_0000_0000; //test point control
            7'd11: data_reg_addr_latch_signal = 'b100_0000_0000; //loop filter resistor control
            default: data_reg_addr_latch_signal = '0;
        endcase
    end

    //READING LOGIC:
    //----------------------------------------------------------------------------------------------------------------------------------------------------
    //everything read msb to lsb, from the address provided
    assign rdata_ready_flag = (spi_clk_counter%8 == 16'd1) && (spi_clk_counter != 16'd1);
    always_ff @(posedge rdata_ready_flag or negedge full_rstn) begin
        if (!full_rstn) begin
            rdata <= '0;
        end
        else begin
            unique case (addr)
                7'd1: rdata <= int_vco_digital_band;
                7'd2: rdata <= int_trigger_channel_mask; 
                7'd3: rdata <= int_instruction;
                7'd4: rdata <= int_mode;
                7'd5: rdata <= int_disc_polarity;
                7'd6: rdata <= int_ref_clk_sel;
                7'd7: rdata <= int_slow_mode;
                7'd8: rdata <= int_pfd_switch;
                7'd9: rdata <= int_pll_switch;
                7'd10: rdata <= int_test_point_control;
                7'd11: rdata <= int_lpf_resistor_sel;
                default: rdata <= '0;
            endcase
        end
    end 

    always_comb begin
        if (!full_rstn) begin
            poci_spi = 0;
        end
        else begin
            if (spi_clk_counter <= 16'd7) begin //don't read while address is being set
                poci_spi = 0;
            end
            else begin
                poci_spi = rdata[7 - ((spi_clk_counter-1)%8)];
            end
        end 
    end

    //all data stored here
    latched_rw_reg #(
        .RESET_VAL (VCO_DIGITAL_BAND_RST_VAL)
    ) vco_digital_band_reg (
        .rstn (rstn), 
        .data (wdata), 
        .latch_en (data_reg_latch_signal[0]),
        .stored_data (int_vco_digital_band)
    );

    latched_rw_reg #(
        .RESET_VAL (TRIGGER_CHANNEL_MASK_RST_VAL)
    ) trigger_channel_mask_reg (
        .rstn (rstn), 
        .data (wdata), 
        .latch_en (data_reg_latch_signal[1]), 
        .stored_data (int_trigger_channel_mask)
    );

    latched_rw_reg #(
        .RESET_VAL (INSTRUCTION_RST_VAL)
    ) instruction_reg (
        .rstn (full_rstn), 
        .data (wdata), 
        .latch_en (data_reg_latch_signal[2]), 
        .stored_data (int_instruction)
    ); //uses full rstn as to generate pulse

    latched_rw_reg #(
        .RESET_VAL (MODE_RST_VAL)
    ) mode_reg (
        .rstn (rstn), 
        .data (wdata), 
        .latch_en (data_reg_latch_signal[3]), 
        .stored_data (int_mode)
    );

    latched_rw_reg #(
        .RESET_VAL (DISC_POLARITY_RST_VAL)
    ) disc_polarity_reg (
        .rstn (rstn), 
        .data (wdata), 
        .latch_en (data_reg_latch_signal[4]), 
        .stored_data (int_disc_polarity)
    );

    latched_rw_reg #(
        .RESET_VAL (REF_CLK_SEL_RST_VAL)
    ) ref_clk_sel_reg (
        .rstn (rstn), 
        .data (wdata), 
        .latch_en (data_reg_latch_signal[5]), 
        .stored_data (int_ref_clk_sel)
    );

    latched_rw_reg #(
        .RESET_VAL (SLOW_MODE_RST_VAL)
    ) slow_mode_reg (
        .rstn (rstn), 
        .data (wdata), 
        .latch_en (data_reg_latch_signal[6]), 
        .stored_data (int_slow_mode)
    );

    latched_rw_reg #(
        .RESET_VAL (PFD_SWITCH_RST_VAL)
    ) pfd_switch_reg (
        .rstn (rstn), 
        .data (wdata), 
        .latch_en (data_reg_latch_signal[7]), 
        .stored_data (int_pfd_switch)
    );

    latched_rw_reg #(
        .RESET_VAL (PLL_SWITCH_RST_VAL)
    ) pll_switch_reg (
        .rstn (rstn), 
        .data (wdata), 
        .latch_en (data_reg_latch_signal[8]), 
        .stored_data (int_pll_switch)
    );

    latched_rw_reg #(
        .RESET_VAL (TEST_POINT_CONTROL_RST_VAL)
    ) test_point_control_reg (
        .rstn (rstn), 
        .data (wdata), 
        .latch_en (data_reg_latch_signal[9]), 
        .stored_data (int_test_point_control)
    );

    latched_rw_reg #(
        .RESET_VAL (LPF_RESISTOR_SEL_RST_VAL)
    ) lpf_resistor_sel_reg (
        .rstn (rstn), 
        .data (wdata), 
        .latch_en (data_reg_latch_signal[10]), 
        .stored_data (int_lpf_resistor_sel)
    );
endmodule