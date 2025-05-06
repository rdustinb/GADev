OUTDIR=out
SIM_EXECUTABLE=runme

##################################
# Build with icarus-verilog
build_icarus: clean_icarus
	iverilog \
		-g2005-sv \
		-I includes \
		-pfileline=1 \
		-Wall \
		tb.sv

sim_icarus: build_icarus
	vvp a.out

clean_icarus:
	clear ; rm -f a.out

##################################
# Build with verilator
build_verilator: clean_verilator
	verilator \
		+1800-2012ext+sv \
		-j 8 \
		--assert \
		--binary \
		--exe \
		--Mdir $(OUTDIR) \
		-o $(SIM_EXECUTABLE) \
		-Iincludes \
		tb.sv

sim_verilator: build_verilator
	$(OUTDIR)/$(SIM_EXECUTABLE)

clean_verilator:
	clear ; rm -fr $(OUTDIR)
