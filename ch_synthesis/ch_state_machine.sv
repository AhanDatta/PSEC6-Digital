import types_pkg::*;

module ch_state_machine (
    input logic trigger,          //processed discriminator output, should move sampling state
    input logic INST_START,       //should start sampling state based on mode
    input logic INST_STOP,        //should move state to stopped
    input logic INST_READOUT,     //should move state to readout
    input logic RSTB,            //system reset
    input smode_t MODE,
    
    output logic STOP_REQUEST, //goes to trigger out, or'd from each channel
    output state_t current_state, //used to control trigger gating
    output logic [2:0] trigger_cnt //how many triggers happened, up to max number of events capturable in a given mode (ex: max = 4 for mode = MODE_SAMPLE1)
);

    //large state machine, large sensitivity list is okay since these signals are mutually exclusive
    always_ff @(posedge trigger, posedge INST_START, posedge INST_STOP, posedge INST_READOUT, negedge RSTB) begin
        if (!RSTB) begin
            current_state <= STATE_INIT;
            trigger_cnt <= '0;
        end
        else if (INST_READOUT) begin
            current_state <= STATE_READOUT;
            // trigger_cnt and STOP_REQUEST hold their values
        end
        else if (INST_STOP) begin
            current_state <= STATE_STOPPED;
            // trigger_cnt and STOP_REQUEST hold their values
        end
        else if (INST_START) begin
            case (MODE)
                MODE_SAMPLE1: current_state <= STATE_SAMPLING_A;
                MODE_SAMPLE2: current_state <= STATE_SAMPLING_A_AND_B;
                MODE_SAMPLE4: current_state <= STATE_SAMPLING_ALL;
                default: current_state <= STATE_SAMPLING_ALL;
            endcase
            trigger_cnt <= '0;
        end
        else if (trigger) begin
            // Only advance if we're in a sampling state
            case (current_state)
                STATE_SAMPLING_A: begin
                    current_state <= STATE_SAMPLING_B;
                    trigger_cnt <= 3'd1;
                end
                STATE_SAMPLING_B: begin
                    current_state <= STATE_SAMPLING_C;
                    trigger_cnt <= 3'd2;
                end
                STATE_SAMPLING_C: begin
                    current_state <= STATE_SAMPLING_D;
                    trigger_cnt <= 3'd3;
                end
                STATE_SAMPLING_D: begin
                    current_state <= STATE_SAMPLING_E;
                    trigger_cnt <= 3'd4;
                end
                STATE_SAMPLING_A_AND_B: begin
                    current_state <= STATE_SAMPLING_C_AND_D;
                    trigger_cnt <= 3'd1;
                end
                STATE_SAMPLING_C_AND_D: begin
                    current_state <= STATE_SAMPLING_E;
                    trigger_cnt <= 3'd2;
                end
                STATE_SAMPLING_ALL: begin
                    current_state <= STATE_SAMPLING_E;
                    trigger_cnt <= 3'd1;
                end
                // In other states, trigger does nothing
                default: begin
                    current_state <= current_state;
                    trigger_cnt <= trigger_cnt + 1;
                end
            endcase
        end
    end

    //STOP_REQUEST is or'd from each channel to trigger out
    always_ff @(posedge trigger, posedge INST_START) begin
        if (INST_START) begin
            STOP_REQUEST <= 0;
        end
        else begin
            STOP_REQUEST <= 1;
        end
    end

endmodule