# ####################################################################

#  Created by Genus(TM) Synthesis Solution 21.18-s082_1 on Thu Dec 18 23:35:10 +03 2025

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design ALU_TOP

create_clock -name "clk" -period 0.355 -waveform {0.0 0.1775} [get_ports clk]
set_multicycle_path -through [list \
  [get_pins {adder_lp/Y[0]}]  \
  [get_pins {adder_lp/Y[1]}]  \
  [get_pins {adder_lp/Y[2]}]  \
  [get_pins {adder_lp/Y[3]}]  \
  [get_pins {adder_lp/Y[4]}]  \
  [get_pins {adder_lp/Y[5]}]  \
  [get_pins {adder_lp/Y[6]}]  \
  [get_pins {adder_lp/Y[7]}]  \
  [get_pins {adder_lp/Y[8]}]  \
  [get_pins {adder_lp/Y[9]}]  \
  [get_pins {adder_lp/Y[10]}]  \
  [get_pins {adder_lp/Y[11]}]  \
  [get_pins {adder_lp/Y[12]}]  \
  [get_pins {adder_lp/Y[13]}]  \
  [get_pins {adder_lp/Y[14]}]  \
  [get_pins {adder_lp/Y[15]}]  \
  [get_pins {adder_lp/Y[16]}]  \
  [get_pins {adder_lp/Y[17]}]  \
  [get_pins {adder_lp/Y[18]}]  \
  [get_pins {adder_lp/Y[19]}]  \
  [get_pins {adder_lp/Y[20]}]  \
  [get_pins {adder_lp/Y[21]}]  \
  [get_pins {adder_lp/Y[22]}]  \
  [get_pins {adder_lp/Y[23]}]  \
  [get_pins {adder_lp/Y[24]}]  \
  [get_pins {adder_lp/Y[25]}]  \
  [get_pins {adder_lp/Y[26]}]  \
  [get_pins {adder_lp/Y[27]}]  \
  [get_pins {adder_lp/Y[28]}]  \
  [get_pins {adder_lp/Y[29]}]  \
  [get_pins {adder_lp/Y[30]}]  \
  [get_pins {adder_lp/Y[31]}]  \
  [get_pins {adder_lp/Y[32]}]  \
  [get_pins {mult_lp/Y[0]}]  \
  [get_pins {mult_lp/Y[1]}]  \
  [get_pins {mult_lp/Y[2]}]  \
  [get_pins {mult_lp/Y[3]}]  \
  [get_pins {mult_lp/Y[4]}]  \
  [get_pins {mult_lp/Y[5]}]  \
  [get_pins {mult_lp/Y[6]}]  \
  [get_pins {mult_lp/Y[7]}]  \
  [get_pins {mult_lp/Y[8]}]  \
  [get_pins {mult_lp/Y[9]}]  \
  [get_pins {mult_lp/Y[10]}]  \
  [get_pins {mult_lp/Y[11]}]  \
  [get_pins {mult_lp/Y[12]}]  \
  [get_pins {mult_lp/Y[13]}]  \
  [get_pins {mult_lp/Y[14]}]  \
  [get_pins {mult_lp/Y[15]}]  \
  [get_pins {mult_lp/Y[16]}]  \
  [get_pins {mult_lp/Y[17]}]  \
  [get_pins {mult_lp/Y[18]}]  \
  [get_pins {mult_lp/Y[19]}]  \
  [get_pins {mult_lp/Y[20]}]  \
  [get_pins {mult_lp/Y[21]}]  \
  [get_pins {mult_lp/Y[22]}]  \
  [get_pins {mult_lp/Y[23]}]  \
  [get_pins {mult_lp/Y[24]}]  \
  [get_pins {mult_lp/Y[25]}]  \
  [get_pins {mult_lp/Y[26]}]  \
  [get_pins {mult_lp/Y[27]}]  \
  [get_pins {mult_lp/Y[28]}]  \
  [get_pins {mult_lp/Y[29]}]  \
  [get_pins {mult_lp/Y[30]}]  \
  [get_pins {mult_lp/Y[31]}]  \
  [get_pins {mult_lp/Y[32]}]  \
  [get_pins {mult_lp/Y[33]}]  \
  [get_pins {mult_lp/Y[34]}]  \
  [get_pins {mult_lp/Y[35]}]  \
  [get_pins {mult_lp/Y[36]}]  \
  [get_pins {mult_lp/Y[37]}]  \
  [get_pins {mult_lp/Y[38]}]  \
  [get_pins {mult_lp/Y[39]}]  \
  [get_pins {mult_lp/Y[40]}]  \
  [get_pins {mult_lp/Y[41]}]  \
  [get_pins {mult_lp/Y[42]}]  \
  [get_pins {mult_lp/Y[43]}]  \
  [get_pins {mult_lp/Y[44]}]  \
  [get_pins {mult_lp/Y[45]}]  \
  [get_pins {mult_lp/Y[46]}]  \
  [get_pins {mult_lp/Y[47]}]  \
  [get_pins {mult_lp/Y[48]}]  \
  [get_pins {mult_lp/Y[49]}]  \
  [get_pins {mult_lp/Y[50]}]  \
  [get_pins {mult_lp/Y[51]}]  \
  [get_pins {mult_lp/Y[52]}]  \
  [get_pins {mult_lp/Y[53]}]  \
  [get_pins {mult_lp/Y[54]}]  \
  [get_pins {mult_lp/Y[55]}]  \
  [get_pins {mult_lp/Y[56]}]  \
  [get_pins {mult_lp/Y[57]}]  \
  [get_pins {mult_lp/Y[58]}]  \
  [get_pins {mult_lp/Y[59]}]  \
  [get_pins {mult_lp/Y[60]}]  \
  [get_pins {mult_lp/Y[61]}]  \
  [get_pins {mult_lp/Y[62]}]  \
  [get_pins {mult_lp/Y[63]}] ] -setup -end 20
