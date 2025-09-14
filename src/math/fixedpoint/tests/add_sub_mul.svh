// Run Calculations
@(negedge clock);
calculate_en = 1'b1;
// h0001.h0001
valueOne[fractionWidth+:wholeWidth] = 'd3;
valueOne[0+:fractionWidth] = 'd1137; // Need to conver this to hex, otherwise the hex fixed point number won't equal what is intended
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

