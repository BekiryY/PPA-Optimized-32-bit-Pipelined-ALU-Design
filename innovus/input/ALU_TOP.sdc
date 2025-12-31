# SDC File for ALU_TOP
# -----------------------------------------------------------------------------

# 1. Clock Definition (1.0 GHz -> 1.0 ns period)
# Define the clock object named 'CLK_P' on the physical port 'clk'
# 1.00GHz -> 1.00ns
create_clock -name clk -period 0.604 -waveform {0 0.302} [get_ports clk]

# 2. Clock Uncertainty (Add margin for jitter/variation)
set_clock_uncertainty 0.05 [get_clocks clk]

# _lp modules have relaxed clk
# those modules can have 20x more timing budget
set_multicycle_path 6 -setup -through [get_cells adder_lp]
set_multicycle_path 6 -hold -through [get_cells adder_lp]
set_multicycle_path 6 -setup -through [get_cells mult_lp]
set_multicycle_path 6 -hold -through [get_cells mult_lp]

# 3. Input Delays
# Exclude the clock port itself from data arrival times!
# Max: Setup check
set_input_delay -max 0.08 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
# Min: Hold check
set_input_delay -min 0.04 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]

# 4. Output Delays
# Max: Setup check (You budgeted 0.29ns for external, leaving 0.71ns internal)
set_output_delay -max 0.08 -clock clk [all_outputs]
# Min: Hold check
set_output_delay -min -0.05 -clock clk [all_outputs]

# 5. Design Rule Constraints (Optimization Limits)
# Apply these globally to the 'current_design' instead of specific registers
set_max_transition 0.12 [current_design]
set_max_capacitance 0.5 [current_design]

