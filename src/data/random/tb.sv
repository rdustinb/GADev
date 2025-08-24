`timescale 1ns / 1ps

module tb;

  // Local Parameters
  parameter int MAXSYMBOLWIDTH = 128;

  // New Types

  // Signals
  logic clock;
  logic resetn;
  logic load_mode;
  logic [$clog2(MAXSYMBOLWIDTH):0] mode;
  logic enable = 1'b0;
  logic valid;
  logic lfsr;

  int working_mode;

  logic [MAXSYMBOLWIDTH-1:0] working_symbol;

  // Clocks and Resets
  initial begin : RESET
    #10ns;
    $display("tb.RESET> Driving resetn to ACTIVE asynchronously");
    resetn = 1'b0;
    #100ns;
    $display("tb.RESET > Driving resetn to INACTIVE synchronously");
    @(posedge clock);
    resetn = 1'b1;
  end

  initial begin : CLOCK
    #50ns;
    $display("tb.CLOCK > Enabling clock source");
    clock = 1'b0;
    forever
      #5ns clock = ~clock;
  end

  // Instances
  prng_lfsr Iprng_lfsr (
    .clock (clock),
    .resetn (resetn),
    .load_mode (load_mode),
    .mode (mode),
    .enable (enable),
    .valid (valid),
    .lfsr (lfsr)
  );

  // Tasks
  task isQuiet();
    int delayTotal;
    $display("tb.isQuiet() > begin...");

    // This task checks that nothing comes out the lfsr port while enable is 0
    for(int thisBit=0; thisBit<MAXSYMBOLWIDTH; thisBit++) begin
      @(negedge clock);
      if(lfsr !== 1'b0) begin
        $error("tb.isQuiet() > lfsr bit %d out is 0x%h", thisBit, lfsr);
      end
    end

    $display("tb.isQuiet() > ...end");

  endtask

  task loadMode(input int mode_in);
    $display("tb.loadMode() > begin...");
    @(negedge clock);
    mode = 8'(mode_in);
    load_mode = 1'b1;
    $display("tb.loadMode() > mode being loaded %d", mode_in);
    @(negedge clock);
    mode = 'X;
    load_mode = 1'b0;
    $display("tb.loadMode() > ...end");
  endtask

  task enableLfsr();
    $display("tb.enableLfsr() > begin...");
    @(negedge clock);
    enable = 1'b1;
    $display("tb.enableLfsr() > ...end");
  endtask

  task monitorData(input int mode_in);
    logic [MAXSYMBOLWIDTH-1:0] thisValue;

    $display("tb.monitorData() > begin...");

    $display("tb.monitorData() > waiting for valid to gi HI...");
    wait(valid);
    $display("tb.monitorData() > valid is HI, monitoring data...");

    thisValue = '0;
    for(int thisValueIdx=0; thisValueIdx<(2**mode_in); thisValueIdx++) begin
      for(int thisBitIdx=0; thisBitIdx<mode_in; thisBitIdx++) begin
        @(negedge clock);
        if(valid == 1'b1) begin
          thisValue[thisBitIdx] = lfsr;
        end
      end
      $display("tb.monitorData() > value received is 0x%016x", thisValue);
      working_symbol = thisValue;
    end

    $display("tb.monitorData() > ...end");

  endtask

  // Local Stimulus
  initial begin : STIMULUS

    $display("tb.STIMULUS > waiting for resetn to be inactive...");
    wait(resetn);

    isQuiet();

    #1us;

    working_mode = 16;

    fork
      begin : STIMULUS_CONTROL

        loadMode(working_mode);

        #1us;

        enableLfsr();

      end
      begin : STIMULUS_DATAMON

        monitorData(working_mode);

      end

    join

    #1us;

    $display("tb.STIMULUS > simulation DONE!");
    $finish;

  end

  initial begin : VCD_DUMP
    $dumpfile("sim.vcd");
    // TB Signals
    $dumpvars(0, clock);
    $dumpvars(0, resetn);
    $dumpvars(0, load_mode);
    $dumpvars(0, mode);
    $dumpvars(0, enable);
    $dumpvars(0, lfsr);
    $dumpvars(0, working_mode);
    $dumpvars(0, working_symbol);
    // DUT Signals
    $dumpvars(0, Iprng_lfsr.clock);
    $dumpvars(0, Iprng_lfsr.resetn);
    $dumpvars(0, Iprng_lfsr.load_mode_r);
    $dumpvars(0, Iprng_lfsr.mode_r);
    $dumpvars(0, Iprng_lfsr.mode_idx);
    $dumpvars(0, Iprng_lfsr.enable_r);
    $dumpvars(0, Iprng_lfsr.feedback);
    $dumpvars(0, Iprng_lfsr.lfsr_bus);
    $dumpvars(0, Iprng_lfsr.valid_r);
    $dumpvars(0, Iprng_lfsr.lfsr_r);
  end

endmodule
