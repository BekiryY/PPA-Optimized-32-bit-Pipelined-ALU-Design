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


# Input Delays
# Assuming inputs arrive somewhat after the clock edge (e.g., from typical flip-flops + wire delay)
# Using 500ps of input delay bc system is fast (45nm)
set_input_delay -clock vclk 0.5 [get_ports {A[*]}]
set_input_delay -clock vclk 0.5 [get_ports {B[*]}]
set_input_delay -clock vclk 0.5 [get_ports power_en]

# Output Delays
# Assuming outputs need to be stable before the next setup time (e.g., setup time + wire delay)
# Using 500ps of output delay bc system is fast (45nm)
set_output_delay -clock vclk 0.5 [get_ports {Y[*]}]

# Optional: Set default load and drive to realistic values if not characterized
set_load 0.05 [get_ports {Y[*]}]
