typedef enum logic {
    SPI_ADDR,
    SPI_DATA
} spi_state_t;

module addr_logic (
    //raw inputs + serdes
    input logic spi_clk,
    input logic cs,
    input logic rstn,
    input logic [7:0] byte_deser, //output from serdes

    //used in WR regs
    output logic is_write, //active high, msb of first byte sets this
    output logic [6:0] addr, //seven lowest order bits of first byte
    output logic [7:0] wdata //set for each byte after the first
);
    logic [2:0] spi_clk_counter; //used to track which part of the transaction we are in
    logic byte_flag;
    spi_state_t spi_state;
    logic full_rstn;
    
    //full async reset
    assign full_rstn = cs && rstn;

    //clock counter
    always_ff @(posedge spi_clk or negedge full_rstn) begin
        if (!full_rstn) begin
            spi_clk_counter <= '0;
        end
        else begin
            spi_clk_counter <= spi_clk_counter + 3'd1;
        end
    end 

    //byte flag generator to signal the end of a byte
    assign byte_flag = (spi_clk_counter == 0);

    assign wdata = byte_deser; //latch logic is handled in wr_regs module

    //read state machine for spi
    always_ff @(negedge spi_clk or negedge full_rstn) begin
        if (!full_rstn) begin
            is_write <= 1'b0;
            addr <= '0;
            spi_state <= SPI_ADDR;
        end
        else if (byte_flag) begin
            case (spi_state)
                SPI_ADDR: begin
                    //first byte sets address, is_write
                    is_write <= byte_deser[7];
                    addr <= byte_deser[6:0];
                    spi_state <= SPI_DATA;
                end
                
                SPI_DATA: begin
                    if (!is_write) begin
                        addr <= addr + 7'd1; //supports address rollover for read
                        spi_state <= SPI_DATA; //remains in SPI_DATA state to read out more bytes
                    end
                    else begin 
                        addr <= addr;
                        spi_state <= SPI_ADDR;
                    end
                    
                    
                end
                
                //literally impossible but ok
                default: begin
                    spi_state <= SPI_ADDR;
                end
            endcase
        end
    end

endmodule