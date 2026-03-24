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
    
    //full async reset
    assign full_rstn = cs && rstn;

    //clock counter
    always_ff @(posedge spi_clk or negedge full_rstn) begin
        if (!full_rstn) begin
            spi_clk_counter <= '0;
        end
        else begin
            spi_clk_counter <= spi_clk_counter + 16'd1;
        end
    end 

    //byte flag generator to signal the end of a byte
    always_comb begin
        if (spi_clk_counter != 16'd0 && spi_clk_counter[2:0] == 3'b000) begin
            byte_flag = 1'b1;
        end 
        else begin
            byte_flag = 1'b0;
        end
    end

    //read state machine for spi
    always_ff @(posedge spi_clk or negedge full_rstn) begin
        if (!full_rstn) begin
            is_write <= 1'b0;
            addr <= '0;
            wdata <= '0;
            spi_state <= SPI_ADDR;
        end
        else begin
            // Synchronous Clock Enable
            if (byte_flag) begin
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
                        addr <= addr + 7'd1; //supports address rollover
                        
                        // Remains in SPI_DATA state to accept subsequent bytes
                        spi_state <= SPI_DATA; 
                    end
                    
                    //literally impossible but ok
                    default: begin
                        spi_state <= SPI_ADDR;
                    end
                endcase
            end
        end
    end

endmodule