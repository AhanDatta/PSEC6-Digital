# ============================================================================
# SDC Constraints for PSEC5_CH_DIGITAL Module
# Target: TSMC 65nm Process
# ============================================================================

set sdc_version 2.0
set design_name "PSEC5_CH_DIGITAL"
set_units -capacitance 1000fF
set_units -time 1000ps

# ----------------------------------------------------------------------------
# Clock Definitions
# ----------------------------------------------------------------------------
# Fast clock - 5 GHz
create_clock -name FCLK -period 0.2 -waveform {0 0.1} [get_ports FCLK]

# SPI clock - 40 MHz
create_clock -name SPI_CLK -period 25.0 -waveform {0 12.5} [get_ports SPI_CLK]

# Clocks are asynchronous to each other
set_clock_groups -asynchronous -group [get_clocks FCLK] -group [get_clocks SPI_CLK]

# Clock uncertainty
set_clock_uncertainty -setup 0.01 [get_clocks FCLK]
set_clock_uncertainty -hold 0.005 [get_clocks FCLK]

set_clock_uncertainty -setup 1.25 [get_clocks SPI_CLK]
set_clock_uncertainty -hold 0.5 [get_clocks SPI_CLK]

# Clock transition
set_clock_transition 0.03 [get_clocks FCLK]
set_clock_transition 1.0 [get_clocks SPI_CLK]

# Clock latency
set_clock_latency -source -max 0.5 [get_clocks FCLK]
set_clock_latency -source -min 0.2 [get_clocks FCLK]

set_clock_latency -source -max 2.0 [get_clocks SPI_CLK]
set_clock_latency -source -min 1.0 [get_clocks SPI_CLK]

# ----------------------------------------------------------------------------
# Input Constraints - FCLK domain
# ----------------------------------------------------------------------------
set fclk_input_delay_max [expr 0.2 * 0.9]
set fclk_input_delay_min [expr 0.2 * 0.5]

set_input_delay -clock FCLK -max $fclk_input_delay_max [get_ports DISCRIMINATOR_OUTPUT]
set_input_delay -clock FCLK -min $fclk_input_delay_min [get_ports DISCRIMINATOR_OUTPUT]

set_input_delay -clock FCLK -max $fclk_input_delay_max [get_ports {CA[*]}]
set_input_delay -clock FCLK -min $fclk_input_delay_min [get_ports {CA[*]}]

set_input_delay -clock FCLK -max $fclk_input_delay_max [get_ports {CB[*]}]
set_input_delay -clock FCLK -min $fclk_input_delay_min [get_ports {CB[*]}]

set_input_delay -clock FCLK -max $fclk_input_delay_max [get_ports {CC[*]}]
set_input_delay -clock FCLK -min $fclk_input_delay_min [get_ports {CC[*]}]

set_input_delay -clock FCLK -max $fclk_input_delay_max [get_ports {CD[*]}]
set_input_delay -clock FCLK -min $fclk_input_delay_min [get_ports {CD[*]}]

set_input_delay -clock FCLK -max $fclk_input_delay_max [get_ports {CE[*]}]
set_input_delay -clock FCLK -min $fclk_input_delay_min [get_ports {CE[*]}]

# ----------------------------------------------------------------------------
# Input Constraints - SPI_CLK domain
# ----------------------------------------------------------------------------
set spi_input_delay_max [expr 25.0 * 0.4]
set spi_input_delay_min [expr 25.0 * 0.1]

set_input_delay -clock SPI_CLK -max $spi_input_delay_max [get_ports {SELECT_REG[*]}]
set_input_delay -clock SPI_CLK -min $spi_input_delay_min [get_ports {SELECT_REG[*]}]

set_input_delay -clock SPI_CLK -max $spi_input_delay_max [get_ports INST_READOUT]
set_input_delay -clock SPI_CLK -min $spi_input_delay_min [get_ports INST_READOUT]

# ----------------------------------------------------------------------------
# Input Constraints - Asynchronous/Control signals
# ----------------------------------------------------------------------------
set_input_delay -clock FCLK -max 0.05 [get_ports INST_START]
set_input_delay -clock FCLK -min 0.0 [get_ports INST_START]

