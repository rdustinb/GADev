`timescale 1ns / 1ps

module tb;

  `include "support.svh"

  parameter logic[31:0] MEMINITWORD = 32'hFFFFFFFF;

  // Define the dynamic array
  logic [31:0] wholeMem [0:65535];

  // Built in tasks
  task readMemFile;
    // Read in the whole memory file
    $readmemh("example.mem", wholeMem);
  endtask

  task printMemData;

    int offset = 'h0;
    int length = 8;

    // Print at a boundary
    $display("@%x", offset);
    for(int idx=offset; idx<(offset+(length/2)); idx++) begin
      $display("index %x: %x", idx, wholeMem[idx]);
    end

    offset = 'h1000;
    length = 8;

    // Print at a boundary
    $display("@%x", offset);
    for(int idx=(offset-(length/2)); idx<(offset+(length/2)); idx++) begin
      $display("index %x: %x", idx, wholeMem[idx]);
    end

  endtask

  // Simulation stimulus
  initial begin : mainSim
    startSim();
    fork
      // Add different forks here...
      begin : simFork0
        #1ns;
        initMem(MEMINITWORD);
        readMemFile();
        printMemData();
        #1ns;
      end
    join
    $finish;
    finishSim();
  end

endmodule
