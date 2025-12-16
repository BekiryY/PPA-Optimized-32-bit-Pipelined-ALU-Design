# SDC File for MULT32_LP
# Target Frequency: 120 MHz
# Period = 1/120MHz = 8.333 ns

# Set the SDC version
set sdc_version 2.0

# Define units
set_time_unit -nanoseconds
set_load_unit -picofarads

# Create a virtual clock for input/output delay constraints
# Since the module is combinational, we use a virtual clock to define timing relative to the system clock.
create_clock -name vclk -period 8.333 


# Input Delays------------------------------------------------------
# Assuming inputs arrive somewhat after the clock edge (e.g., from typical flip-flops + wire delay)
# Using 200ps of input delay bc system is fast (45nm)
# This is the maximum time allowed from the clock edge until the signal reaches the ADDER32 inputs.
set_input_delay -max 0.2 -clock vclk [get_ports {A[*] B[*] power_en}]

# Add a hold check (set_input_delay -min)
set_input_delay -min 0.05 -clock vclk [get_ports {A[*] B[*] power_en}]

# Output Delays------------------------------------------------------
# Assuming outputs need to be stable before the next setup time (e.g., setup time + wire delay)
# Using 200ps of output delay bc system is fast (45nm)
set_output_delay -clock vclk 0.2 [get_ports {Y[*]}]
set_output_delay -min -0.05 -clock vclk [get_ports {Y[*]}]

# --- Design Rule Constraints (DRCs) --------------------------------
# Transition time should be appropriate for the *period* (8.333 ns), not the I/O delay.
set_max_transition 0.8 [current_design] 
set_max_capacitance 0.5 [current_design]
