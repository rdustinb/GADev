.PHONY: test
test: simlibs
	vlog -mixedsvvh s                               \
	    -incr +acc -sv 							        				\
	    insert_sort.sv															\
	    tb.sv
	vsim                                            \
	    -c                                          \
	    -t 1ps                                      \
	    -l wlf/tb.log                   						\
	    -wlf wlf/tb.wlf                      				\
	    tb                                					\
	    -do "onbreak { puts \"Done!\"; quit }; log -r /*; run -all; quit"

.PHONY: simlibs
simlibs:
	@echo "Make > .PHONY: simlibs"
	mkdir -p wlf
	mkdir -p libs
	vlib libs
	vmap work libs
