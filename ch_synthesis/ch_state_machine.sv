import types_pkg::*;

module ch_state_machine_gated_clock (
    input logic FCLK,             // Gated system clock (stops when INST_STOP asserts)
    input logic trigger,          // Async event signal
    input logic INST_START,       // Restarts the gated clock
    input logic INST_STOP,        // Gates off FCLK - must be async reset
    input logic INST_READOUT,     // Must work when clock is gated - async reset  
    input logic RSTB,            // Main reset
    input logic start1,
    input logic start2, 
    input logic start4,
    
    output logic STOP_REQUEST,
    output state_t current_state,
    output logic [2:0] trigger_cnt
);

    // Synchronize inputs that can be synchronous (when clock is running)
    logic trigger_r1, trigger_r2, trigger_pulse;
    logic start1_r1, start1_r2, start1_pulse;
    logic start2_r1, start2_r2, start2_pulse;
    logic start4_r1, start4_r2, start4_pulse;
    logic inst_start_r1, inst_start_r2, inst_start_pulse;
    
    // Two-flop synchronizers for inputs that don't gate the clock
    always_ff @(posedge FCLK or negedge RSTB) begin
        if (!RSTB) begin
            {trigger_r1, trigger_r2} <= '0;
            {start1_r1, start1_r2} <= '0;
            {start2_r1, start2_r2} <= '0;
            {start4_r1, start4_r2} <= '0;
            {inst_start_r1, inst_start_r2} <= '0;
        end else begin
            trigger_r1 <= trigger;
            trigger_r2 <= trigger_r1;
            start1_r1 <= start1;
            start1_r2 <= start1_r1;
            start2_r1 <= start2;
            start2_r2 <= start2_r1;
            start4_r1 <= start4;
            start4_r2 <= start4_r1;
            inst_start_r1 <= INST_START;
            inst_start_r2 <= inst_start_r1;
        end
    end
    
    // Edge detection for synchronized signals
    assign trigger_pulse = trigger_r1 & ~trigger_r2;
    assign start1_pulse = start1_r1 & ~start1_r2;
    assign start2_pulse = start2_r1 & ~start2_r2;
    assign start4_pulse = start4_r1 & ~start4_r2;
    assign inst_start_pulse = inst_start_r1 & ~inst_start_r2;

    // STOP_REQUEST: Must handle INST_START async since it controls clock gating
    always_ff @(posedge FCLK, posedge INST_START, negedge RSTB) begin
        if (!RSTB) begin
            STOP_REQUEST <= 0;
        end else if (INST_START) begin
            STOP_REQUEST <= 0;
        end else if (trigger_pulse) begin
            STOP_REQUEST <= 1;
        end
    end

    // Main state machine: INST_STOP and INST_READOUT must be async
    // because they occur when FCLK is gated off
    always_ff @(posedge FCLK, posedge INST_STOP, posedge INST_READOUT, negedge RSTB) begin
        if (!RSTB) begin
            current_state <= STATE_INIT;
            trigger_cnt <= 3'b0;
        end else if (INST_STOP) begin
            // INST_STOP must be async since it gates the clock off
            current_state <= STATE_STOPPED;
        end else if (INST_READOUT) begin  
            // INST_READOUT must be async since it can occur when clock is gated
            current_state <= STATE_READOUT;
        end else begin // posedge FCLK
            // Synchronous operations when clock is running
            if (start1_pulse) begin 
                current_state <= STATE_SAMPLING_A;
                trigger_cnt <= 3'b0;
            end else if (start2_pulse) begin 
                current_state <= STATE_SAMPLING_A_AND_B; 
                trigger_cnt <= 3'b0;
            end else if (start4_pulse) begin 
                current_state <= STATE_SAMPLING_ALL;
                trigger_cnt <= 3'b0;
            end else if (trigger_pulse) begin 
                case (current_state)
                    STATE_SAMPLING_A: begin
                        current_state <= STATE_SAMPLING_B;
                        trigger_cnt <= 3'b001;
                    end
                    STATE_SAMPLING_B: begin
                        current_state <= STATE_SAMPLING_C;
                        trigger_cnt <= 3'b010;
                    end
                    STATE_SAMPLING_C: begin
                        current_state <= STATE_SAMPLING_D;
                        trigger_cnt <= 3'b011;
                    end
                    STATE_SAMPLING_D: begin
                        current_state <= STATE_SAMPLING_E;
                        trigger_cnt <= 3'b100;
                    end
                    STATE_SAMPLING_A_AND_B: begin
                        current_state <= STATE_SAMPLING_C_AND_D;
                        trigger_cnt <= 3'b001;
                    end
                    STATE_SAMPLING_C_AND_D: begin
                        current_state <= STATE_SAMPLING_E;
                        trigger_cnt <= 3'b010;
                    end
                    STATE_SAMPLING_ALL: begin
                        current_state <= STATE_SAMPLING_E;
                        trigger_cnt <= 3'b001;
                    end
                    default: begin
                        // Stay in current state for INIT, READOUT, STOPPED, SAMPLING_E
                    end
                endcase
            end
        end
    end
endmodule