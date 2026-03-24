# ============================================================================
# SDC Constraints for PSEC6_spi Module
# Target: TSMC 65nm Process
# ============================================================================

set sdc_version 2.0
current_design PSEC6_spi

# ----------------------------------------------------------------------------
# Clock Definition
# ----------------------------------------------------------------------------
create_clock -name spi_clk -period 25.0 -waveform {0 12.5} [get_ports spi_clk]

set_clock_uncertainty -setup 1.25 [get_clocks spi_clk]
set_clock_uncertainty -hold 0.5 [get_clocks spi_clk]

set_clock_transition 1.0 [get_clocks spi_clk]

set_clock_latency -source -max 2.0 [get_clocks spi_clk]
set_clock_latency -source -min 1.0 [get_clocks spi_clk]

# ----------------------------------------------------------------------------
# Input Constraints
# ----------------------------------------------------------------------------
set input_delay_max [expr 25.0 * 0.4]
set input_delay_min [expr 25.0 * 0.1]

# Standard Inputs
set_input_delay -clock spi_clk -max $input_delay_max [get_ports pico]
set_input_delay -clock spi_clk -min $input_delay_min [get_ports pico]

set_input_delay -clock spi_clk -max $input_delay_max [get_ports cs]
set_input_delay -clock spi_clk -min $input_delay_min [get_ports cs]

set_input_delay -clock spi_clk -max $input_delay_max [get_ports trigger_in]
set_input_delay -clock spi_clk -min $input_delay_min [get_ports trigger_in]

set_input_delay -clock spi_clk -max $input_delay_max [get_ports {poci_ch[*]}]
set_input_delay -clock spi_clk -min $input_delay_min [get_ports {poci_ch[*]}]

set_input_delay -clock spi_clk -max $input_delay_max [get_ports {stop_request[*]}]
set_input_delay -clock spi_clk -min $input_delay_min [get_ports {stop_request[*]}]

# Reset Input
set_input_delay -clock spi_clk -max 5.0 [get_ports rstn]
set_input_delay -clock spi_clk -min 0.0 [get_ports rstn]

set_input_transition 1.0 [all_inputs]

# ----------------------------------------------------------------------------
# Output Constraints
# ----------------------------------------------------------------------------
set output_delay_max [expr 25.0 * 0.4]
set output_delay_min [expr 25.0 * 0.1]

# Default output delays
set_output_delay -clock spi_clk -max $output_delay_max [all_outputs]
set_output_delay -clock spi_clk -min $output_delay_min [all_outputs]

# ----------------------------------------------------------------------------
# Output Load Constraints (Parasitic Capacitance)
# ----------------------------------------------------------------------------
# Default load for short, local routing
set_load 1.5 [all_outputs]

# Override load for signals driving long traces out to the channels (~3.0 pF)
set channel_outputs [get_ports { \
    mode[*] \
    disc_polarity[*] \
    select_reg[*] \
    inst_rst \
    inst_readout \
    inst_start \
}]
set_load 3.0 $channel_outputs

# ----------------------------------------------------------------------------
# Reset Path Constraints
# ----------------------------------------------------------------------------
# False path for the asynchronous active-low reset
set_false_path -from [get_ports rstn] -through [get_pins -hier *rstn*] -hold

# ----------------------------------------------------------------------------
# Design Rule Constraints
# ----------------------------------------------------------------------------
set_max_transition 2.0 [current_design]
set_max_fanout 16 [current_design]

# Max capacitance increased to >3.0pF to prevent DRC violations on the 
# high-load channel traces.
set_max_capacitance 4.0 [current_design]