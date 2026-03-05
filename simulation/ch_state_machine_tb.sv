`timescale 1ns/1ps
import types_pkg::*;

module ch_state_machine_tb ();

    logic trigger;
    logic INST_START;
    logic INST_STOP;
    logic INST_READOUT;
    logic RSTB;
    smode_t MODE;

    logic STOP_REQUEST;
    state_t current_state;
    logic [2:0] trigger_cnt;

    ch_state_machine DUT (
        .trigger (trigger),
        .INST_START (INST_START),
        .INST_STOP (INST_STOP),
        .INST_READOUT (INST_READOUT),
        .RSTB (RSTB),
        .MODE (MODE),

        .STOP_REQUEST (STOP_REQUEST),
        .current_state (current_state),
        .trigger_cnt (trigger_cnt)
    );

    // Clock for simulation timing (not connected to DUT since inputs are async)
    logic clk = 0;
    always #5 clk = ~clk;

    // Task to wait for a specific number of clock cycles
    task wait_cycles(input int cycles);
        repeat(cycles) @(posedge clk);
    endtask

    // Task to apply reset
    task apply_reset();
        $display("[%0t] Applying reset", $time);
        RSTB = 0;
        wait_cycles(5);
        RSTB = 1;
        wait_cycles(2);
        $display("[%0t] Reset released, current_state = %s", $time, current_state.name());
    endtask

    // Task to send a trigger pulse
    task send_trigger();
        $display("[%0t] Sending trigger pulse", $time);
        trigger = 1;
        wait_cycles(1);
        trigger = 0;
        wait_cycles(1);
    endtask

    // Task to send instruction pulses
    task send_inst_start();
        $display("[%0t] Sending INST_START", $time);
        INST_START = 1;
        wait_cycles(1);
        INST_START = 0;
        wait_cycles(1);
    endtask

    task send_inst_stop();
        $display("[%0t] Sending INST_STOP", $time);
        INST_STOP = 1;
        wait_cycles(1);
        INST_STOP = 0;
        wait_cycles(1);
    endtask

    task send_inst_readout();
        $display("[%0t] Sending INST_READOUT", $time);
        INST_READOUT = 1;
        wait_cycles(1);
        INST_READOUT = 0;
        wait_cycles(1);
    endtask

    // Task to check expected state
    task check_state(input state_t expected_state);
        if (current_state !== expected_state) begin
            $error("[%0t] State mismatch! Expected: %s, Got: %s", 
                   $time, expected_state.name(), current_state.name());
        end else begin
            $display("[%0t] State check PASSED: %s", $time, current_state.name());
        end
    endtask

    // Task to test a complete sampling sequence for a given mode
    task test_sampling_sequence(input smode_t test_mode, input string mode_name);
        $display("\n=== Testing %s Mode ===", mode_name);
        
        MODE = test_mode;
        wait_cycles(2);
        
        // Start sampling
        send_inst_start();
        wait_cycles(2);
        
        // Send trigger and observe state transitions
        case (test_mode)
            MODE_SAMPLE1: begin
                send_trigger();
                wait_cycles(5);
                // Should cycle through single buffer states
                $display("[%0t] Current state after trigger: %s", $time, current_state.name());
            end
            
            MODE_SAMPLE2: begin
                send_trigger();
                wait_cycles(5);
                // Should use paired buffer states
                $display("[%0t] Current state after trigger: %s", $time, current_state.name());
            end
            
            MODE_SAMPLE4: begin
                send_trigger();
                wait_cycles(5);
                // Should use all buffer state
                $display("[%0t] Current state after trigger: %s", $time, current_state.name());
            end
        endcase
        
        // Stop sampling
        send_inst_stop();
        wait_cycles(2);
        check_state(STATE_STOPPED);
        
        // Test readout
        send_inst_readout();
        wait_cycles(5);
        check_state(STATE_READOUT);
        
        wait_cycles(5); // Allow readout to complete
    endtask

    // Task to test trigger counting
    task test_trigger_counting();
        $display("\n=== Testing Trigger Counting ===");
        
        MODE = MODE_SAMPLE1;
        apply_reset();
        
        // Start sampling
        send_inst_start();
        wait_cycles(2);
        
        // Send multiple triggers and monitor count
        for (int i = 1; i <= 5; i++) begin
            send_trigger();
            wait_cycles(3);
            $display("[%0t] Trigger %0d sent, trigger_cnt = %0d", $time, i, trigger_cnt);
        end
        
        send_inst_stop();
        wait_cycles(2);
    endtask

    // Main test sequence
    initial begin
        $display("=== Starting State Machine Testbench ===");
        
        // Initialize all inputs
        trigger = 0;
        INST_START = 0;
        INST_STOP = 0;
        INST_READOUT = 0;
        RSTB = 1;
        MODE = MODE_SAMPLE1;
        
        // Test 1: Reset functionality
        $display("\n=== Test 1: Reset Functionality ===");
        apply_reset();
        check_state(STATE_INIT);
        
        // Test 2: Basic state transitions
        $display("\n=== Test 2: Basic State Transitions ===");
        send_inst_start();
        wait_cycles(2);
        // Should transition from INIT to some sampling state
        $display("[%0t] State after INST_START: %s", $time, current_state.name());
        
        send_inst_stop();
        wait_cycles(2);
        check_state(STATE_STOPPED);
        
        send_inst_readout();
        wait_cycles(5);
        check_state(STATE_READOUT);
        
        wait_cycles(5);
        
        // Test 3: All sampling modes
        apply_reset();
        test_sampling_sequence(MODE_SAMPLE1, "SAMPLE1");
        
        apply_reset();
        test_sampling_sequence(MODE_SAMPLE2, "SAMPLE2");
        
        apply_reset();
        test_sampling_sequence(MODE_SAMPLE4, "SAMPLE4");
        
        // Test 4: Trigger counting
        test_trigger_counting();
        
        // Test 5: Stop request functionality
        $display("\n=== Test 5: Stop Request Functionality ===");
        apply_reset();
        MODE = MODE_SAMPLE1;
        send_inst_start();
        wait_cycles(2);
        
        // Monitor STOP_REQUEST signal during operation
        for (int i = 0; i < 10; i++) begin
            wait_cycles(5);
            if (STOP_REQUEST) begin
                $display("[%0t] STOP_REQUEST asserted", $time);
            end
            send_trigger();
        end
        
        // Test 6: Mode changes during operation
        $display("\n=== Test 6: Mode Changes During Operation ===");
        apply_reset();
        MODE = MODE_SAMPLE1;
        send_inst_start();
        wait_cycles(5);
        
        $display("[%0t] Changing mode from SAMPLE1 to SAMPLE2", $time);
        MODE = MODE_SAMPLE2;
        wait_cycles(5);
        send_trigger();
        wait_cycles(5);
        
        $display("[%0t] Changing mode from SAMPLE2 to SAMPLE4", $time);
        MODE = MODE_SAMPLE4;
        wait_cycles(5);
        send_trigger();
        wait_cycles(5);
        
        send_inst_stop();
        wait_cycles(2);
        
        // Test 7: Rapid instruction sequences
        $display("\n=== Test 7: Rapid Instruction Sequences ===");
        apply_reset();
        MODE = MODE_SAMPLE2;
        
        // Rapid start/stop
        send_inst_start();
        wait_cycles(1);
        send_inst_stop();
        wait_cycles(1);
        send_inst_start();
        wait_cycles(2);
        send_trigger();
        wait_cycles(3);
        send_inst_readout();
        wait_cycles(5);
        
        // Final state check
        $display("\n=== Final State Check ===");
        $display("[%0t] Final state: %s, trigger_cnt: %0d", 
                 $time, current_state.name(), trigger_cnt);
        
        // Test completion
        wait_cycles(10);
        $display("\n=== Testbench Completed ===");
        $finish;
    end

    // Monitor for state changes
    always @(current_state) begin
        $display("[%0t] State changed to: %s", $time, current_state.name());
    end

    // Monitor for trigger count changes
    always @(trigger_cnt) begin
        $display("[%0t] Trigger count changed to: %0d", $time, trigger_cnt);
    end

    // Monitor for STOP_REQUEST changes
    always @(STOP_REQUEST) begin
        if (STOP_REQUEST)
            $display("[%0t] STOP_REQUEST asserted", $time);
        else
            $display("[%0t] STOP_REQUEST deasserted", $time);
    end

endmodule