# SDC File for ALU_TOP
# Target Frequency HP: 1.66GHz 
# Period HP = 1/1660MHz = 0.6024 ns
# Target Frequency LP: 0.12GHz 
# Period LP = 1/120MHz = 8.333 ns

# Set the SDC version
set sdc_version 2.0,

# Define units
set_time_unit -nanoseconds
set_load_unit -picofarads

#2.816GHz for enabling the TDS and path optimization of Genus
create_clock -name clk -period 0.355 [get_ports clk]

# NOTE: Clock uncertainty is explicitly set to 0 as requested.
# WARNING: This is highly unrealistic for physical implementation.
set_clock_uncertainty 0.050 [get_clocks clk]

#lp modules have relaxed clk
set_multicycle_path 20 -setup -through [get_cells adder_lp]
set_multicycle_path 19 -hold -through [get_cells adder_lp]
set_multicycle_path 20 -setup -through [get_cells mult_lp]
set_multicycle_path 19 -hold -through [get_cells mult_lp]


# Input Delays------------------------------------------------------
# Assuming inputs arrive somewhat after the clock edge (e.g., from typical flip-flops + wire delay)
# Using 80ps of input delay bc system is fast (45nm)
# This is the maximum time allowed from the clock edge until the signal reaches the ADDER32 inputs.
# flop propagation delay + wiring -> 60 + 20 
set_input_delay -max 0.08 -clock clk [get_ports {A[*] B[*] CMD[*] branch[*] idle low_power reset_n}]

# Add a hold check (set_input_delay -min)
set_input_delay -min 0.04 -clock clk [get_ports {A[*] B[*] CMD[*] branch[*] idle low_power reset_n}]

# Output Delays------------------------------------------------------
# Assuming outputs need to be stable before the next setup time (e.g., setup time + wire delay)
# Using 500ps of output delay bc system is fast (45nm)
# wiring + flop propagation delay -> 20 + 60
set_output_delay -max 0.08 -clock clk [get_ports {Y[*] result_aux flag_reg}]
set_output_delay -min -0.05 -clock clk [get_ports {Y[*] result_aux flag_reg}]


# --- Design Rule Constraints (DRCs)---------------------------------
# Transition time should be appropriate for the *period* (0.500 ns), not the I/O delay.
set_max_transition 0.08 [current_design] 
set_max_capacitance 0.3 [current_design]

# here is very important by deration we tell genus that real silicon can be %16 slower than rtl
# hence we encourage Genus to activate TDS and optimize the worst paths
set_timing_derate -early 0.90
set_timing_derate -late 1.16

