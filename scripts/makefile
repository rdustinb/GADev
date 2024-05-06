help:
	@echo -e ""
	@echo -e "buildip     - builds the IP .xci files, generating simulation netlists and .dcp files."
	@echo -e "build       - runs the Vivado build flow."
	@echo -e "Build Options:"
	@echo -e "  LASTBUILDSTEP - branches the Vivado build, completing the build flow early without running everything."
	@echo -e "                  SYN, OPT, PLACE, PHYOPT, ROUTE, ALL"
	@echo -e ""
	@echo -e "lib_setup   - sets up the Libraries for simulation."
	@echo -e "lib_compile - compiles the Libraries for simulation."
	@echo -e "dut_compile - compiles the DUT source RTL for simulation."
	@echo -e ""
	@echo -e "clean       - whipes out all build products."

################################################################################
# For building stuff in Vivado
LASTBUILDSTEP=ALL
FE=MyName
FI=8
FO=MoreStuff
FUM=20231004

help:
	@echo -e "buildip - builds the IP .XCI files in the design, generating simulation netlists and .DCP files."
	@echo -e "build   - builds the design. Arguments to use with this flow:"
	@echo -e "  LASTBUILDSTEP - determines what is the final step of the build flow, allowing for short runs."
	@echo -e "                  SYN, OPT, PLACE, PHYOPT, ROUTE, or ALL"

buildip:
	@echo -e "Building the Xilinx IP!"
	@vivado -mode batch -source buildip.xtcl

build:
	@echo -e "Building the design!"
	@vivado -mode batch -source build.xtcl -tclargs $(LASTBUILDSTEP) $(FE) $(FI) $(FO) $(FUM)

################################################################################
# For simulating stuff with QuestaSim

# If several libraries are needed to be defined, this flow expects each library's set of files to be in a .vf file
# list...
LIBS=one two three four
LIBS_LIST=`echo ${LIBS} | sed -e "s/ / -L /g" | sed -e "s/^/-L /"`

# This variable is only indirectly used when lib_setup is called based on what is defined in the LIBS list...
THISLIB=

# This needs to be filled out to setup the environment. Where are the filelists stored?
FILELIST_FOLDER=~/myfilelists

# Any defines needed globally
DEFINES=+define+SIMULATION+EMULATION

# Any include directories for Verilog `include statements
INCDIRS=+incdir+~/myincs

lib_setup: clean
	@echo "Setting up the libraries..."
	@mkdir logs wlfs
	@$(foreach lib,$(LIBS), \
		mkdir -p libs/$(lib); \
		vlib libs/$(lib); \
		vmap $(lib) libs/$(lib); \
		make lib_compile THISLIB=$(lib); \
		)

# -preserve
#  This keeps any VHDL port or parameter names at the mixed-language boundary, as-written. This means any Verilog module
#  instantiating a VHDL entity will utilize whatever case the port or parameter is written in, even a form of cAmElCaSe.
#  This does not affect the compilation of the VHDL itself, as it is still compiled as case-insensitive.
lib_compile:
	@echo "Compiling VHDL library ${THISLIB}..."
	@vcom -64 \
		-2008 \
		-vhams \
		-mixedsvvh \
		-preserve \
		-work ${THISLIB} \
		-l logs/vcom.LIB_${THISLIB}.log \
		-f ${FILELIST_FOLDER}/${THISLIB}.vf

# -mfcu
#  This flag will utilize a global definitions file as a means to define multiple `define macros throughout the entire
#  hierarchy. Whether or not a respective Verilog file properly `includes said global define file. The global define
#  file must be listed first in the filelist.
dut_compile:
	@vlog -64 \
		-sv \
		-floatparameters \
		-work work \
		-mfcu \
		${DEFINES} \
		${LIBS_LIST} \
		-undef SYNTHESIS \
		-timescale=1ns/1ps \
		-l logs/vlog.dut_compile.log \
		${INCDIRS} \
		-f ${FILELIST_FOLDER}/top.vf

tb_compile:
	@cp tests/${TESTNAME}.svh thistest.svh
	@vlog -64 \
		-sv \
		-floatparameters \
		-work work \
		${DEFINES} \
		-l logs/vlog.tb_compile.log \
		+indcir+${INCDIRS} \
		tb.sv

# +acc is the old way to log and debug signals
#  Old QuestaSim visual and signal logging
# -access=rw+/.
# -debug
#  Always good to have when using Visualizer
opt_vsim: tb_compile
	@vopt -64 \
		-work work \
		${DEFINES} \
		${LIBS_LIST} \
		-L dut \
		-logs/opt_vsim.log \
		+indcir+${INCDIRS} \
		tb \
		-o tb_opt

# -sva
#  This enables SystemVerilog concurrent assertions
# -sv_seed
#  Specifies a number for the seed, or random for the simulator to use a random number
sim_vsim:
	@vsim -64 \
		-work work \
		-c \
		-sva \
		-sv_seed random \
		-l logs/sim_vsim.log \
		-wlf wlfs/sim.wlf \
		tb_opt \
		-do " log -R /* ; run -all ; quit -f "

clean:
	@rm -fr libs logs wlfs modelsim.ini
