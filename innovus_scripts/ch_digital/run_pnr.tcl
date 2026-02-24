#==============================================================================
# Innovus Place & Route Script
#==============================================================================

# Has to be name of top module in design
set DESIGN_NAME "PSEC6_CH_DIGITAL"
set TECH_DIR "/opt/TSMC_65nm_MS_RF_LP/TSMCHOME/digital"

#------------------------------------------------------------------------------
# Set Design Variables (BEFORE init_design)
#------------------------------------------------------------------------------
# LEF files
set init_lef_file [list \
    ${TECH_DIR}/Back_End/lef/tcbn65lplvt_200a/lef/tcbn65lplvt_9lmT2.lef \
]

# Netlist
set init_verilog /home/designs/Synthesis/PSEC6_ch_digital/results/psec6_ch_digital_synth.v

# Top cell
set init_top_cell $DESIGN_NAME

# Power/Ground nets
set init_pwr_net {DVDD}
set init_gnd_net {DVSS}

# MMMC file
set init_mmmc_file scripts/view_definition.tcl

# Specifying the node we are working in
setDesignMode -process 65

#------------------------------------------------------------------------------
# Initialize Design
#------------------------------------------------------------------------------
init_design

setAnalysisMode -analysisType onChipVariation -cppr both

#------------------------------------------------------------------------------
# Floorplanning
#------------------------------------------------------------------------------
source "scripts/floorplan.tcl"

#------------------------------------------------------------------------------
# Power Planning
#------------------------------------------------------------------------------
# Use special routing to connect standard cell power pins and power rings
puts "Starting power planning..."

set pspace 1.0
set pwidth 0.5
set poffset 0.7

# Connecting the net we call VDD with the pins on the pcells for VDD
globalNetConnect DVDD -type pgpin -pin VDD -inst * -verbose
globalNetConnect DVSS -type pgpin -pin VSS -inst * -verbose

# Add power rings
setAddRingMode -stacked_via_top_layer M3 -stacked_via_bottom_layer M1
addRing -nets { DVDD DVSS } \
    -type core_rings \
    -around user_defined \
    -center 0 \
    -spacing $pspace \
    -width $pwidth \
    -offset $poffset \
    -threshold auto \
    -layer {bottom M1 top M1 right M2 left M2 }

# Add vertical power stripes
addStripe -nets { DVDD DVSS } \
    -layer M4 \
    -direction vertical \
    -width $pwidth \
    -spacing $pspace \
    -set_to_set_distance [expr 2 * ($pwidth + $pspace)] \
    -start_offset $poffset

# Connect all power pins/pads/rings
sroute -connect {blockPin padPin padRing corePin} \
    -allowJogging true \
    -allowLayerChange true \
    -blockPin useLef \

editChangeStatus -net {DVDD DVSS} -to FIXED

#------------------------------------------------------------------------------
# Placement
#------------------------------------------------------------------------------
puts "Starting placement..."

# Placement and optimization combined
place_opt_design

# Report
report_timing > reports/timing_preCTS.rpt
report_area > reports/area_postPlace.rpt

#------------------------------------------------------------------------------
# Clock Tree Synthesis - NOT NEEDED FOR REF_CLK_SEL_DECODER
#------------------------------------------------------------------------------
puts "Building clock tree..."

# Settings for ccopt
set_ccopt_property use_inverters auto

# Set CTS cells 
set_ccopt_property buffer_cells [find / -lib_cell CKB*LVT CKN*LVT]
set_ccopt_property inverter_cells [find / -lib_cell INV*LVT]
set_db opt_useful_skew true
set_db opt_useful_skew_ccopt extreme

# Create and run CTS
create_ccopt_clock_tree_spec
ccopt_design

# Report
report_ccopt_skew_groups > reports/clock_skew.rpt

#------------------------------------------------------------------------------
# Post-CTS Optimization
#------------------------------------------------------------------------------

# Optimize
set_db opt_area_recovery false
optDesign -postCts -setup -hold

report_timing -max_paths 100 > reports/timing_postCTS.rpt

#------------------------------------------------------------------------------
# Routing
#------------------------------------------------------------------------------
puts "Routing design..."

# Optimize routing
routeDesign
routeDesign -viaOpt

#------------------------------------------------------------------------------
# Post-Route Optimization
#------------------------------------------------------------------------------

# Optimize
optDesign -postRoute

#------------------------------------------------------------------------------
# Add Fillers
#------------------------------------------------------------------------------
# It is best to list them from largest to smallest to avoid gaps.
set tsmc_fillers [list FILL64LVT FILL32LVT FILL16LVT FILL8LVT FILL4LVT FILL2LVT FILL1LVT]

addFiller -cell ${tsmc_fillers} -fitGap
ecoRoute -target

#------------------------------------------------------------------------------
# Verification
#------------------------------------------------------------------------------
verifyConnectivity
verifyGeometry

#------------------------------------------------------------------------------
# Final Optimization
#------------------------------------------------------------------------------

# Optimize
optDesign -postRoute -drv

#------------------------------------------------------------------------------
# Final Reports
#------------------------------------------------------------------------------
report_area -out_file "reports/final_area.rpt"
report_timing -nworst 20 > "reports/final_timing.rpt"
report_power -outfile "reports/final_power.rpt"
report_qor -out_file "reports/final_qor.rpt" -format text
checkPinAssignment -outFile "reports/final_pin.rpt"
extractRC -outfile "reports/final_RC.cap"

#------------------------------------------------------------------------------
# Write Outputs
#------------------------------------------------------------------------------
set GDS_MAP ${TECH_DIR}/Back_End/lef/tcbn65lplvt_200a/techfiles/Virtuoso/map/mapfiles/Vir65nm_9M_6X1Z1U_v1.4b.042508.map
set STD_CELL_GDS ${TECH_DIR}//Back_End/gds/tcbn65lplvt_200a/tcbn65lplvt.gds

# Standard outputs
defOut results/${DESIGN_NAME}.def
saveNetlist results/${DESIGN_NAME}_final.v -phys
write_sdf results/${DESIGN_NAME}.sdf

# GDS for fabrication
setStreamOutMode -snapToMGrid true

streamOut results/${DESIGN_NAME}.gds \
    -structureName ${DESIGN_NAME} \
    -mapFile ${GDS_MAP} \
    -units 1000 \
    -merge ${STD_CELL_GDS} \
    -mode ALL

# LEF abstract for hierarchical P&R
write_lef_abstract results/${DESIGN_NAME}.lef \
    -stripePin

# Command to create OA Library
if {[catch {createLib ${DESIGN_NAME} -referenceTech tsmcN65} err]} {
    puts "Failed to create library ${DESIGN_NAME}: $err"
}

# Command to save to OA Library
oaOut ${DESIGN_NAME} ${DESIGN_NAME} layout \
    -refLibs {tcbn65lplvt tsmcN65} \
    -autoRemaster \
    -leafViewNames {layout} 

puts "="
puts "Outputs written:"
puts "  GDS:     results/${DESIGN_NAME}.gds"
puts "  DEF:     results/${DESIGN_NAME}.def"
puts "  LEF:     results/${DESIGN_NAME}.lef"

# Open final display
win