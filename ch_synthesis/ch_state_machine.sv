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

    state_t next_state; 

    //state machine using trigger as clock, 4 async resets, and combinational logic for moving forward
    always_comb begin
        if (!RSTB) next_state = STATE_INIT;
        else if (INST_READOUT) next_state = STATE_READOUT;
        else if (INST_STOP) next_state = STATE_STOPPED;
        else if (INST_START) begin
            case (MODE) 
                MODE_SAMPLE1: next_state = STATE_SAMPLING_A;
                MODE_SAMPLE2: next_state = STATE_SAMPLING_A_AND_B;
                MODE_SAMPLE4: next_state = STATE_SAMPLING_ALL;
                default: next_state = STATE_SAMPLING_ALL; //defaults to using all 4 fast buffers on one event
            endcase
        end
        else if (trigger) begin
            case (current_state) 
                STATE_SAMPLING_A: next_state = STATE_SAMPLING_B; //1 fast buff per event path
                STATE_SAMPLING_B: next_state = STATE_SAMPLING_C;
                STATE_SAMPLING_C: next_state = STATE_SAMPLING_D;
                STATE_SAMPLING_D: next_state = STATE_SAMPLING_E;

                STATE_SAMPLING_A_AND_B: next_state = STATE_SAMPLING_C_AND_D; //2 fast buff per event path
                STATE_SAMPLING_C_AND_D: next_state = STATE_SAMPLING_E;

                STATE_SAMPLING_ALL: next_state = STATE_SAMPLING_E; //4 fast buff per event path
            endcase
        end
        else begin //defaults to current state
            next_state = current_state;
        end
    end

    always_ff @(posedge trigger, negedge RSTB, posedge INST_READOUT, posedge INST_STOP, posedge INST_START) begin //long sensitivity list?
        current_state <= next_state;

        //infering trigger count based on the state
        case (next_state) 
            STATE_SAMPLING_A: trigger_cnt = '0; //when started sampling, no triggers
            STATE_SAMPLING_A_AND_B: trigger_cnt = '0;
            STATE_SAMPLING_ALL: trigger_cnt = '0;

            STATE_SAMPLING_B: trigger_cnt = 3'd1; //1 fast buff per event path
            STATE_SAMPLING_C: trigger_cnt = 3'd2;
            STATE_SAMPLING_D: trigger_cnt = 3'd3;

            STATE_SAMPLING_C_AND_D: trigger_cnt = 3'd1; //2 fast buff per event path

            STATE_SAMPLING_E: trigger_cnt = trigger_cnt + 1; //last step in all paths
        endcase
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