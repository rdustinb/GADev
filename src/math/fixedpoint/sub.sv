`timescale 1ns / 1ps

module sub #(
    parameter integer wholeWidth = 1,
    parameter integer fractionWidth = 1
  )(
    input clock,
    input logic calculate_en,
    input logic[((wholeWidth+fractionWidth)-1):0] valueOne,
    input logic[((wholeWidth+fractionWidth)-1):0] valueTwo,
    output logic[((wholeWidth+fractionWidth)-1):0] difference
  );

  always@(posedge clock) begin : SUBTRACTOR
    if(calculate_en == 1'b1) begin
      difference[fractionWidth+:wholeWidth] <= valueOne[fractionWidth+:wholeWidth] - valueTwo[fractionWidth+:wholeWidth];
      difference[0+:fractionWidth] <= valueOne[0+:fractionWidth] - valueTwo[0+:fractionWidth];
    end
  end

endmodule
