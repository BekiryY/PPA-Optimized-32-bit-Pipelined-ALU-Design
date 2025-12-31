#-------------------------------------------------------------------------
# 1. DESIGN IMPORT
# -------------------------------------------------------------------------
source run_import.tcl

# -------------------------------------------------------------------------
# 2. FLOORPLANNING & PIN PLACEMENT
# -------------------------------------------------------------------------
# Set the canvas size
floorPlan -r 1.0 0.65 10.0 10.0 10.0 10.0
#this function is broken in my version of cadence

# Place Pins NOW, before placing cells.
# If you place pins later, the tool will have already placed cells far away 
# from where the pins eventually land, ruining your timing.

editPin -side Left -layer M3 -pin {A[*] clk idle low_power reset_n input_valid} -spreadType center -spacing 5.0
editPin -side Bottom -layer M3 -pin {B[*] CMD[*] branch[*]}  -spreadType center -spacing 5.0
editPin -side Top -layer M3 -pin {Y[*] output_valid}  -spreadType center -spacing 5.0
editPin -side Right -layer M3 -pin {result_aux[*] flag_reg[*]} -spreadType center -spacing 5.0

# -------------------------------------------------------------------------
# 3. GRID & POWER DISTRIBUTION
# -------------------------------------------------------------------------

addRing -nets {VDD VSS} -type core_rings -width 2.0 -spacing 1.0 \
    -layer_top M5 -layer_bottom M5 \
    -layer_left M6 -layer_right M6
addStripe -nets {VDD VSS} -layer M6 -direction vertical \
    -width 2.0 -spacing 1.0 -set_to_set_distance 50.0

# Connect Std Cells (Sroute)
# Note: For LP designs, ensure sroute connects the power switch outputs to the gated cells!
sroute -connect { corePin } -layerChangeRange { M1 M6 } \
    -blockPinTarget { nearestTarget } -allowJogging 1 \
    -crossoverViaLayerRange { M1 M6 } -nets { VDD VSS } -allowLayerChange 1

# -------------------------------------------------------------------------
# 4. PLACEMENT (Standard Cells + Isolation Cells)
# -------------------------------------------------------------------------
# Now we place. Because UPF is committed, Innovus automatically:
# 1. Groups LP modules together.
# 2. Inserts Level Shifters and Isolation Cells at the boundaries.
place_opt_design


----------------either this--------------
setOptMode -usefulSkew true

optDesign -postCTS -setup 
---------------or this------------------
setOptMode -setupTargetSlack 0.10

optDesign -postCTS -setup -incr 
---------------------------------------

report_timing -path_group default -max_paths 5 -nworst 1


# -------------------------------------------------------------------------
# 6. CLOCK TREE SYNTHESIS (CTS)
# -------------------------------------------------------------------------
# [CORRECTION] CTS must happen BEFORE detailed routing.
# define reset skew group
create_ccopt_skew_group -name reset_tree -sources reset_n -auto_sinks

# Configure and Run CTS
create_ccopt_clock_tree_spec
ccopt_design

# Optimization after CTS (Fixes Hold time introduced by clock skew)
optDesign -postCTS -hold

 -------------------------------------------------------------------------
# 7. ROUTING
# -------------------------------------------------------------------------
# Only route AFTER the clock tree is built.
routeDesign

# -------------------------------------------------------------------------
# 8. POST-ROUTE OPTIMIZATION (Sign-off Closure)
# -------------------------------------------------------------------------
# Enable OCV (On-Chip Variation) for accurate analysis
setAnalysisMode -analysisType onChipVariation -cppr both

# Final cleanup for Setup and Hold
optDesign -postRoute
optDesign -postRoute -hold

