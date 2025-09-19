help:
	@echo -e ""
	@echo -e "buildip     - builds the IP .xci files, generating simulation netlists and .dcp files."
	@echo -e "build       - runs the Vivado build flow."
	@echo -e "Build Options:"
	@echo -e "  LASTBUILDSTEP - branches the Vivado build, completing the build flow early without running everything."
	@echo -e "                  SYN, OPT, PLACE, PHYOPT, ROUTE, ALL"
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

clean:
	@rm -fr results
