module ch_spi_readout (
    input logic INST_READOUT,
    input logic SPI_CLK,
    input logic RSTB,
    input logic [2:0] SELECT_REG,
    
    input logic [2:0] trigger_cnt,
    input logic [9:0] CE,
    input logic [9:0] CD,
    input logic [9:0] CC,
    input logic [9:0] CB,
    input logic [9:0] CA,

    output logic CNT_SER
);

    logic [2:0] ser_pos;
    logic [55:0] ctmp;

    always_ff @(posedge INST_READOUT) begin
        ctmp <= {<<{3'b000, trigger_cnt, CE, CD, CC, CB, CA}}; //56 bits total. streamed to be backward here to later be MSB to LSB
    end


    always_ff @(posedge SPI_CLK, negedge RSTB) begin
        if (!RSTB) begin
            ser_pos <= 0;
        end
        else begin //Default behavior when SPI_CLK is high
            CNT_SER <= ctmp[SELECT_REG*8+ser_pos];
            ser_pos <= ser_pos + 1; //only 3 bit, so effectively mod 8
        end
    end

endmodule