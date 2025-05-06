OUTDIR=out
SIM_EXECUTABLE=runme

build: clean
	iverilog \
		-g2005-sv \
		-I includes \
		-pfileline=1 \
		-Wall \
		tb.sv

sim: build
	vvp a.out

clean:
	clear ; rm -f a.out

#build: clean
#	verilator \
#		+1800-2012ext+sv \
#		-j 8 \
#		--assert \
#		--binary \
#		--exe \
#		--Mdir $(OUTDIR) \
#		-o $(SIM_EXECUTABLE) \
#		-Iincludes \
#		tb.sv

#sim: build
#	$(OUTDIR)/$(SIM_EXECUTABLE)

#clean:
#	clear ; rm -fr $(OUTDIR)
