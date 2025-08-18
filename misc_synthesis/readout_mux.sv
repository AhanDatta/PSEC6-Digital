module readout_mux (
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

    // POCI Output Multiplexer
    always_comb begin
        case (addr_one)
            //SPI registers (0-9) - output from SPI itself
            7'd0, 7'd1, 7'd2, 7'd3, 7'd4, 7'd5, 7'd6, 7'd7, 7'd8, 7'd9: begin
                poci = poci_spi;
            end
            
            //channel 0 registers (10-17)
            7'd10, 7'd11, 7'd12, 7'd13, 7'd14, 7'd15, 7'd16, 7'd17: begin
                poci = poci_ch[0];
            end
            
            //channel 1 registers (18-24)
            7'd18, 7'd19, 7'd20, 7'd21, 7'd22, 7'd23, 7'd24: begin
                poci = poci_ch[1];
            end
            
            //channel 2 registers (25-31)
            7'd25, 7'd26, 7'd27, 7'd28, 7'd29, 7'd30, 7'd31: begin
                poci = poci_ch[2];
            end
            
            //channel 3 registers (32-38)
            7'd32, 7'd33, 7'd34, 7'd35, 7'd36, 7'd37, 7'd38: begin
                poci = poci_ch[3];
            end
            
            //channel 4 registers (39-45)
            7'd39, 7'd40, 7'd41, 7'd42, 7'd43, 7'd44, 7'd45: begin
                poci = poci_ch[4];
            end
            
            //channel 5 registers (46-52)
            7'd46, 7'd47, 7'd48, 7'd49, 7'd50, 7'd51, 7'd52: begin
                poci = poci_ch[5];
            end
            
            //channel 6 registers (53-59)
            7'd53, 7'd54, 7'd55, 7'd56, 7'd57, 7'd58, 7'd59: begin
                poci = poci_ch[6];
            end
            
            //channel 7 registers (60-66)
            7'd60, 7'd61, 7'd62, 7'd63, 7'd64, 7'd65, 7'd66: begin
                poci = poci_ch[7];
            end
            
            //default case for addresses > 66
            default: begin
                poci = 1'b0; 
            end
        endcase
    end

endmodule