set_multicycle_path -through [list \
  [get_pins {adder_lp/Y[0]}]  \
  [get_pins {adder_lp/Y[1]}]  \
  [get_pins {adder_lp/Y[2]}]  \
  [get_pins {adder_lp/Y[3]}]  \
  [get_pins {adder_lp/Y[4]}]  \
  [get_pins {adder_lp/Y[5]}]  \
  [get_pins {adder_lp/Y[6]}]  \
  [get_pins {adder_lp/Y[7]}]  \
  [get_pins {adder_lp/Y[8]}]  \
  [get_pins {adder_lp/Y[9]}]  \
  [get_pins {adder_lp/Y[10]}]  \
  [get_pins {adder_lp/Y[11]}]  \
  [get_pins {adder_lp/Y[12]}]  \
  [get_pins {adder_lp/Y[13]}]  \
  [get_pins {adder_lp/Y[14]}]  \
  [get_pins {adder_lp/Y[15]}]  \
  [get_pins {adder_lp/Y[16]}]  \
  [get_pins {adder_lp/Y[17]}]  \
  [get_pins {adder_lp/Y[18]}]  \
  [get_pins {adder_lp/Y[19]}]  \
  [get_pins {adder_lp/Y[20]}]  \
  [get_pins {adder_lp/Y[21]}]  \
  [get_pins {adder_lp/Y[22]}]  \
  [get_pins {adder_lp/Y[23]}]  \
  [get_pins {adder_lp/Y[24]}]  \
  [get_pins {adder_lp/Y[25]}]  \
  [get_pins {adder_lp/Y[26]}]  \
  [get_pins {adder_lp/Y[27]}]  \
  [get_pins {adder_lp/Y[28]}]  \
  [get_pins {adder_lp/Y[29]}]  \
  [get_pins {adder_lp/Y[30]}]  \
  [get_pins {adder_lp/Y[31]}]  \
  [get_pins {adder_lp/Y[32]}]  \
  [get_pins {mult_lp/Y[0]}]  \
  [get_pins {mult_lp/Y[1]}]  \
  [get_pins {mult_lp/Y[2]}]  \
  [get_pins {mult_lp/Y[3]}]  \
  [get_pins {mult_lp/Y[4]}]  \
  [get_pins {mult_lp/Y[5]}]  \
  [get_pins {mult_lp/Y[6]}]  \
  [get_pins {mult_lp/Y[7]}]  \
  [get_pins {mult_lp/Y[8]}]  \
  [get_pins {mult_lp/Y[9]}]  \
  [get_pins {mult_lp/Y[10]}]  \
  [get_pins {mult_lp/Y[11]}]  \
  [get_pins {mult_lp/Y[12]}]  \
  [get_pins {mult_lp/Y[13]}]  \
  [get_pins {mult_lp/Y[14]}]  \
  [get_pins {mult_lp/Y[15]}]  \
  [get_pins {mult_lp/Y[16]}]  \
  [get_pins {mult_lp/Y[17]}]  \
  [get_pins {mult_lp/Y[18]}]  \
  [get_pins {mult_lp/Y[19]}]  \
  [get_pins {mult_lp/Y[20]}]  \
  [get_pins {mult_lp/Y[21]}]  \
  [get_pins {mult_lp/Y[22]}]  \
  [get_pins {mult_lp/Y[23]}]  \
  [get_pins {mult_lp/Y[24]}]  \
  [get_pins {mult_lp/Y[25]}]  \
  [get_pins {mult_lp/Y[26]}]  \
  [get_pins {mult_lp/Y[27]}]  \
  [get_pins {mult_lp/Y[28]}]  \
  [get_pins {mult_lp/Y[29]}]  \
  [get_pins {mult_lp/Y[30]}]  \
  [get_pins {mult_lp/Y[31]}]  \
  [get_pins {mult_lp/Y[32]}]  \
  [get_pins {mult_lp/Y[33]}]  \
  [get_pins {mult_lp/Y[34]}]  \
  [get_pins {mult_lp/Y[35]}]  \
  [get_pins {mult_lp/Y[36]}]  \
  [get_pins {mult_lp/Y[37]}]  \
  [get_pins {mult_lp/Y[38]}]  \
  [get_pins {mult_lp/Y[39]}]  \
  [get_pins {mult_lp/Y[40]}]  \
  [get_pins {mult_lp/Y[41]}]  \
  [get_pins {mult_lp/Y[42]}]  \
  [get_pins {mult_lp/Y[43]}]  \
  [get_pins {mult_lp/Y[44]}]  \
  [get_pins {mult_lp/Y[45]}]  \
  [get_pins {mult_lp/Y[46]}]  \
  [get_pins {mult_lp/Y[47]}]  \
  [get_pins {mult_lp/Y[48]}]  \
  [get_pins {mult_lp/Y[49]}]  \
  [get_pins {mult_lp/Y[50]}]  \
  [get_pins {mult_lp/Y[51]}]  \
  [get_pins {mult_lp/Y[52]}]  \
  [get_pins {mult_lp/Y[53]}]  \
  [get_pins {mult_lp/Y[54]}]  \
  [get_pins {mult_lp/Y[55]}]  \
  [get_pins {mult_lp/Y[56]}]  \
  [get_pins {mult_lp/Y[57]}]  \
  [get_pins {mult_lp/Y[58]}]  \
  [get_pins {mult_lp/Y[59]}]  \
  [get_pins {mult_lp/Y[60]}]  \
  [get_pins {mult_lp/Y[61]}]  \
  [get_pins {mult_lp/Y[62]}]  \
  [get_pins {mult_lp/Y[63]}] ] -hold -start 19
