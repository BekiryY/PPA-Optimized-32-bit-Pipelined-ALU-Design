xrun ADDER32_FAST.sv ADDER32_FAST_CT.sv -64bit -access +rwc -coverage all -covoverwrite^C

xrun MULT32_FAST.sv MULT32_FAST_CT.sv -64bit -access +rwc -coverage all -covoverwrite

xrun SHIFTER.sv SHIFTER_CT.sv -64bit -access +rwc -coverage all -covoverwrite

xrun LOGIC_BLOCK.sv LOGIC_BLOCK_CT.sv -64bit -access +rwc -coverage all -covoverwrite

xrun ALU_TOP.sv ALU_TOP_CT.sv c0_calculator.sv conflict_handler.sv flag_controller.sv pipe_counter.sv ADDER32_FAST.sv MULT32_FAST.sv LOGIC_BLOCK.sv SHIFTER.sv ADDER32_LP.sv MULT32_LP.sv -64bit -access +rwc -coverage all -covoverwrite
