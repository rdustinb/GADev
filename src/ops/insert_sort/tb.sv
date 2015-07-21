`timescale 100 ns / 10 ns

// Parameters
localparam VALCOUNT = 16;
localparam VALBIT = 32;

// Random Value Class
class rand_val;
  rand logic [VALBIT-1:0] value;
endclass

// Simulation Module
module tb;
  // Signals
  logic clk;
  logic rst;
  logic sortstart;
  logic [(VALCOUNT-1):0][(VALBIT-1):0] values;
  rand_val single_value [(VALCOUNT-1):0];

  // Clock and Reset
  initial begin
      clk <= 1'b0;
    forever
      #10ns clk <= ~clk;
  end
  initial begin
    rst <= 1'b0;
    #500ns
    rst <= 1'b1;
  end

  // Instance
  insert_sort #(
      .RSTPOL             (0),
      .INPUTVALS          (VALCOUNT),
      .INPUTBITWIDTHS     (VALBIT)
    )insert_sort_0(
      .clk                (clk),
      .reset              (rst),
      .sortstart          (sortstart),
      .needs_sorting      (values),
      .sortdone           (),
      .sorted             (),
      .sorted_positions   (),
      .error              ()
    );

  // SIM
  initial begin
    sortstart <= 0;
    #1us;

    // Create a list of random values
    for(int i=0; i<VALCOUNT; i++) begin
      single_value[i] = new();
      single_value[i].randomize();
      // Assign the random value to the array of values
      values[i] = VALBIT'(single_value[i]);
    end
    // Display the values
    for(int i=0; i<VALCOUNT; i++) begin
      $display("0x%x",values[i]);
    end

    @(posedge clk) sortstart <= 1;
    @(posedge clk) sortstart <= 0;
    #1us;
    $finish;
  end

endmodule
