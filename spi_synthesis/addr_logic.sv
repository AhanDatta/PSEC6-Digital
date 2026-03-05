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
    logic [15:0] spi_clk_counter; //used to track which part of the transaction we are in
    logic byte_flag;
    spi_state_t spi_state;
    logic full_rstn;
    assign full_rstn = cs && rstn;

    always_ff @(posedge spi_clk or negedge full_rstn) begin
        if (!full_rstn) begin
            spi_clk_counter <= '0;
        end
        else begin
            spi_clk_counter <= spi_clk_counter + 1;
        end
    end 

    //byte flag generator
    always_comb begin
        if (!full_rstn) begin
            byte_flag = '0;
        end
        else begin
            if (spi_clk_counter != 0 && spi_clk_counter % 8 == 0) begin
                byte_flag = 1;
            end 
            else begin
                byte_flag = 0;
            end
        end
    end

    always_ff @(posedge byte_flag or negedge rstn or negedge cs) begin
        if (!rstn) begin
            is_write <= 0;
            addr <= '0;
            wdata <= '0;
            spi_state <= SPI_ADDR;
        end
        else if (!cs) begin
            //async cs deassertion resets state
            spi_state <= SPI_ADDR;
            addr <= '0;
            is_write <= 0;
            //keep wdata to avoid writing glitches
        end
        else begin
            //process on byte_flag when CS is active
            case (spi_state)
                SPI_ADDR: begin
                    //first byte sets address, is_write
                    is_write <= byte_deser[7];
                    addr <= byte_deser[6:0];
                    wdata <= '0;
                    spi_state <= SPI_DATA;
                end
                
                SPI_DATA: begin
                    wdata <= byte_deser[7:0];
                    addr <= addr + 1; //supports address rollover
                    spi_state <= SPI_DATA; //stay in SPI_DATA for additional bytes until cs
                end
            endcase
        end
    end

endmodule