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

  wire [2*fractionWidth-1:0] upshiftFraction;
  logic [2*fractionWidth-1:0] newFraction [0:(fractionWidth-1)];

  // Pre shift the valueOne fraction into the upper set of bits of so the newFraction signal can right-shift them
  // based on the bits in valueTwo
  assign upshiftFraction = {valueOne[0+:fractionWidth], {fractionWidth{1'b0}} };

  always@(*) begin
    for(int thisBit=(fractionWidth-1); thisBit>=0; thisBit--) begin
      if(valueTwo[thisBit] == 1'b1) begin
        newFraction[thisBit] = upshiftFraction>>(fractionWidth - thisBit);
      end else begin
        newFraction[thisBit] = 'h0;
      end
    end
  end

  //always@(negedge clock) begin : DEBUG
  //  if(calculate_en == 1'b1) begin
  //    for(int thisBit=0; thisBit<fractionWidth; thisBit++) begin
  //      $display("newFraction shift %d has value 0x%08x", thisBit, newFraction[thisBit]);
  //    end
  //  end
  //end

  always@(posedge clock) begin : MULTIPLIER
    if(calculate_en == 1'b1) begin
      $display("Whole value 1 is 0x%04x", valueOne[fractionWidth+:wholeWidth]);
      $display("Fraction value 1 is 0x%04x", valueOne[0+:fractionWidth]);
      $display("Whole value 2 is 0x%04x", valueTwo[fractionWidth+:wholeWidth]);
      $display("Fraction value 2 is 0x%04x", valueTwo[0+:fractionWidth]);

      product [fractionWidth+:wholeWidth] <= valueOne[fractionWidth+:wholeWidth] * valueTwo[fractionWidth+:wholeWidth];

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

      for(int thisBit=0; thisBit<fractionWidth; thisBit++) begin : DEBUG
        $display("newFraction shift %d has value 0x%08x", thisBit, newFraction[thisBit]);
      end

      //for(int thisPartial=fractionWidth; thisPartial<(2*fractionWidth); thisBit++) begin
      //  product [0+:fractionWidth] = newFraction[thisPartial][fractionWidth+:fractionWidth];
      //end
    end
  end

endmodule
