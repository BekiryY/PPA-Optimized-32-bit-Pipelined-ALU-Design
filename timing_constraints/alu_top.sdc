# SDC File for ALU_TOP
# Two Analysis Modes: HP and LP
# Target Frequency HP: 1.66GHz 
# Period HP = 1/1660MHz = 0.6024 ns
# Target Frequency LP: 0.12GHz 
# Period LP = 1/120MHz = 8.333 ns

# Set the SDC version
set sdc_version 2.0

# Define units
set_time_unit -nanoseconds
set_load_unit -picofarads

# NOTE: Clock uncertainty is explicitly set to 0 as requested.
# WARNING: This is highly unrealistic for physical implementation.
set_clock_uncertainty 0.050 [get_clocks clk]

create_clock -name clk -period 0.6024 [get_ports clk]

set_case_analysis 0 [get_ports low_power]
set_mode HP_MODE
# Input Delays------------------------------------------------------
# Assuming inputs arrive somewhat after the clock edge (e.g., from typical flip-flops + wire delay)
# Using 80ps of input delay bc system is fast (45nm)
# This is the maximum time allowed from the clock edge until the signal reaches the ADDER32 inputs.
# flop propagation delay + wiring -> 60 + 20 
set_input_delay -max 0.08 -clock clk [get_ports {A[*], B[*], CMD[*], idle, branch[*], low_power}]

# Add a hold check (set_input_delay -min)
set_input_delay -min 0.04 -clock clk [get_ports {A[*], B[*], CMD[*], idle, branch[*], low_power}]

# Output Delays------------------------------------------------------
# Assuming outputs need to be stable before the next setup time (e.g., setup time + wire delay)
# Using 500ps of output delay bc system is fast (45nm)
# wiring + flop propagation delay -> 20 + 60
set_output_delay -clock clk 0.08 [get_ports {result_aux[*], flag_reg[*], Y[*]}]
set_output_delay -min -0.05 -clock clk [get_ports {result_aux[*], flag_reg[*], Y[*]}]


# --- Design Rule Constraints (DRCs)---------------------------------
# Transition time should be appropriate for the *period* (0.500 ns), not the I/O delay.
set_max_transition 0.08 [current_design] 
set_max_capacitance 0.3 [current_design]

# here is very important by deration we tell genus that real silicon can be %16 slower than rtl
# hence we encourage Genus to activate TDS and optimize the worst paths
set_timing_derate -early 0.90
set_timing_derate -late 1.16



