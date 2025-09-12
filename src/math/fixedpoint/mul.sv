`timescale 1ns / 1ps

module mul #(
    parameter integer wholeWidth = 16,
    parameter integer fractionWidth = 16
  )(
    input clock,
    input calculate_en,
    input [((wholeWidth+fractionWidth)-1):0] valueOne,
    input [((wholeWidth+fractionWidth)-1):0] valueTwo,
    output logic[((wholeWidth+fractionWidth)-1):0] product
  );

  // Fixed Point
  // The separation between the whole and fractional parts of the number determines the range and/or precision of the
  // final number.
  //
  // 32 - sign
  //
  // 31:20 - whole (+/-2**12)
  // 19:0 - fraction (1/(2**20) precision)
  //
  // 31:16 - whole (+/-2**16)
  // 15:0 - fraction (1/(2**16) precision)

  // The original fraction bit vector:
  //    fractionWidth . . . . . . 0
  // Becomes:
  //    2*fractionWidth . . . . . fractionWidth . . . . . . 0
  // 
  // Offsetting the original bit vector, up by a bit count of the entire bit width.
  //
  // Example:
  // .b0001 * .b1001
  // Results in the partial multiples:
  //
  // .b0 0001000 # Shift by 1 due to .b1xxx
  // .b0000 0001 # Shift by 4 due to .bxxx1
  //
  // Note how the fractional bit width doubles the needed precision.

  wire [2*fractionWidth-1:0] upshiftFraction;
  logic [2*fractionWidth-1:0] newFractionSegments [0:(fractionWidth-1)];
  logic [2*fractionWidth-1:0] newFraction;

  // Store the original valueOne fractional part as a fractionWidth-left-shifted value to add more precision to the
  // temporary fractional part
  assign upshiftFraction = {valueOne[0+:fractionWidth], {fractionWidth{1'b0}} };

  always@(*) begin : NEW_FRACTIONAL_SEGMENT
    for(int thisBit=(fractionWidth-1); thisBit>=0; thisBit--) begin
      if(valueTwo[thisBit] == 1'b1) begin
        // Take the original valueOne fractional part that was upshifted by fractionWidth bits, and right-shift the
        // value for every bit that is 1 in the valueTwo fractional part.
        newFractionSegments[thisBit] = upshiftFraction>>(fractionWidth - thisBit);
      end else begin
        newFractionSegments[thisBit] = 'h0;
      end
    end
  end

  always@(*) begin : NEW_FRACTION
    for(int thisFractionSegment=0; thisFractionSegment<fractionWidth; thisFractionSegment++) begin : DEBUG
      // Blocking assignments force the summation of all segments from 0 to fractionWidth
      if(thisFractionSegment == 0) begin
        newFraction = newFractionSegments[thisFractionSegment];
      end
      if(thisFractionSegment != 0) begin
        newFraction = newFractionSegments[thisFractionSegment] + newFraction;
      end
    end
  end

  always@(posedge clock) begin : MULTIPLIER
    if(calculate_en == 1'b1) begin
      product [fractionWidth+:wholeWidth] <= valueOne[fractionWidth+:wholeWidth] * valueTwo[fractionWidth+:wholeWidth];
      // Only the upper-bits of the newFraction are passed on, functionally demonstrating that the precision is reduced
      // when two fixed point numbers are multiplied together...
      product [0+:fractionWidth] = newFraction[fractionWidth+:fractionWidth];
    end
  end

  always@(posedge clock) begin : DEBUG
    if(calculate_en == 1'b1) begin
      $display("");
      $display("Whole value 1 is 0x%04x", valueOne[fractionWidth+:wholeWidth]);
      $display("Fraction value 1 is 0x%04x", valueOne[0+:fractionWidth]);
      $display("Whole value 2 is 0x%04x", valueTwo[fractionWidth+:wholeWidth]);
      $display("Fraction value 2 is 0x%04x", valueTwo[0+:fractionWidth]);

      $display("");
      for(int thisBit=0; thisBit<fractionWidth; thisBit++) begin : DEBUG
        $display("newFractionSegments shift %d has value 0x%08x", thisBit, newFractionSegments[thisBit]);
      end

      $display("");
      $display("newFraction has value 0x%08x", newFraction);
    end
  end

endmodule
