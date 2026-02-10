module ref_clk_sel_decoder (
    //local power
    inout DVDD,
    inout DVSS,
    
    input logic rstn,
    input logic [2:0] ref_clk_sel,

    output logic [4:0] tgate_control //lowest order bit = 512. In order, enables for {32, 64, 128, 256, 512}
);

    always_comb begin
        if (!rstn) begin
            tgate_control = 5'b00010;
        end
        else begin
            unique case (ref_clk_sel) 
                3'd0 : tgate_control = 5'b00001;
                3'd1 : tgate_control = 5'b00010;
                3'd2 : tgate_control = 5'b00100;
                3'd3 : tgate_control = 5'b01000;
                3'd4 : tgate_control = 5'b10000;
                default : tgate_control = 5'b00010; //default to 256 division
            endcase
        end
    end

endmodule