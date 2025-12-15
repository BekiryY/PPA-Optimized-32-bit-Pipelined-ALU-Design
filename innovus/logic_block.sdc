# -----------------------------------------------------------------------------
# SDC for Combinational Block: logic_block
# -----------------------------------------------------------------------------

# 1. External Clock Reference
# The block is combinational, so we only need to DEFINE the external clock 
# environment it operates within. This clock is NOT physically in this block.
create_clock -name clk -period .666 -waveform {0 0.333} [get_ports clk] 
# Note: 'clk_port_reference' is a placeholder. You usually define the clock 
# on the top-level port (like the original 'clk' in ALU_TOP) and let the tool 
# trace it to the boundary registers of the logic_block.

# 2. Clock Uncertainty (Adopted from the top-level clock clk)
set_clock_uncertainty 0.04 [get_clocks clk]

# 3. Input Delays (Crucial for Combinational Blocks)
# Max: Total time available (period - uncertainty - output budget)
# We budget the time from the external clock's launch edge to the input of the logic_block.
set_input_delay -max 0.100 -clock clk [all_inputs]

# Min: Hold check
set_input_delay -min 0.040 -clock clk [all_inputs]


# 4. Output Delays (Crucial for Combinational Blocks)
# Max: Time budget for the logic_block's output to reach the next register's input.
# (whatever combinational at the output upto dff) + wiring delay + setup time of dff 
#										30ps													+			20ps		 +				50ps
set_output_delay -max 0.10 -clock clk [all_outputs]

# Min: Hold check
#Output Delay (min) = Required Hold Time - Wire Delay
set_output_delay -min -0.05 -clock clk [all_outputs]

# 5. Design Rule Constraints (Optimization Limits)
set_max_transition 0.1 [current_design]
set_max_capacitance 0.5 [current_design]

# Path_Delay < Period - Input_Delay - Output_Delay - Uncertainty
