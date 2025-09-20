LICENSETIMEOUT=60
LICENSETYPE=synplifypro
TCLSCRIPT=syn.tcl

help:
	@echo -e "Welcome to the Synplify Pro makefile"
	@echo -e "USAGE"
	@echo -e "  check_syntax - verifies the TCL script from the TCLSCRIPT= argument has valid syntax."
	@echo -e "  syn - runs synthesis in batch mode using the TCL script from the TCLSCRIPT= argument. Default is 'syn.tcl'"

check_syntax:
	@echo "Checking syntax on syntehsis TCL script..."
	@synplify_pro -tcl ${TCLSCRIPT} -tclcmd "project -run constraint_check"

syn:
	@echo "Running batch mode synthesis with a TCL script..."
	@synplify_pro -batch -license_wait ${LICENSETIMEOUT} -licensetype ${LICENSETYPE} ${TCLSCRIPT}

clean:
	@rm -fr stdout* *log* *.prj
