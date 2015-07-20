.PHONY: test
test: simlibs
	vlog -mixedsvvh s                               \
	    -novopt -incr +acc -sv 							        \
	    insert_sort.sv
	vopt +acc                                       \
	    work.tb                                     \
	    -o tb_opt
	vsim                                            \
	    -c                                          \
	    -t 1ps                                      \
	    -l wlf/tb.log                   						\
	    -wlf wlf/tb.wlf                      				\
	    tb_opt                             					\
	    -do "onbreak { puts \"Done!\"; quit }; log -R /*; run -all; quit"

.PHONY: simlibs
simlibs:
	@echo "Make > .PHONY: simlibs"
	mkdir -p wlf
