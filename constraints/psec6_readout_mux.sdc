# ============================================================================
# SDC Constraints for readout_mux Module
# Target: TSMC 65nm Process
# ============================================================================

set sdc_version 2.0
current_design readout_mux

# ----------------------------------------------------------------------------
# Clock Definition
# ----------------------------------------------------------------------------
create_clock -name spi_clk -period 25.0 -waveform {0 12.5} [get_ports spi_clk]

set_clock_uncertainty -setup 1.25 [get_clocks spi_clk]
set_clock_uncertainty -hold 0.5 [get_clocks spi_clk]

set_clock_transition 0.5 [get_clocks spi_clk]

set_clock_latency -source -max 2.0 [get_clocks spi_clk]
set_clock_latency -source -min 1.0 [get_clocks spi_clk]

# ----------------------------------------------------------------------------
# Input Constraints
# ----------------------------------------------------------------------------
set input_delay_max [expr 25.0 * 0.4]
set input_delay_min [expr 25.0 * 0.1]

set_input_delay -clock spi_clk -max $input_delay_max [get_ports {addr[*]}]
set_input_delay -clock spi_clk -min $input_delay_min [get_ports {addr[*]}]

set_input_delay -clock spi_clk -max $input_delay_max [get_ports {poci_ch[*]}]
set_input_delay -clock spi_clk -min $input_delay_min [get_ports {poci_ch[*]}]

set_input_delay -clock spi_clk -max $input_delay_max [get_ports poci_spi]
set_input_delay -clock spi_clk -min $input_delay_min [get_ports poci_spi]

set_input_delay -clock spi_clk -max $input_delay_max [get_ports cs]
set_input_delay -clock spi_clk -min $input_delay_min [get_ports cs]

set_input_delay -clock spi_clk -max 5.0 [get_ports rstn]
set_input_delay -clock spi_clk -min 0.0 [get_ports rstn]

set_input_transition 1.0 [all_inputs]

# ----------------------------------------------------------------------------
# Output Constraints
# ----------------------------------------------------------------------------
set output_delay_max [expr 25.0 * 0.4]
set output_delay_min [expr 25.0 * 0.1]

set_output_delay -clock spi_clk -max $output_delay_max [get_ports poci]
set_output_delay -clock spi_clk -min $output_delay_min [get_ports poci]

set_load 1.0 [get_ports poci]

# ----------------------------------------------------------------------------
# Reset Path Constraints
# ----------------------------------------------------------------------------
set_false_path -from [get_ports rstn] -through [get_pins -hier *rstn*] -hold

# ----------------------------------------------------------------------------
# Design Rule Constraints
# ----------------------------------------------------------------------------
set_max_transition 2.0 [current_design]
set_max_fanout 16 [current_design]
set_max_capacitance 0.5 [current_design]