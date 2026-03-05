# ============================================================================
# SDC Constraints for PSEC6_CH_DIGITAL Module
# Target: TSMC 65nm Process
# ============================================================================

set sdc_version 2.0
current_design PSEC6_CH_DIGITAL

# ----------------------------------------------------------------------------
# Clock Definitions
# ----------------------------------------------------------------------------
# SPI clock - 40 MHz (only clock in the design now)
create_clock -name SPI_CLK -period 25.0 -waveform {0 12.5} [get_ports SPI_CLK]

# Clock uncertainty
set_clock_uncertainty -setup 1.25 [get_clocks SPI_CLK]
set_clock_uncertainty -hold 0.5 [get_clocks SPI_CLK]

# Clock transition
set_clock_transition 2.5 [get_clocks SPI_CLK]

# Clock latency
set_clock_latency -source -max 2.0 [get_clocks SPI_CLK]
set_clock_latency -source -min 1.0 [get_clocks SPI_CLK]

# ----------------------------------------------------------------------------
# Input Constraints - SPI_CLK domain
# ----------------------------------------------------------------------------
set spi_input_delay_max [expr 25.0 * 0.4]
set spi_input_delay_min [expr 25.0 * 0.1]

set_input_delay -clock SPI_CLK -max $spi_input_delay_max [get_ports {SELECT_REG[*]}]
set_input_delay -clock SPI_CLK -min $spi_input_delay_min [get_ports {SELECT_REG[*]}]

set_input_delay -clock SPI_CLK -max $spi_input_delay_max [get_ports INST_READOUT]
set_input_delay -clock SPI_CLK -min $spi_input_delay_min [get_ports INST_READOUT]

set_input_delay -clock SPI_CLK -max $spi_input_delay_max [get_ports {CA[*]}]
set_input_delay -clock SPI_CLK -min $spi_input_delay_min [get_ports {CA[*]}]

set_input_delay -clock SPI_CLK -max $spi_input_delay_max [get_ports {CB[*]}]
set_input_delay -clock SPI_CLK -min $spi_input_delay_min [get_ports {CB[*]}]

set_input_delay -clock SPI_CLK -max $spi_input_delay_max [get_ports {CC[*]}]
set_input_delay -clock SPI_CLK -min $spi_input_delay_min [get_ports {CC[*]}]

set_input_delay -clock SPI_CLK -max $spi_input_delay_max [get_ports {CD[*]}]
set_input_delay -clock SPI_CLK -min $spi_input_delay_min [get_ports {CD[*]}]

set_input_delay -clock SPI_CLK -max $spi_input_delay_max [get_ports {CE[*]}]
set_input_delay -clock SPI_CLK -min $spi_input_delay_min [get_ports {CE[*]}]

# ----------------------------------------------------------------------------
# Input Constraints - Asynchronous signals (no clock reference)
# ----------------------------------------------------------------------------
# These signals are asynchronous and don't have timing relationship to SPI_CLK
set_input_transition 0.5 [get_ports DISCRIMINATOR_OUTPUT]
set_input_transition 0.5 [get_ports INST_START]
set_input_transition 0.5 [get_ports INST_STOP]
set_input_transition 0.5 [get_ports RSTB]
set_input_transition 0.5 [get_ports DISCRIMINATOR_POLARITY]
set_input_transition 0.5 [get_ports {MODE[*]}]

set_input_transition 2.5 [get_ports SPI_CLK]

# ----------------------------------------------------------------------------
# Output Constraints - SPI_CLK domain
# ----------------------------------------------------------------------------
set spi_output_delay_max [expr 25.0 * 0.4]
set spi_output_delay_min [expr 25.0 * 0.1]

set_output_delay -clock SPI_CLK -max $spi_output_delay_max [get_ports CNT_SER]
set_output_delay -clock SPI_CLK -min $spi_output_delay_min [get_ports CNT_SER]

# ----------------------------------------------------------------------------
# Output Constraints - Asynchronous outputs (combinational from async inputs)
# ----------------------------------------------------------------------------
# TRIGGER outputs are combinational from DISCRIMINATOR_OUTPUT and state machine
# Set max delay constraints for these async paths
set_max_delay 1.0 -from [get_ports DISCRIMINATOR_OUTPUT] -to [get_ports TRIGGER*]
set_max_delay 1.0 -from [get_ports INST_START] -to [get_ports TRIGGER*]
set_max_delay 1.0 -from [get_ports INST_STOP] -to [get_ports TRIGGER*]

set_max_delay 1.0 -from [get_ports DISCRIMINATOR_OUTPUT] -to [get_ports STOP_REQUEST]
set_max_delay 1.0 -from [get_ports INST_START] -to [get_ports STOP_REQUEST]
set_max_delay 1.0 -from [get_ports INST_STOP] -to [get_ports STOP_REQUEST]

# Output loads
set_load 0.5 [get_ports TRIGGER*]
set_load 0.5 [get_ports CNT_SER]
set_load 1.0 [get_ports STOP_REQUEST]

# ----------------------------------------------------------------------------
# False Paths
# ----------------------------------------------------------------------------
# Asynchronous reset paths
set_false_path -from [get_ports RSTB]

# Asynchronous control signals
set_false_path -from [get_ports INST_START]
set_false_path -from [get_ports INST_STOP]

# Quasi-static configuration inputs
set_false_path -from [get_ports {MODE[*]}]
set_false_path -from [get_ports DISCRIMINATOR_POLARITY]

# Discriminator output is asynchronous
set_false_path -from [get_ports DISCRIMINATOR_OUTPUT]

# ----------------------------------------------------------------------------
# Design Rule Constraints
# ----------------------------------------------------------------------------
set_max_transition 2.0 [get_clocks SPI_CLK]
set_max_transition 1.0 [current_design]

set_max_fanout 16 [current_design]
set_max_capacitance 0.5 [current_design]

# ============================================================================
# End of SDC Constraints
# ============================================================================