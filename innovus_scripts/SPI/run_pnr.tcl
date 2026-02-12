#==============================================================================
# Innovus Place & Route Script
#==============================================================================

# Has to be name of top module in design
set DESIGN_NAME "psec6_spi" 
set TECH_DIR "/opt/TSMC_65nm_MS_RF_LP/TSMCHOME/digital"

#------------------------------------------------------------------------------
# Set Design Variables (BEFORE init_design)
#------------------------------------------------------------------------------
# LEF files
set init_lef_file [list \
    ${TECH_DIR}/Back_End/lef/tcbn65lplvt_200a/lef/tcbn65lplvt_9lmT2.lef \
]

# Netlist
set init_verilog /home/designs/Synthesis/PSEC6_spi/results/psec6_spi_synth.v

# Top cell
set init_top_cell $DESIGN_NAME

# Power/Ground nets
set init_pwr_net {DVDD}
set init_gnd_net {DVSS}

# MMMC file
set init_mmmc_file scripts/view_definition.tcl

# Specifying the node we are working in
setDesignMode -process 65

# setDesignMode -flowEffort standard

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
globalNetConnect DVDD -type pgpin -pin VDD -inst * -override
globalNetConnect DVSS -type pgpin -pin VSS -inst * -override
globalNetConnect DVDD -type pgpin -pin DVDD -inst * -override
globalNetConnect DVSS -type pgpin -pin DVSS -inst * -override

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

# Add horizontal power stripes
addStripe -nets { DVDD DVSS } \
    -layer M2 \
    -direction horizontal \
    -width $pwidth \
    -spacing $pspace \
    -set_to_set_distance [expr 2 * ($pwidth + $pspace)] \
    -start_offset $poffset
# Connect all power pins/pads/rings
sroute -connect {corePin} \
    -allowJogging true \
    -allowLayerChange true \
    -blockPin useLef \

#------------------------------------------------------------------------------
# Placement
#------------------------------------------------------------------------------
puts "Starting placement..."

# Modern Innovus uses place_opt_design instead of place_design + refine_place
place_opt_design

# Report
report_timing > reports/timing_preCTS.rpt
report_area > reports/area_postPlace.rpt

#------------------------------------------------------------------------------
# Clock Tree Synthesis 
#------------------------------------------------------------------------------
puts "Building clock tree..."

# Set CTS cells 
set_ccopt_property buffer_cells [find / -lib_cell CKB*LVT CKN*LVT]
set_ccopt_property inverter_cells [find / -lib_cell INV*LVT]

# Create and run CTS
create_ccopt_clock_tree_spec
ccopt_design

# Report
report_ccopt_skew_groups > reports/clock_skew.rpt

#------------------------------------------------------------------------------
# Post-CTS Optimization
#------------------------------------------------------------------------------
optDesign -postCts

report_timing > reports/timing_postCTS.rpt

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

#------------------------------------------------------------------------------
# Verification
#------------------------------------------------------------------------------
verifyConnectivity
verifyGeometry
verifyProcessAntenna -report reports/antenna.rpt

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
set GDS_MAP ${TECH_DIR}/Back_End/lef/tcbn65lplvt_200a/techfiles/Virtuoso/map/mapfiles/Vir65nm_9M_6X2Y_v1.4b.042508.map

# Standard outputs
defOut results/${DESIGN_NAME}.def

# Save a version to run LVS
saveNetlist results/${DESIGN_NAME}_lvs.v \
    -includePowerGround \
    -includePhysicalInst \
    -excludeLeafCell

# Save a version for simulation (without physical-only cells)
saveNetlist results/${DESIGN_NAME}_sim.v \
    -excludeLeafCell

write_sdf results/${DESIGN_NAME}.sdf

# GDS for fabrication
streamOut results/${DESIGN_NAME}.gds \
    -mapFile ${GDS_MAP} \
    -units 1000 \
    -mode ALL \
    -outputMacros

# LEF abstract for hierarchical P&R
write_lef_abstract results/${DESIGN_NAME}.lef

# write_oa
# catch {create_oa_lib Test -oa_attach_tech_lib tsmcN65}
# write_oa Test $DESIGN_NAME layout -auto_remaster -oa_leaf_views {layout abstract}
# write_oa econdTMR_econd2 econdTMR layout -auto_remaster -oa_leaf_views {layout abstract}

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------
puts "="
puts "Place & Route Complete!"
puts "="
puts "Key Outputs:"
puts "  LVS Netlist:  results/${DESIGN_NAME}_lvs.v  (use this for LVS!)"
puts "  Sim Netlist:  results/${DESIGN_NAME}_sim.v"
puts "  GDS (normal): results/${DESIGN_NAME}.gds"
puts "  GDS (flat):   results/${DESIGN_NAME}_flat_vias.gds  (use for Virtuoso!)"
puts "  DEF:          results/${DESIGN_NAME}.def"
puts "  LEF:          results/${DESIGN_NAME}.lef"
puts "  SDF:          results/${DESIGN_NAME}.sdf"
puts "="
puts "For Virtuoso Import:"
puts "  1. Use ${DESIGN_NAME}_flat_vias.gds (flattened vias)"
puts "  2. Or export to OA directly (see below)"
puts "="

# OPTIONAL: Save directly to OA library (avoids GDS round-trip)
puts "To save directly to OA:"
puts "  1. File > Save > Design > OA Design Library"
puts "  2. Library: <your_oa_lib>"
puts "  3. Cell: ${DESIGN_NAME}"
puts "  4. View: layout"
puts "  5. Check 'Remaster Instances' to tcbn65lplvt"
puts "="

win