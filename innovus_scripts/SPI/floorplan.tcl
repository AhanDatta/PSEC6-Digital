#==============================================================================
# Floorplan for spi
#==============================================================================

# Setting dimensions in um
set WIDTH 60.0
set HEIGHT 64.0
set MARGIN 5.0

# Define which metal layer pins should live on 
set PIN_LAYER_3 "M3"
set PIN_LAYER_4 "M4"

# Specify exact die size with margins
floorplan -site core -d ${WIDTH} ${HEIGHT} ${MARGIN} ${MARGIN} ${MARGIN} ${MARGIN}

# Specify pins and locations
editPin -pin {spi_clk rstn cs pico trigger_in} \
    -side Top \
    -layer ${PIN_LAYER_4} \
    -spreadType center \
    -spacing 2.0 \
    -fixedPin \

editPin -pin {addr[*] poci_spi} \
    -side Bottom \
    -layer ${PIN_LAYER_4} \
    -spreadType center \
    -spacing 2.0 \
    -fixedPin \

editPin -pin {clk_enable test_point_control[*] vco_digital_band[*] ref_clk_sel[*] slow_mode pfd_switch pll_switch lpf_resistor_sel[*]} \
    -side Right \
    -layer ${PIN_LAYER_3} \
    -spreadType center \
    -spacing 1.8 \
    -fixedPin \

editPin -pin {trigger_channel_mask[*] mode[*] disc_polarity[*] select_reg[*] inst_rst inst_readout inst_start} \
    -side Left \
    -layer ${PIN_LAYER_3} \
    -spreadType center \
    -spacing 2.0 \
    -fixedPin \

# Create power pins on the power rings with larger dimensions
editPin -pin {DVDD} \
    -side Top \
    -layer M2 \
    -spreadType center \
    -pinWidth 5.0 \
    -pinDepth 5.0 \
    -fixedPin \

editPin -pin {DVSS} \
    -side Bottom \
    -layer M2 \
    -spreadType center \
    -pinWidth 5.0 \
    -pinDepth 5.0 \
    -fixedPin \

# Check utilization
set core_width [expr ${WIDTH} - 2.0 * ${MARGIN}]
set core_height [expr ${HEIGHT} - 2.0 * ${MARGIN}]
set core_area [expr ${core_width} * ${core_height}]
puts "Die area: [expr ${WIDTH} * ${HEIGHT}] µm²"
puts "Core area: ${core_area} µm² (${core_width} x ${core_height})"

puts "Floorplan complete: ${WIDTH}µm x ${HEIGHT}µm"