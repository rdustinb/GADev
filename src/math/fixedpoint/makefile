OUTDIR=out
SIM_EXECUTABLE=runme
TEST=tasks

all: sim_icarus sim_verilator

clean: preclean clean_icarus clean_verilator

##################################
# Common stuff...
preop:
	cp tests/${TEST}.svh test.svh

preclean:
	rm -f test.svh

##################################
# Build with icarus-verilog
build_icarus: preop
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
