# Setting the library paths in different corners
set_db init_lib_search_path /opt/TSMC_65nm_MS_RF_LP/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn65lplvt_200a
set_db library {
    tcbn65lplvttc_ccs.lib
    tcbn65lplvtwc_ccs.lib
    tcbn65lplvtbc_ccs.lib
}

# Add LEF file for physical information (IMPORTANT for P&R)
# read_physical -lef /opt/TSMC_65nm_MS_RF_LP/TSMCHOME/digital/Back_End/lef/tcbn65lplvt_200a/lef/tcbn65lplvt_9lmT2.lef

# Reading in the hdl
set_db hdl_language sv
read_hdl /home/designs/Synthesis/PSEC6-Digital/misc_synthesis/ref_clk_sel_decoder.sv

# Elaborating into RTL and reading constraints
elaborate ref_clk_sel_decoder
set_top_module ref_clk_sel_decoder
read_sdc /home/designs/Synthesis/PSEC6-Digital/constraints/psec6_ref_clk_sel.sdc

# Check timing setup
check_timing_intent

# Synthesis settings
set_db interconnect_mode ple
set_db syn_generic_effort high
set_db syn_map_effort high
set_db syn_opt_effort high
# set_db auto_ungroup both # Enable auto-ungrouping for better optimization
# set_db optimize_merge_flops true # Boundary optimization

# Synthesis flow
syn_generic
syn_map
syn_opt

# Reports (IMPORTANT - always check these!)
report_area > /home/designs/Synthesis/PSEC6_ref_clk_sel/reports/ref_clk_sel_area.rpt
report_gates > /home/designs/Synthesis/PSEC6_ref_clk_sel/reports/ref_clk_sel_gates.rpt
report_timing -nworst 10 > /home/designs/Synthesis/PSEC6_ref_clk_sel/reports/ref_clk_sel_timing.rpt
report_power > /home/designs/Synthesis/PSEC6_ref_clk_sel/reports/ref_clk_sel_power.rpt
report_qor > /home/designs/Synthesis/PSEC6_ref_clk_sel/reports/ref_clk_sel_qor.rpt

# Writting output into netlist and constraints
write -mapped > /home/designs/Synthesis/PSEC6_ref_clk_sel/results/ref_clk_sel_synth.v
write_sdc > /home/designs/Synthesis/PSEC6_ref_clk_sel/results/ref_clk_sel_synth.sdc

puts "Synthesis complete!"
