#==============================================================================
# MMMC View Definition File for TSMC 65nm
#==============================================================================

set TECH_DIR "/opt/TSMC_65nm_MS_RF_LP/TSMCHOME/digital"
set LIB_PATH "${TECH_DIR}/Front_End/timing_power_noise/CCS/tcbn65lplvt_200a"
set CAP_TABLE_DIR "${TECH_DIR}/Back_End/lef/tcbn65lplvt_200a/techfiles/captable"
set SDC_FILEPATH "/home/designs/Synthesis/PSEC6_readout_mux/results/readout_mux_synth.sdc"

#------------------------------------------------------------------------------
# Create Operating Conditions
#------------------------------------------------------------------------------
create_op_cond -name op_tt -V 1.2 -P 1.0 -T 27 -library [list ${LIB_PATH}/tcbn65lplvttc_ccs.lib]

create_op_cond -name op_ss -V 1.2 -P 1.0 -T 80 -library [list ${LIB_PATH}/tcbn65lplvtwc_ccs.lib]

create_op_cond -name op_ff -V 1.2 -P 1.0 -T 15 -library [list ${LIB_PATH}/tcbn65lplvtbc_ccs.lib]

#------------------------------------------------------------------------------
# Create Library Sets
#------------------------------------------------------------------------------
create_library_set -name lib_typ \
    -timing [list ${LIB_PATH}/tcbn65lplvttc_ccs.lib] 

create_library_set -name lib_slow \
    -timing [list ${LIB_PATH}/tcbn65lplvtwc_ccs.lib] 

create_library_set -name lib_fast \
    -timing [list ${LIB_PATH}/tcbn65lplvtbc_ccs.lib] 

#------------------------------------------------------------------------------
# Create RC Corners
#------------------------------------------------------------------------------
create_rc_corner -name rc_typ \
    -temperature 27 \
    -cap_table ${CAP_TABLE_DIR}/cln65lp_1p09m+alrdl_top2_typical.captable

create_rc_corner -name rc_slow \
    -temperature 80 \
    -cap_table ${CAP_TABLE_DIR}/cln65lp_1p09m+alrdl_top2_rcworst.captable

create_rc_corner -name rc_fast \
    -temperature 15 \
    -cap_table ${CAP_TABLE_DIR}/cln65lp_1p09m+alrdl_top2_rcbest.captable

#------------------------------------------------------------------------------
# Create Delay Corners
#------------------------------------------------------------------------------
create_delay_corner -name corner_typ \
    -library_set lib_typ \
    -rc_corner rc_typ \
    -opcond op_tt \

create_delay_corner -name corner_slow \
    -library_set lib_slow \
    -rc_corner rc_slow \
    -opcond op_ss \

create_delay_corner -name corner_fast \
    -library_set lib_fast \
    -rc_corner rc_fast \
    -opcond op_ff \

#------------------------------------------------------------------------------
# Create Constraint Modes
#------------------------------------------------------------------------------
create_constraint_mode -name func_mode \
    -sdc_files [list ${SDC_FILEPATH}]

#------------------------------------------------------------------------------
# Create Analysis Views
#------------------------------------------------------------------------------
create_analysis_view -name view_typ \
    -constraint_mode func_mode \
    -delay_corner corner_typ

create_analysis_view -name view_slow \
    -constraint_mode func_mode \
    -delay_corner corner_slow

create_analysis_view -name view_fast \
    -constraint_mode func_mode \
    -delay_corner corner_fast

#------------------------------------------------------------------------------
# Set Analysis Views
#------------------------------------------------------------------------------
set_analysis_view -setup {view_typ} \
    -hold {view_typ}