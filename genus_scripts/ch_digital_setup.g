# Setting the library paths in different corners
set_db init_lib_search_path /opt/TSMC_65nm_MS_RF_LP/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn65lplvt_200a
set_db library {
    tcbn65lplvttc_ccs.lib
    tcbn65lplvtwc_ccs.lib
    tcbn65lplvtbc_ccs.lib
}

# Reading in the hdl
set_db hdl_language sv
read_hdl /home/designs/Synthesis/PSEC6-Digital/ch_synthesis/types_pkg.sv
read_hdl /home/designs/Synthesis/PSEC6-Digital/ch_synthesis/ch_trigger_gen.sv
read_hdl /home/designs/Synthesis/PSEC6-Digital/ch_synthesis/ch_state_machine.sv
read_hdl /home/designs/Synthesis/PSEC6-Digital/ch_synthesis/ch_state_decoder.sv
read_hdl /home/designs/Synthesis/PSEC6-Digital/ch_synthesis/ch_spi_readout.sv
read_hdl /home/designs/Synthesis/PSEC6-Digital/ch_synthesis/ch_mode_decoder.sv
read_hdl /home/designs/Synthesis/PSEC6-Digital/ch_synthesis/ch_digital.sv

# Elaborating into RTL and reading constraints
elaborate PSEC6_CH_DIGITAL
set_top_module PSEC6_CH_DIGITAL
read_sdc /home/designs/Synthesis/PSEC6-Digital/constraints/psec6_ch_digital.sdc

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
report_area > /home/designs/Synthesis/PSEC6_spi/reports/ref_clk_sel_area.rpt
report_gates > /home/designs/Synthesis/PSEC6_spi/reports/ref_clk_sel_gates.rpt
report_timing -nworst 10 > /home/designs/Synthesis/PSEC6_spi/reports/ref_clk_sel_timing.rpt
report_power > /home/designs/Synthesis/PSEC6_spi/reports/ref_clk_sel_power.rpt
report_qor > /home/designs/Synthesis/PSEC6_spi/reports/ref_clk_sel_qor.rpt

# Writting output into netlist and constraints
write -mapped > /home/designs/Synthesis/PSEC6_spi/results/psec6_ch_digital_synth.v
write_sdc > /home/designs/Synthesis/PSEC6_spi/results/psec6_ch_digital_synth.sdc

puts "Synthesis complete!"
