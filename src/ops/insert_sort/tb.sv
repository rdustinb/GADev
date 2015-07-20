`timescale 100 ns / 10 ns

module tb;

// Clock and Reset
initial begin
    clk <= 1'b0;
  forever
    #10ns clk <= ~clk;
end
initial begin
  rst <= 1'b0;
  #500ns
  rst <= 1'b0;
end

// Instance

endmodule
