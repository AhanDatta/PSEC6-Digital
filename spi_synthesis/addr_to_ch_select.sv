module addr_to_ch_select (
    input logic rstn,
    input logic csb,
    input logic [6:0] addr,

    output logic [2:0] select_reg
);
    //follows formula select_reg = (addr-11) % 7 to choose the correct reg from each channel to read out
    always_comb begin
    unique case (addr)
        // addr 11-17: select_reg = 0-6
        7'd11: select_reg = 3'd0;
        7'd12: select_reg = 3'd1;
        7'd13: select_reg = 3'd2;
        7'd14: select_reg = 3'd3;
        7'd15: select_reg = 3'd4;
        7'd16: select_reg = 3'd5;
        7'd17: select_reg = 3'd6;
        
        // addr 18-24: select_reg = 0-6
        7'd18: select_reg = 3'd0;
        7'd19: select_reg = 3'd1;
        7'd20: select_reg = 3'd2;
        7'd21: select_reg = 3'd3;
        7'd22: select_reg = 3'd4;
        7'd23: select_reg = 3'd5;
        7'd24: select_reg = 3'd6;
        
        // addr 25-31: select_reg = 0-6
        7'd25: select_reg = 3'd0;
        7'd26: select_reg = 3'd1;
        7'd27: select_reg = 3'd2;
        7'd28: select_reg = 3'd3;
        7'd29: select_reg = 3'd4;
        7'd30: select_reg = 3'd5;
        7'd31: select_reg = 3'd6;
        
        // addr 32-38: select_reg = 0-6
        7'd32: select_reg = 3'd0;
        7'd33: select_reg = 3'd1;
        7'd34: select_reg = 3'd2;
        7'd35: select_reg = 3'd3;
        7'd36: select_reg = 3'd4;
        7'd37: select_reg = 3'd5;
        7'd38: select_reg = 3'd6;
        
        // addr 39-45: select_reg = 0-6
        7'd39: select_reg = 3'd0;
        7'd40: select_reg = 3'd1;
        7'd41: select_reg = 3'd2;
        7'd42: select_reg = 3'd3;
        7'd43: select_reg = 3'd4;
        7'd44: select_reg = 3'd5;
        7'd45: select_reg = 3'd6;
        
        // addr 46-52: select_reg = 0-6
        7'd46: select_reg = 3'd0;
        7'd47: select_reg = 3'd1;
        7'd48: select_reg = 3'd2;
        7'd49: select_reg = 3'd3;
        7'd50: select_reg = 3'd4;
        7'd51: select_reg = 3'd5;
        7'd52: select_reg = 3'd6;
        
        // addr 53-59: select_reg = 0-6
        7'd53: select_reg = 3'd0;
        7'd54: select_reg = 3'd1;
        7'd55: select_reg = 3'd2;
        7'd56: select_reg = 3'd3;
        7'd57: select_reg = 3'd4;
        7'd58: select_reg = 3'd5;
        7'd59: select_reg = 3'd6;
        
        // addr 60-66: select_reg = 0-6
        7'd60: select_reg = 3'd0;
        7'd61: select_reg = 3'd1;
        7'd62: select_reg = 3'd2;
        7'd63: select_reg = 3'd3;
        7'd64: select_reg = 3'd4;
        7'd65: select_reg = 3'd5;
        7'd66: select_reg = 3'd6;

        // default case
        default: select_reg = 3'b111;
    endcase
end

endmodule