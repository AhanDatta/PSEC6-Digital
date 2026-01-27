import types_pkg::*;

module PSEC6_CH_DIGITAL (
    input logic INST_START, //From SPI
    input logic INST_STOP, //From the trig_in pin
    input logic INST_READOUT, //From SPI
    input logic RSTB, //Full chip reset
    input logic DISCRIMINATOR_OUTPUT, // This is the unsync'ed input from the discriminator, which is in the analog part of the PSEC5.
    input logic SPI_CLK, //moved some of the spi shift registers into this module, for the sake of speed and simplicity. 40 MHz
    input logic [9:0] CA, //These are counter values from analog ch of when the triggers are fired
    input logic [9:0] CB,
    input logic [9:0] CC,
    input logic [9:0] CD,
    input logic [9:0] CE, //Always running during sampling in all modes, and thus used for trigger gating
    input smode_t MODE, //Comes from the SPI, set before sampling start command sent
    input logic DISCRIMINATOR_POLARITY, //Comes from SPI, set before sampling
    input logic [2:0] SELECT_REG, //Comes from SPI during readout

    //Outputs are async, dealt with at analog channel level
    output logic STOP_REQUEST, //Flag for a trigger happening
    output logic TRIGGERA, //Sent to the analog channel to start the fast buffers
    output logic TRIGGERB,
    output logic TRIGGERC,
    output logic TRIGGERD,
    output logic TRIGGERE,
    output logic TRIGGERAC,
    output logic TRIGGERBC,
    output logic TRIGGERCC,
    output logic TRIGGERDC,
    output logic CNT_SER //Output sent to the readout mux
);  
    state_t current_state;
    logic start1;
    logic start2;
    logic start4;
    logic trigger;
    logic [2:0] trigger_cnt; //# of legitimate trigger fires. 

    //generates triggers after 32 clock cycles of FCLK (read from timestamp regs), according to polarity and raw discriminator output
    ch_trigger_gen trigger_gen (
        .CE (CE),
        .INST_START (INST_START),
        .DISCRIMINATOR_OUTPUT (DISCRIMINATOR_OUTPUT),
        .DISCRIMINATOR_POLARITY (DISCRIMINATOR_POLARITY),
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

    ch_state_machine state_machine (
        .trigger (trigger),
        .INST_START (INST_START),
        .start1 (start1),
        .start2 (start2),
        .start4 (start4),
        .INST_STOP (INST_STOP),
        .INST_READOUT (INST_READOUT),
        .RSTB (RSTB),

        .STOP_REQUEST (STOP_REQUEST),
        .current_state (current_state),
        .trigger_cnt (trigger_cnt)
    );

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

    //controls the trigger mask based on the state
    ch_state_decoder trigger_mask_gen (
        .current_state (current_state),

        .TRIGGERA (TRIGGERA),
        .TRIGGERAC (TRIGGERAC),
        .TRIGGERB (TRIGGERB),
        .TRIGGERBC (TRIGGERBC),
        .TRIGGERC (TRIGGERC),
        .TRIGGERCC (TRIGGERCC),
        .TRIGGERD (TRIGGERD),
        .TRIGGERDC (TRIGGERDC),
        .TRIGGERE (TRIGGERE)
    );
    
endmodule