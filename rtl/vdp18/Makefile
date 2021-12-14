
.PHONY: build

build:
	ghdl -a \
	vdp18_hor_vert.vhd \
	vdp18_addr_mux.vhd \
	vdp18_clk_gen.vhd \
	vdp18_col_mux.vhd \
	vdp18_ctrl.vhd \
	vdp18_cpuio.vhd \
	vdp18_pattern.vhd \
	vdp18_sprite.vhd \
	vdp18_core.vhd

	yosys -m ghdl -p 'ghdl vdp18_core; proc; opt; fsm; opt; memory; opt; write_verilog vdp18_core.v'

# another possibility:
# see https://gist.github.com/pcornier/2da9976a9d5603f717e384a88ff30fd5
# ghdl -a vdp18_hor_vert.vhd
# yosys -m ghdl -p 'ghdl vdp18_hor_vert; proc; opt; fsm; opt; memory; opt; write_verilog verilog/vdp18_hor_vert.v'
# ghdl -a vdp18_addr_mux.vhd
# yosys -m ghdl -p 'ghdl vdp18_addr_mux; proc; opt; fsm; opt; memory; opt; write_verilog verilog/vdp18_addr_mux.v'
# ghdl -a vdp18_clk_gen.vhd
# yosys -m ghdl -p 'ghdl vdp18_clk_gen; proc; opt; fsm; opt; memory; opt; write_verilog verilog/vdp18_clk_gen.v'
# ghdl -a vdp18_col_mux.vhd
# yosys -m ghdl -p 'ghdl vdp18_col_mux; proc; opt; fsm; opt; memory; opt; write_verilog verilog/vdp18_col_mux.v'
# ghdl -a vdp18_ctrl.vhd
# yosys -m ghdl -p 'ghdl vdp18_ctrl; proc; opt; fsm; opt; memory; opt; write_verilog verilog/vdp18_ctrl.v'
# ghdl -a vdp18_cpuio.vhd
# yosys -m ghdl -p 'ghdl vdp18_cpuio; proc; opt; fsm; opt; memory; opt; write_verilog verilog/vdp18_cpuio.v'
# ghdl -a vdp18_pattern.vhd
# yosys -m ghdl -p 'ghdl vdp18_pattern; proc; opt; fsm; opt; memory; opt; write_verilog verilog/vdp18_pattern.v'
# ghdl -a vdp18_sprite.vhd
# yosys -m ghdl -p 'ghdl vdp18_sprite; proc; opt; fsm; opt; memory; opt; write_verilog verilog/vdp18_sprite.v'
# ghdl -a vdp18_core.vhd
# yosys -m ghdl -p 'ghdl vdp18_core; proc; opt; fsm; opt; memory; opt; write_verilog verilog/vdp18_core2.v'
# then $ vhd2vl vdp18_core.vhd > verilog/vdp18_core.v
# with some incompatible lines commented out and restored after the conversion
