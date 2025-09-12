`timescale 1ns / 1ps

module tb;

  // Parameters
  parameter wholeWidth = 16;
  parameter fractionWidth = 16;

  // New Types

  // Signals
  logic clock;
  logic calculate_en;

  logic[(wholeWidth+fractionWidth)-1:0] valueOne;
  logic[(wholeWidth+fractionWidth)-1:0] valueTwo;

  logic[(wholeWidth+fractionWidth)-1:0] addend;
  logic[(wholeWidth+fractionWidth)-1:0] difference;
  logic[(wholeWidth+fractionWidth)-1:0] product;

  // Clocks and Resets
  initial begin
    clock = 1'b0;
    forever
      #(1ns / 2) clock = ~clock;
  end

  // Assignments

  // Processes

  // Instances
  add #(
    .wholeWidth (wholeWidth),
    .fractionWidth (fractionWidth)
  ) Iadd (
    .clock (clock),
    .calculate_en (calculate_en),
    .valueOne (valueOne),
    .valueTwo (valueTwo),
    .addend (addend)
  );

  sub #(
    .wholeWidth (wholeWidth),
    .fractionWidth (fractionWidth)
  ) Isub (
    .clock (clock),
    .calculate_en (calculate_en),
    .valueOne (valueOne),
    .valueTwo (valueTwo),
    .difference (difference)
  );

  mul #(
    .wholeWidth (wholeWidth),
    .fractionWidth (fractionWidth)
  ) Imul (
    .clock (clock),
    .calculate_en (calculate_en),
    .valueOne (valueOne),
    .valueTwo (valueTwo),
    .product (product)
  );

  // Tasks

  // Floating Point
  // See IEEE754
  //
  // The binary structure is:
  // 32 - sign
  // 31:24 - exponent
  // 23:0 - mantissa
  //
  // The precision of the fraction depends on the whole number being stored. Every time the whole number consumes more
  // bits (2**n) a bit of precision of the fraction is removed. The boundaries are:
  //
  // -1.9999999 to 1.9999999 (0.0000001 precision)
  // -3.9999998 to 3.9999998 (0.0000002 precision)
  // -4.9999996 to 4.9999996 (0.0000004 precision)
  // -7.9999995 to 4.9999995 (0.0000004 precision)

  // Simulation
  initial begin
    calculate_en = 1'b0;
    valueOne = 'h0;
    valueTwo = 'h0;

    #20ns;

    // Run Calculations
    @(negedge clock);
    calculate_en = 1'b1;
    // h0001.h0001
    valueOne[fractionWidth+:wholeWidth] = 'd3;
    valueOne[0+:fractionWidth] = 'd1137;
    // h0001.h0001
    valueTwo[fractionWidth+:wholeWidth] = 'd16;
    valueTwo[0+:fractionWidth] = 'd4173;
    @(negedge clock);
    calculate_en = 1'b0;

    $display("");
    //$display("0x%08h + 0x%08h = 0x%08h", valueOne, valueTwo, addend);
    //$display("0x%08h - 0x%08h = 0x%08h", valueOne, valueTwo, difference);
    $display("0x%08h * 0x%08h = 0x%08h", valueOne, valueTwo, product);
    $display("%d.%05d * %d.%05d = %d.%05d", 
      valueOne[fractionWidth+:wholeWidth], 
      valueOne[0+:fractionWidth], 
      valueTwo[fractionWidth+:wholeWidth], 
      valueTwo[0+:fractionWidth],
      product[fractionWidth+:wholeWidth], 
      product[0+:fractionWidth]
    );

    #20ns;

    $display("");
    $display("---------------------------------");
    $display("           SIM COMPLETE!");
    $display("---------------------------------");
    $display("");
    $finish;
  end

endmodule
