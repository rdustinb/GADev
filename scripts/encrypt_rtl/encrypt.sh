encryptOutDir="out"

# QuestaSim RTL Encryption needs headers with slightly different syntax...

# vencrypt and vhencrypt come installed with the QuestaSim tool.

################################
# Verilog File Encryption
################################
vencrypt -h=header.v -d ${encryptOutDir} file.v

################################
# VHDL File Encryption
################################
vhencrypt -h=header.vhd -d ${encryptOutDir} file.vhd
