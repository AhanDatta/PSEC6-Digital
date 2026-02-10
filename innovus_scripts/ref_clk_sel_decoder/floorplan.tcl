#==============================================================================
# Floorplan for ref_clk_sel_decoder
#==============================================================================

# Setting dimensions in um
set WIDTH 20.0
set HEIGHT 15.0
set MARGIN 4.0

# Define which metal layer pins should live on 
set PIN_LAYER "M4"

# Specify exact die size with margins
floorplan -site core -d ${WIDTH} ${HEIGHT} ${MARGIN} ${MARGIN} ${MARGIN} ${MARGIN}

# Specify pins and locations
editPin -pin {rstn ref_clk_sel[*]} -side Bottom -layer ${PIN_LAYER} -spreadType center -spacing 2.0 -fixedPin
editPin -pin {tgate_control[*]} -side Top -layer ${PIN_LAYER} -spreadType center -spacing 2.0 -fixedPin

# Check utilization
set core_width [expr ${WIDTH} - 2.0 * ${MARGIN}]
set core_height [expr ${HEIGHT} - 2.0 * ${MARGIN}]
set core_area [expr ${core_width} * ${core_height}]
puts "Die area: [expr ${WIDTH} * ${HEIGHT}] µm²"
puts "Core area: ${core_area} µm² (${core_width} x ${core_height})"

puts "Floorplan complete: ${WIDTH}µm x ${HEIGHT}µm"
