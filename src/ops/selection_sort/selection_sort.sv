module selection_sort #(
    parameter RSTPOL                                    = 0,
    parameter INPUTVALS                                 = 16,
    parameter INPUTBITWIDTHS                            = 32
  )(
    input                                               clk,
    input                                               reset,
    input                                               sortstart,          // Start the sorting, takes a few clock cycles
    input       [(INPUTVALS-1):0][(INPUTBITWIDTHS-1):0] needs_sorting,      // List of values that needs sorting
    output                                              sortdone,           // Flag goes HI when sorting is done
    output      [(INPUTVALS-1):0][(INPUTBITWIDTHS-1):0] sorted,             // List of input values in ascending order
    output      [(INPUTVALS-1):0][$clog2(INPUTVALS):0]  sorted_positions,   // List of input positions, sorted by their values in ascending order
    output                                              error               // Just throws an error if the FSM goes into an unknown state
  );

  // Control Parameters

  // Enumerations
  typedef enum logic[3:0] {IDLE,MERGE2,MERGE4,MERGE8,MERGE16,MERGE32} States;
  States sort_fsm;

  // Signals
  logic step1, step2, step3, step4, step5, step6, step7;
  logic sortdone_y;
  logic [(INPUTVALS-1):0][(INPUTBITWIDTHS-1):0] working_set;
  logic [(INPUTVALS-1):0][$clog2(INPUTVALS):0] positions_y;
  logic error_y;

  // Output Assignments
  assign sortdone = sortdone_y;
  assign sorted = working_set;
  assign sorted_positions = positions_y;
  assign error = error_y;

endmodule
