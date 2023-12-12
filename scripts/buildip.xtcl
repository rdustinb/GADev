# Building Vivado IP from just the XCI files.

# Step 1) Define the Part
set_part xc7vx485tffg1761-2

# Step 2) Read in the IP .xci files
read_ip ./ip/xilinx/my_ip/my_ip.xci

# Step 3) Synthesize the IP (this generates the DCP files)
synth_ip [get_ips my_ip]

# Step 4) Generate all Output Products
generate_target all [get_ips my_ip]

# Step 5) Open the Example Design (not all IP has one, so this command would fail)
open_example_project -dir ./ip/xilinx.gen/ -force [get_ips my_ip]

