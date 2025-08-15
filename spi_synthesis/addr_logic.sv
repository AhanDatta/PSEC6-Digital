module addr_logic (
    input logic spi_clk,
    input logic csb,
    input logic rstn,
    input logic [7:0] byte_deser, //output from serdes
    input logic pico,

    output logic is_write, //active high, msb of first byte sets this
    output logic [6:0] addr, //seven lowest order bits of first byte
    output logic [7:0] wdata //set for each byte after the first
);
    logic [15:0] spi_clk_counter; //used to track which part of the transaction we are in
    logic byte_flag;
    logic full_rstn;
    assign full_rstn = csb && rstn;

    always_ff @(posedge spi_clk or negedge full_rstn) begin
        if (!full_rstn) begin
            spi_clk_counter <= '0;
            byte_flag <= 0;
        end
        else begin
            spi_clk_counter <= spi_clk_counter + 1;
            if (spi_clk_counter != 0 && spi_clk_counter % 8 == 7) begin
                byte_flag <= 1;
            end 
            else begin
                byte_flag <= 0;
            end
        end
    end 

    always_ff @(posedge byte_flag or negedge full_rstn) begin
        if (!full_rstn) begin
            is_write <= 0;
            addr <= '0;
            wdata <= '0; 
        end
        else begin
            if (spi_clk_counter == 16'd7) begin
                is_write <= byte_deser[7]; //msb is used to declare write
                addr <= {byte_deser[5:0], pico}; //lower order bits set initial address, have to use hack
                wdata <= '0;
            end
            else begin
                is_write <= is_write;
                addr <= addr + 1; //increment address on each additional byte
                wdata <= {byte_deser[6:0], pico};
            end 
        end
    end

endmodule