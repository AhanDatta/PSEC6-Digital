#==============================================================================
# Floorplan for channel digital
#==============================================================================

# Setting dimensions in um
set WIDTH 19.0
set HEIGHT 200.0
set SIDE_MARGIN 3.0
set TOP_MARGIN 30.0
set BOTTOM_MARGIN 3.0

# Define which metal layer pins should live on 
set PIN_LAYER_4 "M4"
set PIN_LAYER_3 "M3"

# Specify exact die size with margins
floorplan -site core -d ${WIDTH} ${HEIGHT} ${SIDE_MARGIN} ${BOTTOM_MARGIN} ${SIDE_MARGIN} ${TOP_MARGIN}

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

# Attempt 1: Pins are too spread
# editPin -pin {
#     # Group D
#     TRIGGERDC
#     CD[0] CD[1] CD[2] CD[3] CD[4] CD[5] CD[6] CD[7] CD[8] CD[9]
#     DISCRIMINATOR_OUTPUT 
    
#     # Group C
#     TRIGGERCC 
#     CC[0] CC[1] CC[2] CC[3] CC[4] CC[5] CC[6] CC[7] CC[8] CC[9]
    
#     # Group B
#     TRIGGERBC 
#     CB[0] CB[1] CB[2] CB[3] CB[4] CB[5] CB[6] CB[7] CB[8] CB[9]
    
#     # Group A
#     TRIGGERAC 
#     CA[0] CA[1] CA[2] CA[3] CA[4] CA[5] CA[6] CA[7] CA[8] CA[9] 
    
#     # Group E
#     CE[0] CE[1] CE[2] CE[3] CE[4] CE[5] CE[6] CE[7] CE[8] CE[9] 
# } \
#     -side Right \
#     -layer ${PIN_LAYER_3} \
#     -spreadType center \
#     -spacing 3.0 \
#     -fixedPin

editPin -pin {
    # We reverse the list so the "bottom" pins are listed first.
    # This ensures CE[9] is at the absolute bottom (Y=min).
    
    # Group E (Now at the bottom)
    CE[9] CE[8] CE[7] CE[6] CE[5] CE[4] CE[3] CE[2] CE[1] CE[0] 
    
    # Group A
    CA[9] CA[8] CA[7] CA[6] CA[5] CA[4] CA[3] CA[2] CA[1] CA[0]
    TRIGGERAC
    
    # Group B
    CB[9] CB[8] CB[7] CB[6] CB[5] CB[4] TRIGGERE CB[3] CB[2] CB[1] CB[0]
    TRIGGERBC
    
    # Group C
    CC[9] CC[8] DISCRIMINATOR_OUTPUT CC[7] CC[6] CC[5] CC[4] CC[3] CC[2] CC[1] CC[0]
    TRIGGERCC
    
    # Group D (Now at the top)
    CD[9] CD[8] CD[7] CD[6] CD[5] CD[4] CD[3] CD[2] CD[1] CD[0]
    TRIGGERDC
} \
    -side Right \
    -layer ${PIN_LAYER_3} \
    -spreadType start \
    -start {19 0} \
    -spreadDirection counterclockwise \
    -spacing 3.4 \
    -fixedPin

editPin -pin {
    TRIGGERD  
    TRIGGERC 
    TRIGGERB 
    TRIGGERA 
} \
    -side Right \
    -layer M5 \
    -spreadType center \
    -spacing 40 \
    -fixedPin \

editPin -pin {
    STOP_REQUEST \
    INST_START \ 
    INST_STOP \ 
    INST_READOUT \ 
    RSTB \ 
    SPI_CLK \ 
    MODE[*] \
    DISCRIMINATOR_POLARITY \
    SELECT_REG[*] \
    CNT_SER \
} \
    -side Bottom \
    -layer ${PIN_LAYER_4} \
    -spreadType center \
    -spacing 1.0 \
    -fixedPin \

# Check utilization
# set core_width [expr ${WIDTH} - 2.0 * ${MARGIN}]
# set core_height [expr ${HEIGHT} - 2.0 * ${MARGIN}]
# set core_area [expr ${core_width} * ${core_height}]
# puts "Die area: [expr ${WIDTH} * ${HEIGHT}] µm²"
# puts "Core area: ${core_area} µm² (${core_width} x ${core_height})"

# puts "Floorplan complete: ${WIDTH}µm x ${HEIGHT}µm"