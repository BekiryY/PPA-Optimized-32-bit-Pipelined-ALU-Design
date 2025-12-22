Some of these schematics are depreceated and will not %100 reflect the current modules.
Sorry for inconvinience but generating decent schematic using vivado is cumbersome work.

alu_top(OLD)		->	Mostly same features not present in the schematic are:
				pipeline counting
				valid_input & valid output handling
mult32_fast(OLD) 	->	Mostly same but valid_pipe calculation removed in the current module
shifter(OLD)		->	Mostly same but BYT_SWP and ROR/ROL are not present in the schematic

COLOR OF NETS AND INSTANCES at alu_top(OLD).pdf:

------- COLOR --------- MEANING -------
---------------------------------------
	CYAN		clk
	ORANGE		reset_n
	RED		CMD (opcode)
	YELLOW		low_power-only modules
	YELLOW		low_power mode selection signalde selection signal
	BLUE		A & B inputs (operands)
	BLUE		High performance modules
	PURPLE 		output signals