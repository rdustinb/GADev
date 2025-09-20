set thisProject "ExampleSynplifyProProject"

# Step 1) Create a new project
project -new "${thisProject}"

# Step 2) Add all the implementation options
set_option ...

# Step 3) Add all the files to the project
add_file -vhdl -lib thisLib "path/to/this/file.vhd"
add_file -verilog "path/to/this/file.sv"

# Step 4) Synthesize the Design
synthesize

# Step 5) Save the project
project -save "syn.prj"
