import types_pkg::*;

module ch_trigger_gen (
    input logic [9:0] CE, //first counter
    input logic INST_START,
    input logic DISCRIMINATOR_OUTPUT,
    input logic DISCRIMINATOR_POLARITY,
    input state_t current_state,

    output logic trigger
);

    // Logic to flush the fast buffer before allowing a trigger
    // If more than 32 fclk cycles passed after start of sampling (starting at 10'h3ff), not premature trigger
    logic premature_trigger;
    assign premature_trigger = (CE > 10'h00f || CE == 10'h3ff) ? 0 : 1; 

    always_comb begin
        case (current_state)
            STATE_STOPPED: begin
                trigger = 0;
            end
            STATE_INIT: begin
                trigger = 0;
            end
            STATE_READOUT: begin
                trigger = 0;
            end
            default: begin
                    trigger = (DISCRIMINATOR_OUTPUT ^ DISCRIMINATOR_POLARITY) & (!premature_trigger); //async to FCLK
            end
        endcase
    end

endmodule