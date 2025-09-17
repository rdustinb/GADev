OUTDIR=out
SIM_EXECUTABLE=runme
TEST=tasks

all: sim_verilator

clean: preclean clean_verilator

##################################
# Common stuff...
preop:
	cp tests/${TEST}.svh run_test.svh

preclean:
	rm -f run_test.svh c/adder.o

##################################
# Build with verilator
build_verilator:
	verilator \
		-j 0 \
		+1800-2012ext+sv \
		--assert \
		--binary \
		--Mdir $(OUTDIR) \
		-o $(SIM_EXECUTABLE) \
		-Iincludes \
		--top tb \
		cpp/adder.cpp \
		tb.sv

sim_verilator: build_verilator
	$(OUTDIR)/$(SIM_EXECUTABLE)

clean_verilator:
	clear ; rm -fr $(OUTDIR)
