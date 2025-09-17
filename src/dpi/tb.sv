`timescale 1ns / 1ps

module tb;

  // Parameters

  // New Types

  // Signals

  // Clocks and Resets

  // Assignments

  // Processes

  // Instances

  // DPI header import
  import "DPI-C" function int add(int a, int b);

  // Tasks
  `include "support.svh"

  // Simulation
  initial begin : SIM
    startSim();

    #20ns;

    $display("Calling the c function add(2,3) results in %d", add(2, 3));

    #20ns;

    finishSim();
  end

endmodule
