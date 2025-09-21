OUTDIR=out
SIM_EXECUTABLE=runme

################
# DPI only works with Verilator
sim_verilator: build_verilator
	$(OUTDIR)/$(SIM_EXECUTABLE)

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
		cpp/genRand.cpp \
		cpp/adder.cpp \
		tb.sv

################
# Clean
clean: clean_verilator

clean_verilator:
	clear ; rm -fr $(OUTDIR)
