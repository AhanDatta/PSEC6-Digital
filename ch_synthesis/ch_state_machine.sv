import types_pkg::*;

module ch_state_machine (
    input logic trigger,          //processed discriminator output, should move sampling state
    input logic INST_START,       //to control the STOP_REQUEST output
    input logic start1,           //start sampling 1 fast buff per trigger
    input logic start2,           //start sampling 2 fast buff per trigger
    input logic start4,           //start sampling 4 fast buff per trigger
    input logic INST_STOP,        //should move state to stopped
    input logic INST_READOUT,     //should move state to readout
    input logic RSTB,            //system reset
    
    output logic STOP_REQUEST, //goes to trigger out, or'd from each channel
    output state_t current_state, //used to control trigger gating
    output logic [2:0] trigger_cnt //how many triggers happened, up to max number of events capturable in a given mode (ex: max = 4 for mode = MODE_SAMPLE1)
);

    //asynchronous command capture (sr latches)
    logic mode_sampling;
    logic mode_readout;
    logic mode_stopped;
    smode_t sample_type; //using the enum from types_pkg to remember the mode

    always_latch begin
        if (!RSTB) begin
            mode_sampling = 1'b0;
            mode_readout  = 1'b0;
            mode_stopped  = 1'b1;
            sample_type   = MODE_SAMPLE1;
        end else if (INST_STOP) begin
            mode_sampling = 1'b0;
            mode_readout  = 1'b0;
            mode_stopped  = 1'b1;
        end else if (INST_READOUT) begin
            mode_sampling = 1'b0;
            mode_readout  = 1'b1;
            mode_stopped  = 1'b0;
        end else if (start1 || start2 || start4) begin
            mode_sampling = 1'b1;
            mode_readout  = 1'b0;
            mode_stopped  = 1'b0;
            
            //remember which start command fired using smode_t
            if (start1)      sample_type = MODE_SAMPLE1;
            else if (start2) sample_type = MODE_SAMPLE2;
            else if (start4) sample_type = MODE_SAMPLE4;
        end
    end

    //fast trigger state machine
    //we use the start commands to asynchronously reset the fast trigger counter
    logic fast_rstb;
    assign fast_rstb = RSTB & ~(start1 | start2 | start4); 

    //trigger_cnt itself acts as our fast state variable
    always_ff @(posedge trigger or negedge fast_rstb) begin
        if (!fast_rstb) begin
            trigger_cnt <= '0;
        end else if (mode_sampling) begin
            //prevent the counter from incrementing past the final buffer state
            if ((sample_type == MODE_SAMPLE1 && trigger_cnt < 3'd4) ||
                (sample_type == MODE_SAMPLE2 && trigger_cnt < 3'd2) ||
                (sample_type == MODE_SAMPLE4 && trigger_cnt < 3'd1)) begin
                trigger_cnt <= trigger_cnt + 1;
            end
        end
    end

    //output state combination
    always_comb begin
        if (mode_stopped) begin
            current_state = STATE_STOPPED;
        end else if (mode_readout) begin
            current_state = STATE_READOUT;
        end else if (mode_sampling) begin
            
            //map the fast trigger_cnt and sample_type to your specific sampling states
            case (sample_type)
                MODE_SAMPLE1: begin
                    case (trigger_cnt)
                        3'd0: current_state = STATE_SAMPLING_A;
                        3'd1: current_state = STATE_SAMPLING_B;
                        3'd2: current_state = STATE_SAMPLING_C;
                        3'd3: current_state = STATE_SAMPLING_D;
                        default: current_state = STATE_SAMPLING_E;
                    endcase
                end
                
                MODE_SAMPLE2: begin
                    case (trigger_cnt)
                        3'd0: current_state = STATE_SAMPLING_A_AND_B;
                        3'd1: current_state = STATE_SAMPLING_C_AND_D;
                        default: current_state = STATE_SAMPLING_E;
                    endcase
                end
                
                MODE_SAMPLE4: begin
                    case (trigger_cnt)
                        3'd0: current_state = STATE_SAMPLING_ALL;
                        default: current_state = STATE_SAMPLING_E;
                    endcase
                end
                
                default: current_state = STATE_INIT;
            endcase
            
        end else begin
            current_state = STATE_INIT;
        end
    end

    //STOP_REQUEST is or'd from each channel to trigger out
    always_ff @(posedge trigger, posedge INST_START) begin
        if (INST_START) begin
            STOP_REQUEST <= '0;
        end
        else begin
            STOP_REQUEST <= '1;
        end
    end

    //large state machine, unsynthesizable
    // always_ff @(posedge trigger, posedge start1, posedge start2, posedge start4, posedge INST_STOP, posedge INST_READOUT, negedge RSTB) begin
    //     if (!RSTB) begin
    //         current_state <= STATE_INIT;
    //         trigger_cnt <= '0;
    //     end
    //     else if (INST_READOUT) begin
    //         current_state <= STATE_READOUT;
    //         // trigger_cnt and STOP_REQUEST hold their values
    //     end
    //     else if (INST_STOP) begin
    //         current_state <= STATE_STOPPED;
    //         // trigger_cnt and STOP_REQUEST hold their values
    //     end
    //     else if (start1) begin
    //         MODE_SAMPLE1: current_state <= STATE_SAMPLING_A;
    //         trigger_cnt <= '0;
    //     end
    //     else if (start2) begin
    //         MODE_SAMPLE2: current_state <= STATE_SAMPLING_A_AND_B;
    //         trigger_cnt <= '0;
    //     end
    //     else if (start4) begin
    //         MODE_SAMPLE4: current_state <= STATE_SAMPLING_ALL;
    //         trigger_cnt <= '0;
    //     end
    //     else if (trigger) begin
    //         // Only advance if we're in a sampling state
    //         case (current_state)
    //             STATE_SAMPLING_A: begin
    //                 current_state <= STATE_SAMPLING_B;
    //                 trigger_cnt <= 3'd1;
    //             end
    //             STATE_SAMPLING_B: begin
    //                 current_state <= STATE_SAMPLING_C;
    //                 trigger_cnt <= 3'd2;
    //             end
    //             STATE_SAMPLING_C: begin
    //                 current_state <= STATE_SAMPLING_D;
    //                 trigger_cnt <= 3'd3;
    //             end
    //             STATE_SAMPLING_D: begin
    //                 current_state <= STATE_SAMPLING_E;
    //                 trigger_cnt <= 3'd4;
    //             end
    //             STATE_SAMPLING_A_AND_B: begin
    //                 current_state <= STATE_SAMPLING_C_AND_D;
    //                 trigger_cnt <= 3'd1;
    //             end
    //             STATE_SAMPLING_C_AND_D: begin
    //                 current_state <= STATE_SAMPLING_E;
    //                 trigger_cnt <= 3'd2;
    //             end
    //             STATE_SAMPLING_ALL: begin
    //                 current_state <= STATE_SAMPLING_E;
    //                 trigger_cnt <= 3'd1;
    //             end
    //             STATE_SAMPLING_E: begin // Last fast buffer used, so trigger does nothing
    //                 current_state <= current_state;
    //                 trigger_cnt <= trigger_cnt;
    //             end
    //             // In other states (such as readout or stopped), trigger does nothing
    //             default: begin
    //                 current_state <= current_state;
    //                 trigger_cnt <= trigger_cnt;
    //             end
    //         endcase
    //     end
    // end

    

endmodule