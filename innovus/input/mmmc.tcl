
# mmmc.tcl
# -----------------------------------------------------------------------------
# 1. Define the Library Set (Link to your .lib file)
create_library_set -name MyLibSet \
    -timing { /home/public/Libs/fast_vdd1v0_basicCells.lib }

# 2. Define the Delay Corner (Link library set to RC conditions)
# Note: We use the default RC extraction for now since TLU+ is missing
create_delay_corner -name MyDelayCorner \
    -library_set MyLibSet

# 3. Define the Constraint Mode (Link to your .sdc file)
create_constraint_mode -name MyConstraints \
    -sdc_files { ALU_TOP.sdc }

# 4. Define Analysis Views (Combine Delay Corner + Constraints)
create_analysis_view -name MyAnalysisView \
    -delay_corner MyDelayCorner \
    -constraint_mode MyConstraints

# 5. Set the Active Views (Tell Innovus which view to use for Setup/Hold)
set_analysis_view \
    -setup { MyAnalysisView } \
    -hold { MyAnalysisView }


