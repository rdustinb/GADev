FE=MyName
FI=8
FO=MoreStuff
FUM=20231004

buildip:
	@echo -e "Building the Xilinx IP!"
	@vivado -mode batch -source buildip.tcl

build:
	@echo -e "Building the design!"
	@vivado -mode batch -source build.tcl -tclargs $(FE) $(FI) $(FO) $(FUM)
