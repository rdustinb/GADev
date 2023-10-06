# Capture the TCL Arguments from the Makefile
set FE    [lindex $argv 0]
set FI    [lindex $argv 1]
set FO    [lindex $argv 2]
set FUM   [lindex $argv 3]

puts "build.tcl : FE  is $FE"
puts "build.tcl : FI  is $FI"
puts "build.tcl : FO  is $FO"
puts "build.tcl : FUM is $FUM"

# Setup some useful variables
set bitfileName "myBuild_$FE$FI$FO$FUM"
set includesDir "../../includes"
set resultsDir "./results"

if { [file exists $includesDir] == 0 } {
  puts "build.tcl : The includes directory $includesDir doesn't exist..."
  exit
}

# Define the Part and store it in a variable
set outputPart xc7vx485tffg1761-2
set_part $outputPart

# Read in any IP Containers (this will be the same as step 2 of the buildip.tcl script)
read_ip ./ip/xilinx/my_ip/my_ip.xci

# Read in custom HDL
read_vhdl -vhdl2008 ./src/mycode.vhd

read_verilog        ./src/mycode.sv

# Put specific files into a library if needed...
set_property library my_library [get_files ./src/mycode.vhd]

# Read in the constraints
read_xdc ./constraints/pins.xdc
read_xdc ./constraints/timing.xdc
read_xdc ./constraints/fp.xdc
read_xdc ./constraints/project.xdc

# Build Step 1) Synthesize the Design
set_msg_config -id "Synth 8-7129" -limit 1000

synth_design -top mytop \
  -part $outputPart \
  -include_dirs $includesDir \
  -generic MY_VHDL_GENERIC=1'b1

write_checkpoint -force $resultsDir/1_synthesis_checkpoint

check_timing -verbose   -file $resultsDir/1_timing_check.rpt
report_timing_summary   -file $resultsDir/1_timing_summary.rpt
report_power            -file $resultsDir/1_power_utilization.rpt
report_high_fanout_nets -fanout_greater_than 200 -max_nets 50 -file $resultsDir/1_high_fanout_nets.rpt

# Build Step 2) Place the Design
opt_design

create_waiver -type DRC -id {PORTPROP-10} -user "me" \
  -objects [get_ports some_port] \
  -description {I am waiving this check for this port...}

# Wrap the place design step in a catch clause to print the results later
set placer_return_code [ catch {place_design} placer_return_results ]

write_checkpoint -force $resultsDir/2_placer_checkpoint

# Dump the debug info
if {$placer_return_code != 0} {
  puts "\n\n"
  puts "Build Script"
  puts "Placer return code is: $placer_return_code"
  puts "Placer return results are: $placer_return_results"
  puts "\n\n"
  report_drc            -file $resultsDir/2_drc_errors.rpt
  # Don't continue if the placer failed...
  exit
}

# Run Physical Optimizer (this is a last ditch effort to fix stuff, it would be better to fix the code
if {[get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]] < 0} {
  puts "Found setup timing violations => running physical optimization"
  phys_opt_design
}

report_bus_skew         -file $resultsDir/2_timing_bus_skew.rpt
report_timing_summary   -file $resultsDir/2_timing_summary.rpt

# Build Step 3) Route the Design
set router_return_code [ catch {route_design} router_return_results ]

write_checkpoint -force $resultsDir/3_router_checkpoint

# Dump the debug info
if {$router_return_code != 0} {
  puts "\n\n"
  puts "Build Script"
  puts "Router return code is: $router_return_code"
  puts "Router return results are: $router_return_results"
  puts "\n\n"
  report_drc            -file $resultsDir/3_drc_errors.rpt
  # Don't continue if the router failed...
  exit
}

# Seee UG835 page 27 for the full list of reports which may be run in the TCL scripts
report_timing_summary -check_timing_verbose -file $resultsDir/3_timing_summary.rpt
report_timing         -setup  -nworst 100   -file $resultsDir/3_timing_setup.rpt
report_timing         -hold   -nworst 100   -file $resultsDir/3_timing_hold.rpt
report_clocks                               -file $resultsDir/3_clocks.rpt
report_clock_utilization                    -file $resultsDir/3_clock_utilization.rpt
report_clock_networks         -levels 2     -file $resultsDir/3_clock_utilization.rpt
report_utilization                          -file $resultsDir/3_device_utilization.rpt
report_power                                -file $resultsDir/3_power_utilization.rpt
report_io                                   -file $resultsDir/3_io_information.rpt
report_drc                    -verbose      -file $resultsDir/3_drc_report.rpt
report_synchronizer_mtbf      -verbose      -file $resultsDir/3_mtbf_information.rpt

# Output the Simulation Netlist and final constraints for the whole design
write_verilog                 -force        -file $resultsDir/3_netlist.v
write_xdc  -no_fixed_only     -force        -file $resultsDir/3_final_constraints.xdc

# Build Step 4) Generate the Bitfile and PROM file
write_bitstream -force $resultsDir/$bitfileName.bit
write_cfgmem \
  -format mcs \
  -size 128 \
  -interface BPIx16 \
  -loadbit "up 0x00000000 $resultsDir/$bitfileName.bit" \
  -force -file $resultsDir/$bitfileName.mcs

write_debug_probe -verbose $resultsDir/$bitfileName.ltx
