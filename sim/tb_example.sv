`timescale 1ns/1ps

module tb;

  // Parameters
  localparam integer CLK_PS = 1000;
  localparam integer CLK_INIT_PS = 500;

  localparam integer RESET_INIT_PS = 250;
  localparam integer RESET_ASSERT_PS = 2000;
  localparam integer RESET_DEASSERT_PS = 20000;

  // Signals
  logic clk_1ns;

  logic clk;
  logic resetf;

  integer WATCHDOG_TIMEOUT_NS = 500;
  logic en_watchdog_timer = 1'b0;
  integer watchdog_timer = WATCHDOG_TIMEOUT_NS;

  // Clocks
  initial begin
    clk_1ns = 1'b0;
    forever
      #500ps clk_1ns = ~clk_1ns;
  end

  initial begin
    #(1ps * CLK_INIT_PS);
    clk = 1'b0;
    forever
      #(1ps * CLK_PS/2) clk = ~clk;
  end

  // Resets
  initial begin
    #(1ps * RESET_INIT_PS);
    resetf = 1'b1;
    #(1ps * RESET_ASSERT_PS);
    resetf = 1'b0;
    #(1ps * RESET_DEASSERT_PS);
    resetf = 1'b1;
  end

  // Instances
  dut #(
    .TOP_PARAM1 (10)
  ) dut_inst (
    .clk        (clk),
    .resetf     (resetf)
  );

  // Tasks
  task fetch_health_status();
    // Do stuff in here to track certain status and health of the design in sim...
  endtask

  // Support Stuff
  always@(posedge clk_1ns or negedge en_watchdog_timer) begin
    // If the Watchdog isn't enabled, reset it and don't decrement...
    if(en_watchdog_timer == 1'b0) begin
      watchdog_timer <= WATCHDOG_TIMEOUT_NS;
    // When the Watchdog is enabled, decrement...
    end else begin
      if(watchdog_timer != 0) begin
        watchdog_timer <= watchdog_timer - 1;
        $display("Watchdog counting down...");
      end
    end
  end

  // Stimulus
  initial begin
    fork
      begin : WATCHDOG_TIMER
        // Sit here forever, until the watchdog expires...
        wait(watchdog_timer == WATCHDOG_TIMEOUT);
        $fatal("Watchdog timeout occurred! Finishing sim!");
      end
      begin : HEALTH_CHECKER
        while(1) begin
          if(en_health_tracker == 1'b1) begin
            #(1ps * HEALTH_TRACKER_UPDATE_PS);
            fetch_health_status();
          end
        end
      end
      begin : STIMULUS_TEST
        // Use a makefile to overwrite a generic-named test.svh with one of many tests...
        `include "test.svh"
      end
    join_any
  end

endmodule
