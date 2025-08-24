OUTDIR=out
SIM_EXECUTABLE=runme

all: sim_verilator

clean: clean_icarus clean_verilator

##################################
# Build with icarus-verilog
build_icarus:
	iverilog \
		-g2005-sv \
		-pfileline=1 \
		-Wall \
		prng_lfsr.sv \
		tb.sv

sim_icarus: build_icarus
	vvp a.out

clean_icarus:
	clear ; rm -f a.out *.vcd

##################################
# Build with verilator
build_verilator:
	verilator \
		+1800-2012ext+sv \
		-j 8 \
		--assert \
		--binary \
		--exe \
		--Mdir $(OUTDIR) \
		-o $(SIM_EXECUTABLE) \
		prng_lfsr.sv \
		tb.sv

sim_verilator: build_verilator
	$(OUTDIR)/$(SIM_EXECUTABLE)

clean_verilator:
	clear ; rm -fr $(OUTDIR) *.vcd
