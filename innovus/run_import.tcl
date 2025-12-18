# run_import.tcl 
# -----------------------------------------------------------------------------

# 1. Define Input Files (Use 'set', NOT 'set_global')
set init_verilog "ALU_TOP_netlist.v"
set init_top_cell "ALU_TOP"

# 2. Define Physical Libraries (LEF)
set init_lef_file { \
    /home/public/Libs/lef/gsclib045_tech.lef \
    /home/public/Libs/lef/gsclib045_macro.lef \
    /home/public/Libs/lef/gsclib045_multibitsDFF.lef \
}

# 3. Define Power and Ground Nets
set init_pwr_net "VDD"
set init_gnd_net "VSS"

# 4. Link the MMMC file
set init_mmmc_file "mmmc.tcl"

# 5. Initialize the Design
init_design
