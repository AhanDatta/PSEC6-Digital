#==============================================================================
# Floorplan for readout_mux
#==============================================================================

# Setting dimensions in um
set WIDTH 30.0
set HEIGHT 24.0
set MARGIN 5.0

# Define which metal layer pins should live on 
set PIN_LAYER_4 "M4"
set PIN_LAYER_3 "M3"

# Specify exact die size with margins
floorplan -site core -d ${WIDTH} ${HEIGHT} ${MARGIN} ${MARGIN} ${MARGIN} ${MARGIN}

# Specify pins and locations
editPin -pin {addr[*] poci_spi} \
    -side Top \
    -layer ${PIN_LAYER_4} \
    -spreadType center \
    -spacing 2.0 \
    -fixedPin \

editPin -pin {spi_clk cs rstn} \
    -side Bottom \
    -layer ${PIN_LAYER_4} \
    -spreadType center \
    -spacing 2.0 \
    -fixedPin \

editPin -pin {poci_ch[*]} \
    -side Right \
    -layer ${PIN_LAYER_3} \
    -spreadType center \
    -spacing 2.0 \
    -fixedPin \

editPin -pin {poci} \
    -side Left \
    -layer ${PIN_LAYER_3} \
    -spreadType center \
    -spacing 2.0 \
    -fixedPin \

# Check utilization
set core_width [expr ${WIDTH} - 2.0 * ${MARGIN}]
set core_height [expr ${HEIGHT} - 2.0 * ${MARGIN}]
set core_area [expr ${core_width} * ${core_height}]
puts "Die area: [expr ${WIDTH} * ${HEIGHT}] µm²"
puts "Core area: ${core_area} µm² (${core_width} x ${core_height})"

puts "Floorplan complete: ${WIDTH}µm x ${HEIGHT}µm"