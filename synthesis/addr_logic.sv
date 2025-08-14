module addr_logic (
    input logic spi_clk,
    input logic csb,
    input logic rstn,
    input logic [7:0] byte_deser, //output from serdes

    output logic is_write, //active high, msb of first byte sets this
    output logic [6:0] addr, //seven lowest order bits of first byte
    output logic [7:0] wdata //set for each byte after the first
);
    logic [15:0] spi_clk_counter; //used to track which part of the transaction we are in
    logic full_rstn;
    assign full_rstn = csb && rstn;

    always_ff @(posedge spi_clk or negedge full_rstn) begin
        if (!full_rstn) begin
            spi_clk_counter <= '0;
        end
        else begin
            spi_clk_counter <= spi_clk_counter + 1;
        end
    end 

    always_latch begin //using the clock counter to latch our data
        if (spi_clk_counter == 0) begin
            is_write <= 0;
            addr <= '0;
            wdata <= '0;
        end 
        else if (spi_clk_counter == 16'd8) begin
            is_write <= byte_deser[7]; //msb is used to declare write
            addr <= byte_deser[6:0]; //lower order bits set initial address
            wdata <= '0;
        end 
        else if (spi_clk_counter % 8 == 0) begin //is_write shouldn't change
            addr <= addr + 1; //increment address on each additional byte
            wdata <= byte_deser;
        end 
    end

endmodule