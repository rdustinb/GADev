`timescale 1ns / 1ps

module tb;

  // Parameters
  parameter LOOPTOTAL = 10;

  // New Types

  // Signals
  logic clock;
  logic en_rtl, en_c;
  logic [31:0] rtl_a, rtl_b, rtl_c;
  int a, b, c;

  // Clocks and Resets
  initial begin
    clock = 1'b0;
    forever
      #(500ps) clock = ~clock;
  end

  // Assignments

  // Processes
  always@(posedge clock) begin : RTL_MATH_PROCESS
    if(en_rtl == 1'b1) begin
      rtl_c <= rtl_a + rtl_b;
    end
  end

  always@(posedge clock) begin : C_MATH_PROCESS
    if(en_c == 1'b1) begin
      c <= add(a, b);
    end
  end

  // Instances

  // DPI header import
  import "DPI-C" function int add(int a, int b);
  import "DPI-C" function void genRand_seed();
  import "DPI-C" function int genRand();

  // Tasks
  `include "support.svh"

  // Simulation
  initial begin : SIM
    en_rtl = 1'b0;
    en_c = 1'b0;
    genRand_seed();
    startSim();

    #20ns;

    fork
      //begin : RTL_MATH_STIMULUS
      //  for(int thisRtlLoopIndex=0; thisRtlLoopIndex<LOOPTOTAL; thisRtlLoopIndex++) begin
      //  end
      //end
      begin : C_MATH_STIMULUS
        for(int thisCLoopIndex=0; thisCLoopIndex<LOOPTOTAL; thisCLoopIndex++) begin
          $display("A Random Number: %d", genRand());
        end
      end
    join

    #20ns;

    finishSim();
  end

endmodule
