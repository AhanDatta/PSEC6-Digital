# ============================================================================
# SDC Constraints for PSEC6_CH_DIGITAL Module
# Target: TSMC 65nm Process
# ============================================================================

set sdc_version 2.0
current_design PSEC6_CH_DIGITAL

# ----------------------------------------------------------------------------
# 1. Clock Definitions
# ----------------------------------------------------------------------------
# SPI clock - 40 MHz (25.0ns period)
create_clock -name SPI_CLK -period 25.0 -waveform {0 12.5} [get_ports SPI_CLK]

# INST_READOUT clock - Command pulse acting as a clock for capture register
create_clock -name INST_READOUT_CLK -period 25.0 -waveform {0 12.5} [get_ports INST_READOUT]

# Fast analog trigger clock - Using 1.0ns (1 GHz) to heavily constrain the analog paths
create_clock -name TRIGGER_CLK -period 1.0 -waveform {0 0.5} [get_ports DISCRIMINATOR_OUTPUT]

# Define Clock Domains as Asynchronous to prevent impossible cross-domain timing checks
set_clock_groups -asynchronous \
    -group [get_clocks SPI_CLK] \
    -group [get_clocks INST_READOUT_CLK] \
    -group [get_clocks TRIGGER_CLK]

# Clock uncertainty (Setup/Hold margins)
set_clock_uncertainty -setup 1.25 [get_clocks SPI_CLK]
set_clock_uncertainty -hold 0.5 [get_clocks SPI_CLK]
set_clock_uncertainty -setup 0.2 [get_clocks TRIGGER_CLK]
set_clock_uncertainty -hold 0.1 [get_clocks TRIGGER_CLK]

# Clock transition
set_clock_transition 0.5 [get_clocks SPI_CLK]
set_clock_transition 0.1 [get_clocks TRIGGER_CLK]

# Clock latency
set_clock_latency -source -max 2.0 [get_clocks SPI_CLK]
set_clock_latency -source -min 1.0 [get_clocks SPI_CLK]

# ----------------------------------------------------------------------------
# 2. Input Constraints (Delays & Slew)
# ----------------------------------------------------------------------------
# Assume a generic input transition (slew rate) for all inputs to size first-stage cells
set_input_transition 0.5 [all_inputs]
set_input_transition 0.1 [get_ports DISCRIMINATOR_OUTPUT] ;# Fast analog edge

# SPI_CLK Domain Inputs (SELECT_REG)
set_input_delay -clock SPI_CLK -max 10.0 [get_ports {SELECT_REG[*]}]
set_input_delay -clock SPI_CLK -min 2.5 [get_ports {SELECT_REG[*]}]

# INST_READOUT Domain Inputs (CA, CB, CC, CD, CE)
set_input_delay -clock INST_READOUT_CLK -max 10.0 [get_ports {CA[*] CB[*] CC[*] CD[*] CE[*]}]
set_input_delay -clock INST_READOUT_CLK -min 1.0 [get_ports {CA[*] CB[*] CC[*] CD[*] CE[*]}]

# ----------------------------------------------------------------------------
# 3. Output Constraints (Delays)
# ----------------------------------------------------------------------------
# SPI Output (CNT_SER) - Assuming it drives another chip or a pad
set_output_delay -clock SPI_CLK -max 12.0 [get_ports CNT_SER]
set_output_delay -clock SPI_CLK -min -1.0 [get_ports CNT_SER]

# TRIGGER Outputs - Very tight constraints relative to the fast trigger clock
# They drive internal analog SCAs, so they must arrive extremely fast
set_output_delay -clock TRIGGER_CLK -max 0.4 [get_ports TRIGGER*]
set_output_delay -clock TRIGGER_CLK -min -0.1 [get_ports TRIGGER*]

# STOP_REQUEST Output
set_output_delay -clock TRIGGER_CLK -max 0.5 [get_ports STOP_REQUEST]
set_output_delay -clock TRIGGER_CLK -min 0.0 [get_ports STOP_REQUEST]

# ----------------------------------------------------------------------------
# 4. Output Loads
# ----------------------------------------------------------------------------
# CNT_SER typically goes to an IO pad or heavy bus (e.g., 5.0 pF)
set_load 5.0 [get_ports CNT_SER]

# TRIGGER signals go to internal analog standard cells. 
# Keep this very small (e.g., 0.05 pF = 50 fF) so the synth uses fast buffers
set_load 0.05 [get_ports TRIGGER*]

# STOP_REQUEST goes to trigger logic block
set_load 3.0 [get_ports STOP_REQUEST]

# ----------------------------------------------------------------------------
# 5. Design Rule Constraints (DRC)
# ----------------------------------------------------------------------------
# Prevent the tool from building infinitely long nets or overloaded drivers
set_max_transition 1.5 [current_design]
set_max_fanout 30 [current_design]
set_max_capacitance 1.0 [current_design]

# Override the transition for the fast analog-triggered domain
set_max_transition 0.2 [get_clocks TRIGGER_CLK]

# ----------------------------------------------------------------------------
# 6. Max Delay / Exceptions / False Paths
# ----------------------------------------------------------------------------
# Constraining the async STOP_REQUEST generation from command signals
set_max_delay 1.5 -from [get_ports INST_START] -to [get_ports STOP_REQUEST]
set_max_delay 1.5 -from [get_ports INST_STOP] -to [get_ports STOP_REQUEST]

# Asynchronous reset paths
set_false_path -from [get_ports RSTB]

# Asynchronous control signals
set_false_path -from [get_ports INST_START]
set_false_path -from [get_ports INST_STOP]

# Quasi-static configuration inputs (Safe to ignore for timing)
set_false_path -from [get_ports {MODE[*]}]
set_false_path -from [get_ports DISCRIMINATOR_POLARITY]