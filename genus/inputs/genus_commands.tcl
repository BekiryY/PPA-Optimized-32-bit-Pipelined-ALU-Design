genus 			//start

read_lib /home/public/cadence/libary/GPDK045/gsclib045_all_v4.4/gsclib045/timing/fast_vdd1v2_basicCells.lib /home/public/cadence/libary/GPDK045/gsclib045_all_v4.4/gsclib045/timing/fast_vdd1v2_basicCells.lib 


read_hdl -sv {ALU_TOP.sv ADDER32_FAST.sv ADDER32_LP.sv MULT32_FAST.sv MULT32_LP.sv SHIFTER.sv LOGIC_BLOCK.sv flag_controller.sv pipe_counter.sv c0_calculator.sv }

elaborate ALU_TOP

##---------------------do not optiimize much------------------------
set_db auto_ungroup none

##---------------------power gating------------------------
read_power_intent -1801 powergate.upf

apply_power_intent

check_power_intent

# Read .sdc file for extensive timing anaylsis
read_sdc ALU_TOP.sdc


syn_generic

syn_map

syn_opt

gui_show

write_netlist > ALU_TOP_netlist.v

write_hdl > top_mapped.v

write_sdc > top_mapped.sdc

write_power_intent > -1801 -base_name top_mapped

