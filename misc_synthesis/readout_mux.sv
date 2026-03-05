module readout_mux #(
    parameter integer CH_REG_START_ADDR = 12, //first channel-based reg address
    parameter integer CH_REG_STOP_ADDR = 67, //last channel-based reg address
    parameter integer NUM_REGS_PER_CH = 7 //there are 7 register for each channel
) (
    //local power
    inout DVDD,
    inout DVSS,

    input logic spi_clk, //used to track addr one cycle back
    input logic [7:0] poci_ch, //timestamps from channels
    input logic poci_spi, //from SPI itself
    input logic cs,
    input logic rstn,
    input logic [6:0] addr, //used to control the mux

    output logic poci
);
    
    logic full_rstn;
    logic [6:0] addr_one;

    assign full_rstn = cs & rstn;
    always_ff @(posedge spi_clk or negedge full_rstn) begin
        if (!full_rstn) begin
            addr_one <= '0;
        end
        else begin
            addr_one <= addr;
        end
    end

    //POCI Output Multiplexer
    always_comb begin
        if (addr_one == '0) poci = 0;
        else if (addr_one < CH_REG_START_ADDR) poci = poci_spi;
        else if (addr_one <= CH_REG_STOP_ADDR) poci = poci_ch[((addr_one - CH_REG_START_ADDR)/NUM_REGS_PER_CH)]; //floor is implicit, choses correct channel
        else poci = 0;
    end

endmodule