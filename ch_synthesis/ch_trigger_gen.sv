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
    always_latch begin 
        if (INST_START) begin
            premature_trigger = 1'b1;
        end
        else if (CE > 10'h00f && CE != 10'h3ff) begin //trigger E has counted more than 16 clock cycles
            premature_trigger = 1'b0;
        end
    end

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