import types_pkg::*;

module ch_state_decoder (
    // Input
    input state_t current_state,
    
    //Triggers for buffers, A-D fast, E slow. Active Low signals
    output logic TRIGGERA,
    output logic TRIGGERAC,
    output logic TRIGGERB,
    output logic TRIGGERBC,
    output logic TRIGGERC,
    output logic TRIGGERCC,
    output logic TRIGGERD,
    output logic TRIGGERDC,
    output logic TRIGGERE
);

    //Control latch decoder logic 
    always_comb begin
        // Update the control latches based on the current state
        case (current_state)
            STATE_INIT:
                begin
                    TRIGGERA = 1;
                    TRIGGERAC = 1;
                    TRIGGERB = 1;
                    TRIGGERBC = 1;
                    TRIGGERC = 1;
                    TRIGGERCC = 1;
                    TRIGGERD = 1;
                    TRIGGERDC = 1;
                    TRIGGERE = 1;
                end
            STATE_STOPPED:
                begin
                    TRIGGERA = 1;
                    TRIGGERAC = 1;
                    TRIGGERB = 1;
                    TRIGGERBC = 1;
                    TRIGGERC = 1;
                    TRIGGERCC = 1;
                    TRIGGERD = 1;
                    TRIGGERDC = 1;
                    TRIGGERE = 1;
                end
            STATE_READOUT:
                begin
                    TRIGGERA = 1;
                    TRIGGERAC = 1;
                    TRIGGERB = 1;
                    TRIGGERBC = 1;
                    TRIGGERC = 1;
                    TRIGGERCC = 1;
                    TRIGGERD = 1;
                    TRIGGERDC = 1;
                    TRIGGERE = 1;
                end
            STATE_SAMPLING_A:
                begin
                    TRIGGERA = 0;
                    TRIGGERAC = 0;
                    TRIGGERB = 1;
                    TRIGGERBC = 0;
                    TRIGGERC = 1;
                    TRIGGERCC = 0;
                    TRIGGERD = 1;
                    TRIGGERDC = 0;
                    TRIGGERE = 0;
                end
            STATE_SAMPLING_B:
                begin
                    TRIGGERA = 1;
                    TRIGGERAC = 1;
                    TRIGGERB = 0;
                    TRIGGERBC = 0;
                    TRIGGERC = 1;
                    TRIGGERCC = 0;
                    TRIGGERD = 1;
                    TRIGGERDC = 0;
                    TRIGGERE = 0;
                end
            STATE_SAMPLING_C:
                begin
                    TRIGGERA = 1;
                    TRIGGERAC = 1;
                    TRIGGERB = 1;
                    TRIGGERBC = 1;
                    TRIGGERC = 0;
                    TRIGGERCC = 0;
                    TRIGGERD = 1;
                    TRIGGERDC = 0;
                    TRIGGERE = 0;
                end
            STATE_SAMPLING_D:
                begin
                    TRIGGERA = 1;
                    TRIGGERAC = 1;
                    TRIGGERB = 1;
                    TRIGGERBC = 1;
                    TRIGGERC = 1;
                    TRIGGERCC = 1;
                    TRIGGERD = 0;
                    TRIGGERDC = 0;
                    TRIGGERE = 0;
                end
            STATE_SAMPLING_E:
                begin
                    TRIGGERA = 1;
                    TRIGGERAC = 1;
                    TRIGGERB = 1;
                    TRIGGERBC = 1;
                    TRIGGERC = 1;
                    TRIGGERCC = 1;
                    TRIGGERD = 1;
                    TRIGGERDC = 1;
                    TRIGGERE = 0;
                end
            STATE_SAMPLING_A_AND_B:
                begin
                    TRIGGERA = 0;
                    TRIGGERAC = 0;
                    TRIGGERB = 0;
                    TRIGGERBC = 0;
                    TRIGGERC = 1;
                    TRIGGERCC = 0;
                    TRIGGERD = 1;
                    TRIGGERDC = 0;
                    TRIGGERE = 0;
                end
            STATE_SAMPLING_C_AND_D:
                begin
                    TRIGGERA = 1;
                    TRIGGERAC = 1;
                    TRIGGERB = 1;
                    TRIGGERBC = 1;
                    TRIGGERC = 0;
                    TRIGGERCC = 0;
                    TRIGGERD = 0;
                    TRIGGERDC = 0;
                    TRIGGERE = 0;
                end
            STATE_SAMPLING_ALL:
                begin
                    TRIGGERA = 0;
                    TRIGGERAC = 0;
                    TRIGGERB = 0;
                    TRIGGERBC = 0;
                    TRIGGERC = 0;
                    TRIGGERCC = 0;
                    TRIGGERD = 0;
                    TRIGGERDC = 0;
                    TRIGGERE = 0;
                end
            default: // Handle any other states if necessary
                begin
                    // Default behavior
                    TRIGGERA = 1;
                    TRIGGERAC = 1;
                    TRIGGERB = 1;
                    TRIGGERBC = 1;
                    TRIGGERC = 1;
                    TRIGGERCC = 1;
                    TRIGGERD = 1;
                    TRIGGERDC = 1;
                    TRIGGERE = 1;
                end
        endcase
    end

endmodule