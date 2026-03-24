module readout_mux #(
    parameter integer CH_REG_START_ADDR = 12, 
    parameter integer CH_REG_STOP_ADDR = 67,
    parameter integer NUM_REGS_PER_CH = 7
) (
    input logic spi_clk, 
    input logic [7:0] poci_ch, 
    input logic poci_spi, 
    input logic cs,
    input logic rstn,
    input logic [6:0] addr, 

    output logic poci
);
    
    logic full_rstn;
    logic [6:0] addr_one;

    assign full_rstn = cs & rstn;

    //delays the address by one to match the switching time properly
    always_ff @(posedge spi_clk or negedge full_rstn) begin
        if (!full_rstn) begin
            addr_one <= '0;
        end
        else begin
            addr_one <= addr;
        end
    end

    //explicit mux for the poci output
    always_comb begin
        case (addr_one) inside
            7'd0:            poci = 1'b0;
            [7'd12 : 7'd18]: poci = poci_ch[0];
            [7'd19 : 7'd25]: poci = poci_ch[1];
            [7'd26 : 7'd32]: poci = poci_ch[2];
            [7'd33 : 7'd39]: poci = poci_ch[3];
            [7'd40 : 7'd46]: poci = poci_ch[4];
            [7'd47 : 7'd53]: poci = poci_ch[5];
            [7'd54 : 7'd60]: poci = poci_ch[6];
            [7'd61 : 7'd67]: poci = poci_ch[7];
            default:         poci = poci_spi;
        endcase
    end

endmodule