set_input_delay -clock FCLK -max 0.05 [get_ports INST_STOP]
set_input_delay -clock FCLK -min 0.0 [get_ports INST_STOP]

set_input_delay -clock FCLK -max 0.05 [get_ports RSTB]
set_input_delay -clock FCLK -min 0.0 [get_ports RSTB]

set_input_delay -clock FCLK -max 0.05 [get_ports DISCRIMINATOR_POLARITY]
set_input_delay -clock FCLK -min 0.0 [get_ports DISCRIMINATOR_POLARITY]

set_input_delay -clock FCLK -max 0.05 [get_ports {MODE[*]}]
set_input_delay -clock FCLK -min 0.0 [get_ports {MODE[*]}]

set_input_delay -clock FCLK -max 0.05 [get_ports {TRIG_DELAY[*]}]
set_input_delay -clock FCLK -min 0.0 [get_ports {TRIG_DELAY[*]}]

set_input_transition 0.1 [get_ports FCLK]
set_input_transition 0.5 [get_ports SPI_CLK]
set_input_transition 0.2 [remove_from_collection [all_inputs] [get_ports {FCLK SPI_CLK}]]

# ----------------------------------------------------------------------------
# Output Constraints - FCLK domain (trigger outputs)
# ----------------------------------------------------------------------------
set fclk_output_delay_max [expr 0.2 * 0.9]
set fclk_output_delay_min [expr 0.2 * 0.5]

set_output_delay -clock FCLK -max $fclk_output_delay_max [get_ports TRIGGERA]
set_output_delay -clock FCLK -min $fclk_output_delay_min [get_ports TRIGGERA]

set_output_delay -clock FCLK -max $fclk_output_delay_max [get_ports TRIGGERB]
set_output_delay -clock FCLK -min $fclk_output_delay_min [get_ports TRIGGERB]

set_output_delay -clock FCLK -max $fclk_output_delay_max [get_ports TRIGGERC]
set_output_delay -clock FCLK -min $fclk_output_delay_min [get_ports TRIGGERC]

set_output_delay -clock FCLK -max $fclk_output_delay_max [get_ports TRIGGERD]
set_output_delay -clock FCLK -min $fclk_output_delay_min [get_ports TRIGGERD]

set_output_delay -clock FCLK -max $fclk_output_delay_max [get_ports TRIGGERE]
set_output_delay -clock FCLK -min $fclk_output_delay_min [get_ports TRIGGERE]

set_output_delay -clock FCLK -max $fclk_output_delay_max [get_ports TRIGGERAC]
set_output_delay -clock FCLK -min $fclk_output_delay_min [get_ports TRIGGERAC]

set_output_delay -clock FCLK -max $fclk_output_delay_max [get_ports TRIGGERBC]
set_output_delay -clock FCLK -min $fclk_output_delay_min [get_ports TRIGGERBC]

set_output_delay -clock FCLK -max $fclk_output_delay_max [get_ports TRIGGERCC]
set_output_delay -clock FCLK -min $fclk_output_delay_min [get_ports TRIGGERCC]

set_output_delay -clock FCLK -max $fclk_output_delay_max [get_ports TRIGGERDC]
set_output_delay -clock FCLK -min $fclk_output_delay_min [get_ports TRIGGERDC]

set_output_delay -clock FCLK -max $fclk_output_delay_max [get_ports STOP_REQUEST]
set_output_delay -clock FCLK -min $fclk_output_delay_min [get_ports STOP_REQUEST]

# ----------------------------------------------------------------------------
# Output Constraints - SPI_CLK domain
# ----------------------------------------------------------------------------
set spi_output_delay_max [expr 25.0 * 0.4]
set spi_output_delay_min [expr 25.0 * 0.1]

set_output_delay -clock SPI_CLK -max $spi_output_delay_max [get_ports CNT_SER]
set_output_delay -clock SPI_CLK -min $spi_output_delay_min [get_ports CNT_SER]

