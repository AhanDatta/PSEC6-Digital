#==============================================================================
# Floorplan for PSEC6_spi
#==============================================================================

# Setting dimensions in um
set WIDTH 70.0
set HEIGHT 450.0
set MARGIN 5.0

# Define which metal layer pins should live on 
set PIN_LAYER_3 "M3"
set PIN_LAYER_4 "M4"

# Specify exact die size with margins
floorplan -site core -d ${WIDTH} ${HEIGHT} ${MARGIN} ${MARGIN} ${MARGIN} ${MARGIN}

# ============================================================================
# Top and Bottom Edge Pin Alignment
# (Restricted to Left 40µm Corner with 0.2µm pin sizing)
# ============================================================================
# We define 20 discrete slots starting at X=4.0 with a 1.8um pitch.
# This spans from X=4.0 to X=38.2, keeping them in the left 40um block.

set start_x 4.0
set pitch 1.8

# Full 20-pin list for the Top Edge
set top_pins {
    select_reg[0] select_reg[1] select_reg[2] 
    poci_ch[0] poci_ch[1] poci_ch[2] poci_ch[3] 
    spi_clk 
    disc_polarity[0] disc_polarity[1] disc_polarity[2] disc_polarity[3] 
    inst_readout inst_start 
    stop_request[0] stop_request[1] stop_request[2] stop_request[3] 
    mode[0] mode[1]
}

# 20-slot list for the Bottom Edge 
# Empty braces {} represent gaps where shared signals are omitted to maintain vertical alignment
set bottom_pins {
    {} {} {} 
    poci_ch[4] poci_ch[5] poci_ch[6] poci_ch[7] 
    {} 
    disc_polarity[4] disc_polarity[5] disc_polarity[6] disc_polarity[7] 
    {} {} 
    stop_request[4] stop_request[5] stop_request[6] stop_request[7] 
    {} {}
}

# Place Top Pins
for {set i 0} {$i < 20} {incr i} {
    set p [lindex $top_pins $i]
    if {$p != ""} {
        set px [expr {$start_x + $i * $pitch}]
        # Assigns explicit {X Y} coordinate to override auto-spreading
        editPin -pin $p -assign [list $px $HEIGHT] -layer ${PIN_LAYER_4} -pinWidth 0.2 -pinDepth 3 -fixedPin
    }
}

# Place Bottom Pins (Creating gaps for alignment)
for {set i 0} {$i < 20} {incr i} {
    set p [lindex $bottom_pins $i]
    if {$p != ""} {
        set px [expr {$start_x + $i * $pitch}]
        editPin -pin $p -assign [list $px 0.0] -layer ${PIN_LAYER_4} -pinWidth 0.2 -pinDepth 3 -fixedPin
    }
}

# ============================================================================
# Left and Right Edge Pin Placement
# ============================================================================

# LEFT EDGE (General SPI Control & Triggers)
editPin -pin {rstn cs pico trigger_in poci trigger_out inst_rst} \
    -side Left \
    -layer ${PIN_LAYER_3} \
    -spreadType center \
    -spacing 2.0 \
    -fixedPin

# RIGHT EDGE (Clock Controls & Analog Biasing)
editPin -pin {clk_enable test_point_control[*] vco_digital_band[*] ref_clk_tgate_control[*] slow_mode pfd_switch pll_switch lpf_resistor_sel[*]} \
    -side Right \
    -layer ${PIN_LAYER_3} \
    -spreadType center \
    -spacing 1.8 \
    -fixedPin

# ============================================================================
# Utilization Check
# ============================================================================
set core_width [expr ${WIDTH} - 2.0 * ${MARGIN}]
set core_height [expr ${HEIGHT} - 2.0 * ${MARGIN}]
set core_area [expr ${core_width} * ${core_height}]
puts "Die area: [expr ${WIDTH} * ${HEIGHT}] µm²"
puts "Core area: ${core_area} µm² (${core_width} x ${core_height})"

puts "Floorplan complete: ${WIDTH}µm x ${HEIGHT}µm"