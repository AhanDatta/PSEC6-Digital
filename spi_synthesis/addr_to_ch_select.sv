module addr_to_ch_select #(
    parameter integer CH_REG_START_ADDR = 12, //first channel-based reg address
    parameter integer CH_REG_STOP_ADDR = 67 //last channel-based reg address
) (
    //local power
    inout DVDD,
    inout DVSS,
 
    //inputs
    input logic rstn,
    input logic cs,
    input logic spi_clk,
    input logic [6:0] addr,

    //send to all digital channels
    output logic [2:0] select_reg
);

    logic full_rstn;
    logic [6:0] addr_one; //address lagging 1 spi_clk
    assign full_rstn = cs && rstn;

    always_ff @(posedge spi_clk or negedge full_rstn) begin
        if (!full_rstn) begin
            addr_one <= '0;
        end 
        else begin
            addr_one <= addr;
        end
    end

    //loads the correct register based on the address, timestamps are between 12-67, otherwise default to 111 (unloaded)
    assign select_reg = (addr_one >= CH_REG_START_ADDR && addr_one <= CH_REG_STOP_ADDR) ? ((addr_one - CH_REG_START_ADDR) % 7) : 3'd7;

endmodule