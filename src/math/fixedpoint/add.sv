`timescale 1ns / 1ps

module add #(
    parameter integer wholeWidth = 1,
    parameter integer fractionWidth = 1
  )(
    input clock,
    input logic calculate_en,
    input logic[((wholeWidth+fractionWidth)-1):0] valueOne,
    input logic[((wholeWidth+fractionWidth)-1):0] valueTwo,
    output logic[((wholeWidth+fractionWidth)-1):0] addend
  );

  always@(posedge clock) begin : ADDER
    if(calculate_en == 1'b1) begin
      addend[fractionWidth+:wholeWidth] <= valueOne[fractionWidth+:wholeWidth] + valueTwo[fractionWidth+:wholeWidth];
      addend[0+:fractionWidth] <= valueOne[0+:fractionWidth] + valueTwo[0+:fractionWidth];
    end
  end

endmodule
