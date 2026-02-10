#==============================================================================
# Floorplan for channel digital
#==============================================================================

# Setting dimensions in um
set WIDTH 25.0
set HEIGHT 140.0
set MARGIN 4.0

# Define which metal layer pins should live on 
set PIN_LAYER_4 "M4"
set PIN_LAYER_3 "M3"

# Specify exact die size with margins
floorplan -site core -d ${WIDTH} ${HEIGHT} ${MARGIN} ${MARGIN} ${MARGIN} ${MARGIN}

# Specify pins and locations
# editPin -pin {} \
#     -side Top \
#     -layer ${PIN_LAYER_4} \
#     -spreadType center \
#     -spacing 2.0 \
#     -fixedPin \

# editPin -pin {} \
#     -side Bottom \
#     -layer ${PIN_LAYER_4} \
#     -spreadType center \
#     -spacing 2.0 \
#     -fixedPin \

editPin -pin {
    DISCRIMINATOR_OUTPUT \ 
    CA[*] \
    CB[*] \
    CC[*] \
    CD[*] \ 
    CE[*] \ 
    STOP_REQUEST \
    CNT_SER
} \
    -side Right \
    -layer ${PIN_LAYER_3} \
    -spreadType center \
    -spacing 2.0 \
    -fixedPin \

editPin -pin {
    INST_START \ 
    INST_STOP \ 
    INST_READOUT \ 
    RSTB \ 
    SPI_CLK \ 
    MODE[*] \
    DISCRIMINATOR_POLARITY \
    SELECT_REG[*] \
    TRIG_DELAY[*] \ 
    TRIGGERA \ 
    TRIGGERB \ 
    TRIGGERC \ 
    TRIGGERD \
    TRIGGERE \ 
    TRIGGERAC \
    TRIGGERBC \ 
    TRIGGERCC \
    TRIGGERDC
} \
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