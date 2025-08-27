import types_pkg::*;

module ch_trigger_gen (
    input logic FCLK,
    input logic INST_START,
    input logic DISCRIMINATOR_OUTPUT,
    input logic DISCRIMINATOR_POLARITY,
    input logic [4:0] TRIG_DELAY,
    input state_t current_state,

    output logic trigger
);

    logic premature_trigger;
    logic [31:0] trig_shift_reg;

    always_ff @(posedge FCLK, posedge INST_START) begin
        if(INST_START) begin
          trig_shift_reg <= 32'b1; //Zero all registers except the first bit. After 6.4ns, when the bit reaches the last register, release the premature_trigger.
          premature_trigger <= 1;
        end
        else begin
          trig_shift_reg <= {trig_shift_reg[30:0], DISCRIMINATOR_OUTPUT};
          if(trig_shift_reg[31]) begin
            premature_trigger <= 0;
          end
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
                if (TRIG_DELAY == 5'b0) begin
                    trigger = (DISCRIMINATOR_OUTPUT ^ DISCRIMINATOR_POLARITY) & (!premature_trigger); //async to FCLK
                end
                else begin
                    trigger = (trig_shift_reg[TRIG_DELAY] ^ DISCRIMINATOR_POLARITY) & (!premature_trigger); //sync to FCLK
                end 
            end
        endcase
    end

endmodule