`timescale 1ns / 1ps

module tb;

  `include "support.svh"

  parameter int MEMDEPTH = 65536;
  parameter logic[31:0] MEMINITWORD = 32'hFFFFFFFF;

  // Define the dynamic array
  logic [31:0] wholeMem [0:(MEMDEPTH-1)];

  // Built in tasks
  task readMemFile;
    // Read in the whole memory file
    $readmemh("example.mem", wholeMem);
  endtask

  task automatic printMemData;
    int length = 8;

    // Offset 0x0000
    int offset = 'h0;

    $display("\n@%x", offset);
    for(int idx=offset; idx<(offset+(length/2)); idx++) begin
      $display("index %x: %x", idx, wholeMem[idx]);
    end

    // Offset 0x0400
    offset = 'h400;

    $display("\n@%x", offset);
    for(int idx=(offset-(length/2)); idx<(offset+(length/2)); idx++) begin
      $display("index %x: %x", idx, wholeMem[idx]);
    end

    // Offset 0x1000
    offset = 'h1000;

    $display("\n@%x", offset);
    for(int idx=(offset-(length/2)); idx<(offset+(length/2)); idx++) begin
      $display("index %x: %x", idx, wholeMem[idx]);
    end

    // Offset 0x1100
    offset = 'h1100;

    $display("\n@%x", offset);
    for(int idx=(offset-(length/2)); idx<(offset+(length/2)); idx++) begin
      $display("index %x: %x", idx, wholeMem[idx]);
    end

    // Offset 0x2000
    offset = 'h2000;

    $display("\n@%x", offset);
    for(int idx=(offset-(length/2)); idx<(offset+(length/2)); idx++) begin
      $display("index %x: %x", idx, wholeMem[idx]);
    end

    // Offset 0x8000
    offset = 'h8000;

    $display("\n@%x", offset);
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
        //initMem(MEMINITWORD);
        readMemFile();
        printMemData();
        #1ns;
      end
    join
    finishSim();
  end

endmodule
