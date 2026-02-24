# Setting the library paths in different corners
set_db init_lib_search_path /opt/TSMC_65nm_MS_RF_LP/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn65lplvt_200a
set_db library {
    tcbn65lplvttc_ccs.lib
    tcbn65lplvtwc_ccs.lib
    tcbn65lplvtbc_ccs.lib
}

# General Settings
# write_vlog_preserve_net_name true # doesn't work even tho it exists?????
# write_vlog_top_module_first true # also doesn't work????
# continue_on_error false # doesn't work, help root: lies

# Reading in the hdl
set_db hdl_language sv
read_hdl /home/designs/Synthesis/PSEC6-Digital/spi_synthesis/latched_rw_reg.sv
read_hdl /home/designs/Synthesis/PSEC6-Digital/spi_synthesis/serdes.sv
read_hdl /home/designs/Synthesis/PSEC6-Digital/spi_synthesis/spi_frontend.sv
read_hdl /home/designs/Synthesis/PSEC6-Digital/spi_synthesis/addr_logic.sv
read_hdl /home/designs/Synthesis/PSEC6-Digital/spi_synthesis/addr_to_ch_select.sv
read_hdl /home/designs/Synthesis/PSEC6-Digital/spi_synthesis/inst_driver.sv
read_hdl /home/designs/Synthesis/PSEC6-Digital/spi_synthesis/wr_regs.sv
read_hdl /home/designs/Synthesis/PSEC6-Digital/spi_synthesis/PSEC6_spi.sv

# Elaborating into RTL and reading constraints
elaborate psec6_spi
set_top_module psec6_spi
read_sdc /home/designs/Synthesis/PSEC6-Digital/constraints/psec6_spi.sdc

# Check timing setup
check_timing_intent

# Local Power Pins
# lef_add_power_and_ground_pins true # doesn't work
# use_power_ground_pin_from_lef true # doesn't work
set_db init_power_nets DVDD
set_db init_ground_nets DVSS
# set_db [get_db ports DVDD] .is_power_net true
# set_db [get_db ports DVSS] .is_ground_net true

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
write -mapped -pg > /home/designs/Synthesis/PSEC6_ref_clk_sel/results/psec6_spi_synth.v
write_sdc > /home/designs/Synthesis/PSEC6_ref_clk_sel/results/psec6_spi_synth.sdc

# write_hdl -generic -pg > /home/designs/Synthesis/PSEC6_ref_clk_sel/results/psec6_spi_synth.v # doesn't have power pins

puts "Synthesis complete!"
