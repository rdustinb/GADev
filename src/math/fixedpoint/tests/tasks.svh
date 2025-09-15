real2hex(3.141592653589793, workingHex);
$display("\ntasks.svh > ");
$display("The Hex fixed point value is: %016h%h", workingHex[fractionWidth+:wholeWidth], workingHex[0+:fractionWidth]);
hex2real(workingHex, workingReal);
$display("\ntasks.svh > ");
$display("The float fixed point value is: %.015f", workingReal);
$display("The original float value is: %.015f", 3.141592653589793);
$display("Conversion error is: %.015f", (3.141592653589793 - workingReal));