set_load 0.2 [get_ports TRIGGER*]
set_load 0.5 [get_ports CNT_SER]
set_load 0.2 [get_ports STOP_REQUEST]

# ----------------------------------------------------------------------------
# False Paths
# ----------------------------------------------------------------------------
# Asynchronous reset paths
set_false_path -from [get_ports RSTB] -through [get_pins -hier *RSTB*] -hold

# INST_START and INST_STOP are asynchronous control signals
set_false_path -from [get_ports INST_START]
set_false_path -from [get_ports INST_STOP]

# MODE and configuration inputs are quasi-static
set_false_path -from [get_ports {MODE[*]}]
set_false_path -from [get_ports DISCRIMINATOR_POLARITY]
set_false_path -from [get_ports {TRIG_DELAY[*]}]

# ----------------------------------------------------------------------------
# Synchronizer Constraints
# ----------------------------------------------------------------------------
# Two-stage synchronizer for DISCRIMINATOR_OUTPUT when TRIG_DELAY = 0
# This path goes through async logic and then through trigger_synchronizer
set_max_delay 0.4 -from [get_ports DISCRIMINATOR_OUTPUT] -through [get_pins -hier *sync_stage1*] -to [get_pins -hier *sync_stage2*]

# ----------------------------------------------------------------------------
# Design Rule Constraints
# ----------------------------------------------------------------------------
set_max_transition 0.1 [get_clocks FCLK]
set_max_transition 1.0 [get_clocks SPI_CLK]

set_max_fanout 8 [current_design]
set_max_capacitance 0.3 [current_design]

# ============================================================================
# End of SDC Constraints
# ============================================================================

# ============================================================================
# Old SDC Constraints
# ============================================================================

# set sdc_version 2.0

# set_units -capacitance 1000fF
# set_units -time 1000ps

# # Set the current design
# current_design "PSEC6_CH_DIGITAL"

# create_clock -name "FCLK" -period 0.2 -waveform {0.0 0.1} [get_ports FCLK]
# create_clock -name "SPI_CLK" -period 25.0 -waveform {0.0 12.5} [get_ports SPI_CLK]
# set_clock_transition 0.03 [get_clocks FCLK]
# set_clock_transition 1.0 [get_clocks SPI_CLK]
# set_load -pin_load 1.0 [get_ports STOP_REQUEST]
# set_load -pin_load 0.04 [get_ports TRIGGERA]
# set_load -pin_load 0.04 [get_ports TRIGGERB]
# set_load -pin_load 0.04 [get_ports TRIGGERC]
# set_load -pin_load 0.04 [get_ports TRIGGERD]
# set_load -pin_load 0.15 [get_ports TRIGGERE]
# set_load -pin_load 1.0 [get_ports CNT_SER]
# set_max_delay 0.4 -to [list \
#   [get_ports TRIGGERA]  \
#   [get_ports TRIGGERB]  \
#   [get_ports TRIGGERC]  \
#   [get_ports TRIGGERD]  \
#   [get_ports TRIGGERE]  \
#   [get_ports TRIGGERAC]  \
#   [get_ports TRIGGERBC]  \
#   [get_ports TRIGGERCC]  \
#   [get_ports TRIGGERDC] ]
# set_max_delay 1 -to [get_ports STOP_REQUEST]
# set_clock_groups -name "clock_groups_sclk_to_fclk" -asynchronous -group [get_clocks SPI_CLK] -group [get_clocks FCLK]
# set_clock_gating_check -setup 0.0 
# set_input_delay -clock [get_clocks SPI_CLK] -add_delay -min 23.0 [get_ports {SELECT_REG[0]}]
# set_input_delay -clock [get_clocks SPI_CLK] -add_delay -min 23.0 [get_ports {SELECT_REG[1]}]
# set_input_delay -clock [get_clocks SPI_CLK] -add_delay -min 23.0 [get_ports {SELECT_REG[2]}]
# set_output_delay -clock [get_clocks SPI_CLK] -add_delay -max 2.0 [get_ports CNT_SER]
# set_wire_load_mode "segmented"
