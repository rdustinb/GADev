module insert_sort #(
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
  typedef enum logic[3:0] {IDLE,COMPARE,INSERT} States;
  States sort_fsm;

  // Signals
  logic [$clog2(INPUTVALS)-1:0] total_sorted;
  logic [$clog2(INPUTVALS)-1:0] compare_position;
  logic [$clog2(INPUTVALS)-1:0] insert_point;
  logic [(INPUTVALS-1):0][(INPUTBITWIDTHS-1):0] working_set;
  logic [(INPUTVALS-1):0][(INPUTBITWIDTHS-1):0] sorted_y;
  logic [(INPUTVALS-1):0][(INPUTBITWIDTHS-1):0] positions_y;
  logic sortdone_y;
  logic error_y;

  always@(posedge clk) begin
    if(reset == RSTPOL) begin
      working_set <= 0;
      sortdone_y <= 0;
      error_y <= 0;
      sort_fsm <= IDLE;
    end
    else begin
      // Defaults
      sortdone_y <= 0;
      error_y <= 0;
      // FSM
      case(sort_fsm)
        IDLE        : begin
          if(sortstart == 1'b1) begin
            // Grab all working data, store internally
            working_set <= needs_sorting;
            // Push first value into position 0
            sorted_y[0] <= needs_sorting[0];
            // Generate the initial position array
            for(int i =0; i<INPUTVALS; i++) begin
              positions_y[i] <= i;
            end
            // Current Number Sorted is incremented as we have one value in the
            // sorted array
            total_sorted <= 1;
            compare_position <= 0;
            // Compare State
            sort_fsm <= COMPARE;
          end
        end
        COMPARE     : begin
          // If this value is larger than all others in the sorted list
          if(compare_position == total_sorted) begin
            insert_point <= total_sorted;
            sort_fsm <= INSERT;
          end
          // Find the Insertion Point
          else begin
            // If this iteration found the insertion point, flag it
            if((working_set[total_sorted] >= sorted_y[compare_position]) && (working_set[total_sorted] <= sorted_y[compare_position+1])) begin
              sort_fsm <= INSERT;
            end
            // Otherwise Increment the compare point
            else begin
              compare_position <= compare_position + 1;
            end
          end
        end
        INSERT      : begin
          // Insert the new value
          sorted_y[compare_position] <= working_set[total_sorted];
          // Everything Above this position gets shifted up
          for(int i=(compare_position+1); i<INPUTVALS; i++) begin
            sorted_y[i] <= sorted_y[(i-1)];
          end
          // Clear the Compare Positions pointer
          compare_position <= 0;
          // All Sorted
          if(total_sorted == INPUTVALS) begin
            // Flag the Sorted Done bit
            sortdone_y <= 1'b1;
            // Return to IDLE
            sort_fsm <= IDLE;
          end
          else begin
            // Increment the Total Sorted Counter
            total_sorted <= total_sorted + 1;
            // Return to COMPARE
            sort_fsm <= COMPARE;
          end
        end
        // Catch if the FSM goes into an unknown state
        default     : begin
          working_set <= 0;
          sortdone_y <= 0;
          positions_y <= 0;
          error_y <= 1;
          sort_fsm <= IDLE;
        end
      endcase
    end
  end

endmodule
