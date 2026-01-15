# ============================================================================
# SDC Constraints for ref_clk_sel_decoder Module
# Target: TSMC 65nm Process
# ============================================================================

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

current_design "ref_clk_sel_decoder"

# ----------------------------------------------------------------------------
# Input Constraints
# ----------------------------------------------------------------------------
# ref_clk_sel is a quasi-static configuration signal from SPI
# Set conservative timing but mark as false path since it's stable during operation
set_input_transition 1.0 [get_ports {ref_clk_sel[*]}]
set_input_transition 1.0 [get_ports rstn]

# These are configuration inputs that change infrequently
set_false_path -from [get_ports {ref_clk_sel[*]}]
set_false_path -from [get_ports rstn]

# ----------------------------------------------------------------------------
# Output Load Constraints
# ----------------------------------------------------------------------------
# Transmission gates typically have small capacitive load
set_load -pin_load 0.05 [get_ports {tgate_control[0]}]
set_load -pin_load 0.05 [get_ports {tgate_control[1]}]
set_load -pin_load 0.05 [get_ports {tgate_control[2]}]
set_load -pin_load 0.05 [get_ports {tgate_control[3]}]
set_load -pin_load 0.05 [get_ports {tgate_control[4]}]

# ----------------------------------------------------------------------------
# Combinational Timing Constraints
# ----------------------------------------------------------------------------
# Maximum delay from input to output for the decoder logic
# This ensures glitch-free operation when switching
set_max_delay 2.0 -from [get_ports {ref_clk_sel[*]}] -to [get_ports {tgate_control[*]}]
set_max_delay 1.0 -from [get_ports rstn] -to [get_ports {tgate_control[*]}]

# ----------------------------------------------------------------------------
# Design Rule Constraints
# ----------------------------------------------------------------------------
set_max_transition 1.0 [current_design]
set_max_fanout 16 [current_design]
set_max_capacitance 0.5 [current_design]

# ----------------------------------------------------------------------------
# Wire Load Mode
# ----------------------------------------------------------------------------
set_wire_load_mode "segmented"

# ============================================================================
# End of SDC Constraints
# ============================================================================