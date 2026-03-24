module addr_to_ch_select #(
    parameter integer CH_REG_START_ADDR = 12, //first channel-based reg address
    parameter integer CH_REG_STOP_ADDR = 67 //last channel-based reg address
) (
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
    always_comb begin
        case (addr_one) inside
            [7'd12 : 7'd18]: select_reg = addr_one - 7'd12;
            [7'd19 : 7'd25]: select_reg = addr_one - 7'd19;
            [7'd26 : 7'd32]: select_reg = addr_one - 7'd26;
            [7'd33 : 7'd39]: select_reg = addr_one - 7'd33;
            [7'd40 : 7'd46]: select_reg = addr_one - 7'd40;
            [7'd47 : 7'd53]: select_reg = addr_one - 7'd47;
            [7'd54 : 7'd60]: select_reg = addr_one - 7'd54;
            [7'd61 : 7'd67]: select_reg = addr_one - 7'd61;
            default:         select_reg = 3'd7;
        endcase
    end

endmodule