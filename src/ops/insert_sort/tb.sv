`timescale 100 ns / 10 ns

// DEBUG
localparam DEBUG = 0;

// Parameters
localparam VALCOUNT = 64;
localparam VALBIT = 16;
localparam RSTPOL = 0;

// Simulation Module
module tb;
  // Signals
  logic clk;
  logic rst;
  logic sortstart;
  logic sortdone;
  logic finish_status;
  logic [(VALCOUNT-1):0][(VALBIT-1):0] values;
  logic [(VALCOUNT-1):0][(VALBIT-1):0] sorted_values;
  logic [(VALCOUNT-1):0][$clog2(VALCOUNT):0] sorted_positions;
  logic [VALBIT-1:0] single_value [(VALCOUNT-1):0];

  logic [63:0] clock_counter;
  logic counting;

  logic order_error;

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
      .RSTPOL             (RSTPOL),
      .INPUTVALS          (VALCOUNT),
      .INPUTBITWIDTHS     (VALBIT)
    )insert_sort_0(
      .clk                (clk),
      .reset              (rst),
      .sortstart          (sortstart),
      .needs_sorting      (values),
      .sortdone           (sortdone),
      .sorted             (sorted_values),
      .sorted_positions   (sorted_positions),
      .error              ()
    );

  // Clock Cycle Counter
  always@(posedge clk) begin
    if(rst == RSTPOL) begin
      clock_counter <= 0;
      counting <= 0;
    end
    else begin
      // Flag to count or not count
      if(sortstart) begin
        counting <= 1;
        clock_counter <= 0;
      end
      else if(sortdone) begin
        counting <= 0;
      end
      // Counting
      if(counting == 1) begin
        clock_counter <= clock_counter + 1;
      end
    end
  end

  // SIM
  initial begin
    sortstart <= 0;
    order_error = 0;
    #1us;

    // Print the current time
    $display("System >>>> Current time integer is: %d", $system("date +%N"));

    // Create a list of random values
    for(int i=0; i<VALCOUNT; i++) begin
      single_value[i] = ($urandom_range(0,(2**VALBIT - 1)) + 1) % (2**VALBIT);
      // Assign the random value to the array of values
      values[i] = VALBIT'(single_value[i]);
    end

    @(posedge clk) sortstart <= 1;
    @(posedge clk) sortstart <= 0;

    // Wait for sorting to be complete
    @(posedge sortdone) #1us;

    // Verify they are in order
    for(int i=0; i<VALCOUNT; i++) begin
      if(!(sorted_values[i] <= (sorted_values[i+1]))) begin
        order_error = 1;
      end
    end

    if(DEBUG > 0) begin
      // Display the values
      $display("Original values are:::");
      for(int i=0; i<VALCOUNT; i++) begin
        $display("%d",values[i]);
      end

      // Print out the sorted values
      $display("Sorted values are:::");
      for(int i=0; i<VALCOUNT; i++) begin
        $display("%d",sorted_values[i]);
      end
      // Print out the sorted positions
      $display("Sorted positions are:::");
      for(int i=0; i<VALCOUNT; i++) begin
        $display("%d",sorted_positions[i]);
      end
    end

    $finish;
  end

  // Watchdog
  initial begin
    finish_status = 0;
    #100us;
    finish_status = 1;
    $finish;
  end

  // Final Step
  final begin
    if(finish_status == 1) begin
      $display("Results >>>> Simulation did not complete normally.");
    end
    else begin
      $display("Results >>>> Sorting took %d Clock Cycles", clock_counter);
      if(order_error) begin
        $display("Results >>>> Sorting operation --- FAILED ---");
      end
      else begin
        $display("Results >>>> Sorting operation --- PASSED ---");
      end
      $display("Results >>>> Simulation completed normally.");
    end
  end

endmodule
