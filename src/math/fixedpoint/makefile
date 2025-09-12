OUTDIR=out
SIM_EXECUTABLE=runme

all: sim_icarus sim_verilator

##################################
# Build with icarus-verilog
build_icarus:
	iverilog \
		-g2005-sv \
		-I includes \
		-pfileline=1 \
		-Wall \
		add.sv \
		sub.sv \
		mul.sv \
		tb.sv

sim_icarus: build_icarus
	vvp a.out

clean_icarus:
	clear ; rm -f a.out

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
		-Iincludes \
		add.sv \
		sub.sv \
		mul.sv \
		tb.sv

sim_verilator: build_verilator
	$(OUTDIR)/$(SIM_EXECUTABLE)

clean_verilator:
	clear ; rm -fr $(OUTDIR)
