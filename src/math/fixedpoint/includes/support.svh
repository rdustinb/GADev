task automatic real2hex(
  input real thisFloat,
  output[(wholeWidth+fractionWidth)-1:0] thisHex
);
  // The only purpose of this task is for converting starting real numbers to hex.
  // Don't try to store real values in RTL

  real originalFloat = thisFloat;
  int originalWhole = int'(thisFloat);
  real originalFraction = thisFloat-real'(int'(thisFloat));

  int thisFractionTransformInt;
  logic[3:0] thisFractionTransformHex;
  int thisHexFractionDigit = 0;

  $display("\nreal2hex()");

  // Debug (To answer the question: am I stupid or not?)
  $display("Original float: %.016f\nWhole number: %d\nFractional number: %.016f",
    originalFloat,
    originalWhole,
    originalFraction
  );

  // First assign the whole number to the hex field
  thisHex[fractionWidth+:wholeWidth] = wholeWidth'(originalWhole);

  // Now process the fractional part using the following algorithm:
  while(originalFraction != 0 && thisHexFractionDigit < (fractionWidth / 4)) begin
    $display("Loop %d", thisHexFractionDigit);
    $display("Partial fraction value is: %.016f", originalFraction);
    // 1) Multiply by 16
    originalFraction = originalFraction * 16; // In essence, this causes the fraction to "shift-left"
    $display("Partial fraction upscaled real is: %.016f", originalFraction);
    // 2) Take whole number digit, convert to hex
    // Jenky way to get the whole integer of the number of the original real, since casting by default rounds.
    // What this does is converts the number from the original real, to int (where rounding occurs), then back to real
    // and compares it against the original real. If the double-convert is larger than the original real then the
    // rounding occured up as the fractional value was >0.5.
    //
    // Another way to do this is to use $floor() but I wanted to find something that is supported on all simulators.
    //      thisFractionTransformInt = $floor(originalFraction);
    thisFractionTransformInt = int'(originalFraction) - ((originalFraction < real'(int'(originalFraction))) ? 1 : 0);
    $display("Partial fraction upscaled int is: %d", thisFractionTransformInt);
    thisFractionTransformHex = 4'(thisFractionTransformInt);
    // 3) Append to running hex fraction value
    //    This is done with a left-shift of the converted hex value
    thisHex[0+:fractionWidth] = {thisHex[0+:(fractionWidth-4)],thisFractionTransformHex};
    // 4) Goto step 1 if the original fraction value is non-zero
    //  4.1) Subtract the whole number from the originalFraction value which was multiplied by 16
    originalFraction = originalFraction - thisFractionTransformInt;
    //  4.2) Increment the fraction digit position by 1
    thisHexFractionDigit = thisHexFractionDigit + 1;
  end

endtask

task automatic hex2real(
  input[(wholeWidth+fractionWidth)-1:0] thisHex,
  output real thisFloat
);

  logic [(fractionWidth-1):0] originalHexFraction = thisHex[0+:fractionWidth];
  logic [3:0] thisFractionTransformHex;
  real thisFractionTransformFloat;
  real thisFractionFloat;

  $display("\nhex2real()");

  $display("Original hex: %016h", thisHex);
  $display("Original hex fraction: %016h", originalHexFraction);
  
  while(originalHexFraction != 'h0) begin
    // 1) Shift off the uppermost Hex Fraction digit
    thisFractionTransformHex = originalHexFraction[0+:4];
    originalHexFraction = {4'h0,originalHexFraction[4+:(fractionWidth-4)]};
    // 2) Convert to float
    thisFractionTransformFloat = real'(thisFractionTransformHex);
    // 3) Append to the running float fraction, which starts in the whole number digit
    thisFractionFloat = thisFractionFloat + thisFractionTransformFloat;
    // 3) Divide by 16
    thisFractionFloat = thisFractionFloat / 16.0; // In essence, this causes the fraction to "shift-right" out of the whole number digit
    $display("Running converted float fraction is: %.016f", thisFractionFloat);
    // 4) Goto step 1 if the original hex value is non-zero, or the shift count is > hex fraction digit count
  end

  // Assign the whole number to the final float
  thisFloat = real'(thisHex[fractionWidth+:wholeWidth]);
  // Add the fractional float to the final float
  thisFloat = thisFloat + thisFractionFloat;

  $display("Final converted float value: %.016f", thisFloat);

endtask

