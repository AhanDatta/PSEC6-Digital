import types_pkg::*;

module PSEC5_CH_DIGITAL (
    input logic INST_START,
    input logic INST_STOP,
    input logic INST_READOUT,
    input logic RSTB,
    input logic DISCRIMINATOR_OUTPUT, // This is the unsync'ed input from the discriminator, which is in the analog part of the PSEC5.
    input logic SPI_CLK, //moved some of the spi shift registers into this module, for the sake of speed and simplicity.
    input logic [9:0] CA, //These are counter values.
    input logic [9:0] CB,
    input logic [9:0] CC,
    input logic [9:0] CD,
    input logic [9:0] CE,
    input smode_t MODE,
    input logic DISCRIMINATOR_POLARITY,
    input logic [2:0] SELECT_REG,
    input logic [4:0] TRIG_DELAY,
    input logic FCLK, //gated on clk_enable from SPI, which is an SR latch (INST_START/INST_STOP)
    //final trigger outputs of the module must be sync to FCLK (5GHz clock) to avoid metastability issues. This is not implemented in this module yet.
    output logic STOP_REQUEST,
    output logic TRIGGERA,
    output logic TRIGGERB,
    output logic TRIGGERC,
    output logic TRIGGERD,
    output logic TRIGGERE,
    output logic TRIGGERAC,
    output logic TRIGGERBC,
    output logic TRIGGERCC,
    output logic TRIGGERDC,
    output logic CNT_SER
);  
    state_t current_state;
    logic start1;
    logic start2;
    logic start4;
    logic trigger;
    logic [2:0] trigger_cnt; //# of legitimate trigger fires. 

    //generates triggers after 32 clock cycles of FCLK, according to polarity and raw discriminator output
    ch_trigger_gen trigger_gen (
        .FCLK (FCLK),
        .INST_START (INST_START),
        .DISCRIMINATOR_OUTPUT (DISCRIMINATOR_OUTPUT),
        .DISCRIMINATOR_POLARITY (DISCRIMINATOR_POLARITY),
        .TRIG_DELAY (TRIG_DELAY),
        .current_state (current_state),

        .trigger (trigger)
    );

    //converts mode into a start instruction pulse to kick off sampling
    ch_mode_decoder mode_decoder (
        .INST_START (INST_START),
        .MODE (MODE),

        .start1 (start1),
        .start2 (start2),
        .start4 (start4)
    );

    //STOP_REQUEST is or'd from each channel to trigger out
    always_ff @(posedge trigger, posedge INST_START) begin
        if (INST_START) begin
            STOP_REQUEST <= 0;
        end
        else begin
            STOP_REQUEST <= 1;
        end
    end

    always_ff @(posedge trigger, negedge RSTB, posedge start1, posedge start2, posedge start4, posedge INST_STOP, posedge INST_READOUT) begin
        if (!RSTB) begin
            current_state <= STATE_INIT;
        end
        else if (start1) begin 
            current_state <= STATE_SAMPLING_A;
            trigger_cnt <= 3'b0;
        end
        else if (start2) begin 
            current_state <= STATE_SAMPLING_A_AND_B; 
            trigger_cnt <= 3'b0;
        end
        else if (start4) begin 
            current_state <= STATE_SAMPLING_ALL;
            trigger_cnt <= 3'b0;
        end
        else if (INST_STOP) begin //stop when the controller sends a trigger in
            current_state <= STATE_STOPPED;
        end
        else if (INST_READOUT) begin //prepare readout when SPI sends readout instruction
            current_state <= STATE_READOUT;
        end
        else begin //trigger rising edge, meaning discriminator fired
            case (current_state)
                STATE_SAMPLING_A: begin //starting with 1 fast buffer per event setting (MODE = 00)
                    // If the discriminator output is present, start sampling the next fast buffer.
                    current_state <= STATE_SAMPLING_B;
                    trigger_cnt <= 3'b001;
                end
                STATE_SAMPLING_B: begin
                    // If the discriminator output is present, start sampling the next fast buffer.
                    current_state <= STATE_SAMPLING_C;
                    trigger_cnt <= 3'b010;
                end
                STATE_SAMPLING_C: begin
                    // If the discriminator output is present, start sampling the next fast buffer.
                    current_state <= STATE_SAMPLING_D;
                    trigger_cnt <= 3'b011;
                end
                STATE_SAMPLING_D: begin
                    // If the discriminator output is present, finish sampling the fast buffers but keep sampling the slow buffer.
                    current_state <= STATE_SAMPLING_E;
                    trigger_cnt <= 3'b100;
                end
                STATE_SAMPLING_A_AND_B: begin //starting with 2 fast buffers per event setting (MODE = 01)
                    // If the discriminator output is present, start sampling the next two fast buffers.
                    current_state <= STATE_SAMPLING_C_AND_D;
                    trigger_cnt <= 3'b001;
                end
                STATE_SAMPLING_C_AND_D: begin
                    // If the discriminator output is present, finish sampling the fast buffers but keep sampling the slow buffer.
                    current_state <= STATE_SAMPLING_E;
                    trigger_cnt <= 3'b010;
                end
                STATE_SAMPLING_ALL: begin //starting with 4 fast buffers per event setting (MODE = 11)
                    // If the discriminator output is present, finish sampling the fast buffers but keep sampling the slow buffer.
                    current_state <= STATE_SAMPLING_E;
                    trigger_cnt <= 3'b001;
                end
                STATE_INIT: begin
                    current_state <= STATE_INIT;
                end
                STATE_READOUT: begin
                    current_state <= STATE_READOUT;
                end
                STATE_STOPPED: begin
                    current_state <= STATE_STOPPED;
                end
                STATE_SAMPLING_E: begin
                    //this state is reached when the fast buffers are done sampling. The state machine will stay in this state until a stop command is given.
                    current_state <= STATE_SAMPLING_E;
                end
                default: begin //defaults to stopped, though this should never be reached
                    current_state <= STATE_STOPPED;
                end
            endcase
        end
    end

    //readout of the timestamps and trigger_cnt on the SPI
    ch_spi_readout spi_readout (
        .INST_READOUT (INST_READOUT),
        .SPI_CLK (SPI_CLK),
        .RSTB (RSTB),
        .SELECT_REG (SELECT_REG),

        .trigger_cnt (trigger_cnt),
        .CE (CE),
        .CD (CD),
        .CC (CC),
        .CB (CB),
        .CA (CA),

        .CNT_SER (CNT_SER)
    );

    always_comb begin
        //Update the control latches based on the current state.
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