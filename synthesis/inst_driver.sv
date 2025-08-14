module inst_driver (
    input logic [7:0] inst_reg,
    input logic csb,
    input logic rstn,

    output logic inst_rst,
    output logic inst_readout,
    output logic inst_start
);
    logic full_rstn;
    assign full_rstn = csb && rstn;

    //these generate pulses implicitly with width of csb low
    //only generate one pulse per time written to instruction by resetting instruction reg on csb
    always_comb begin
        if (!full_rstn) begin
            inst_rst = 0;
            inst_readout = 0;
            inst_start = 0;
        end 
        else begin
            if (inst_reg == 8'd1) begin //reset command
                inst_rst = 1;
                inst_readout = 0;
                inst_start = 0;
            end
            else if (inst_reg == 8'd2) begin //readout command
                inst_rst = 0;
                inst_readout = 1;
                inst_start = 0;
            end
            else if (inst_reg == 8'd3) begin //start command
                inst_rst = 0;
                inst_readout = 0;
                inst_start = 1;
            end
            else begin //default to doing nothing
                inst_rst = 0;
                inst_readout = 0;
                inst_start = 0;
            end
        end 
    end 
endmodule