set_clock_gating_check -setup 0.0 
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[31]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[30]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[29]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[28]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[27]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[26]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[25]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[24]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[23]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[22]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[21]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[20]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[19]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[18]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[17]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[16]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[15]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[14]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[13]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[12]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[11]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[10]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[9]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[8]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[7]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[6]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[5]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[4]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[3]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[2]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {A[0]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[31]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[30]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[29]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[28]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[27]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[26]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[25]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[24]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[23]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[22]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[21]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[20]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[19]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[18]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[17]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[16]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[15]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[14]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[13]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[12]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[11]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[10]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[9]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[8]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[7]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[6]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[5]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[4]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[3]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[2]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {B[0]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {CMD[4]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {CMD[3]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {CMD[2]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {CMD[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {CMD[0]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {branch[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {branch[0]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports idle]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports low_power]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports reset_n]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[31]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[30]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[29]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[28]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[27]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[26]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[25]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[24]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[23]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[22]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[21]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[20]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[19]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[18]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[17]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[16]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[15]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[14]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[13]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[12]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[11]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[10]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[9]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[8]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[7]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[6]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[5]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[4]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[3]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[2]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {A[0]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[31]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[30]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[29]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[28]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[27]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[26]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[25]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[24]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[23]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[22]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[21]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[20]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[19]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[18]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[17]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[16]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[15]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[14]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[13]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[12]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[11]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[10]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[9]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[8]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[7]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[6]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[5]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[4]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[3]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[2]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {B[0]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {CMD[4]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {CMD[3]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {CMD[2]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {CMD[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {CMD[0]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {branch[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports {branch[0]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports idle]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports low_power]
set_input_delay -clock [get_clocks clk] -add_delay -min 0.04 [get_ports reset_n]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[31]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[30]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[29]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[28]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[27]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[26]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[25]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[24]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[23]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[22]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[21]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[20]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[19]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[18]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[17]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[16]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[15]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[14]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[13]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[12]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[11]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[10]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[9]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[8]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[7]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[6]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[5]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[4]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[3]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[2]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[1]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {Y[0]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[31]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[30]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[29]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[28]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[27]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[26]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[25]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[24]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[23]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[22]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[21]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[20]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[19]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[18]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[17]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[16]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[15]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[14]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[13]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[12]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[11]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[10]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[9]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[8]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[7]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[6]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[5]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[4]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[3]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[2]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[1]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {result_aux[0]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {flag_reg[7]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {flag_reg[6]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {flag_reg[5]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {flag_reg[4]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {flag_reg[3]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {flag_reg[2]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {flag_reg[1]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.08 [get_ports {flag_reg[0]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[31]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[30]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[29]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[28]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[27]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[26]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[25]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[24]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[23]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[22]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[21]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[20]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[19]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[18]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[17]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[16]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[15]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[14]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[13]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[12]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[11]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[10]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[9]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[8]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[7]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[6]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[5]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[4]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[3]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[2]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[1]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {Y[0]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[31]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[30]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[29]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[28]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[27]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[26]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[25]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[24]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[23]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[22]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[21]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[20]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[19]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[18]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[17]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[16]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[15]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[14]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[13]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[12]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[11]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[10]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[9]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[8]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[7]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[6]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[5]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[4]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[3]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[2]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[1]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {result_aux[0]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {flag_reg[7]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {flag_reg[6]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {flag_reg[5]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {flag_reg[4]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {flag_reg[3]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {flag_reg[2]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {flag_reg[1]}]
set_output_delay -clock [get_clocks clk] -add_delay -min -0.05 [get_ports {flag_reg[0]}]
set_max_transition 0.08 [current_design]
set_max_capacitance 0.3 [current_design]
set_wire_load_mode "enclosed"
set_dont_touch [get_nets power_en_adder]
set_dont_touch [get_nets power_en_mult]
set_clock_uncertainty -setup 0.05 [get_clocks clk]
set_clock_uncertainty -hold 0.05 [get_clocks clk]
