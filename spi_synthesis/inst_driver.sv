module inst_driver (
    //takes instruction async (no clock)
    input logic [1:0] inst_reg,
    input logic cs,
    input logic rstn,
    input logic inst_stop, //should be connected to trigger in, stops sampling clk

    //from channels/register, for trigger out
    input logic [7:0] stop_request,
    input logic [7:0] trigger_channel_mask,

    //sent to channels
    output logic inst_rst,
    output logic inst_readout,
    output logic inst_start,
    output logic clk_enable,

    //sent to chip pin
    output logic trigger_out
);
    logic full_rstn;
    assign full_rstn = cs && rstn;

    //trigger out logic using mask and discriminator fires
    assign trigger_out = |(stop_request & trigger_channel_mask);

    //these generate pulses implicitly with width of cs high
    //only generate one pulse per time written to instruction by resetting instruction reg on cs
    always_comb begin
        if (!full_rstn) begin
            inst_rst = 0;
            inst_readout = 0;
            inst_start = 0;
        end 
        else if (inst_reg == 2'd1) begin //reset command
            inst_rst = 1;
            inst_readout = 0;
            inst_start = 0;
        end
        else if (inst_reg == 2'd2) begin //readout command
            inst_rst = 0;
            inst_readout = 1;
            inst_start = 0;
        end
        else if (inst_reg == 2'd3) begin //start command
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

    //SR latch to enable/disable 5GHz sampling clk
    always_latch begin
        if (!rstn) begin
            clk_enable <= 1'b0;
        end
        else if (inst_start) begin
            clk_enable <= 1'b1;
        end
        else if (inst_stop) begin
            clk_enable <= 1'b0;
        end
    end
endmodule