/**********************************************************
  Insertion Sort Algorithm

This is a fairly simple algorithm that utilizes small amounts of logic. Maximum 
time of sorting is n^2 where n is the number of elements to be sorted. 
Typically, for large lists of numbers, O(n^2) is a very high estimate of 
sorting time (in clock cycles). While for very small lists, O(n^2) is the 
typical amount of time that sorting requires.

https://en.m.wikipedia.org/wiki/Insertion_sort

---- Analytics ----
> Medium Memory Writes
> Slow Execution Speed
**********************************************************/

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
  typedef enum logic[2:0] {IDLE,SHIFT,COMPARE} States;
  States sort_fsm;

  // Signals
  logic [$clog2(INPUTVALS):0] current_sort;
  logic [$clog2(INPUTVALS):0] current_position;
  logic [(INPUTVALS-1):0][(INPUTBITWIDTHS-1):0] working_set;
  logic [(INPUTVALS-1):0][(INPUTBITWIDTHS-1):0] sorted_y;
  logic [(INPUTVALS-1):0][$clog2(INPUTVALS):0] positions_y;
  logic sortdone_y;
  logic error_y;

  // Output Assignments
  assign sortdone = sortdone_y;
  assign error = error_y;
  assign sorted = sorted_y;
  assign sorted_positions = positions_y;

  // Core Logic
  always@(posedge clk) begin
    if(reset == RSTPOL) begin
      working_set <= 0;
      sortdone_y <= 0;
      // Generate the Position Array
      for(int i=0; i<INPUTVALS; i++) begin
        positions_y[i] <= i;
      end
      error_y <= 0;
      sort_fsm <= IDLE;
    end
    else begin
      // Defaults
      sortdone_y <= 0;
      error_y <= 0;
      // FSM
      case(sort_fsm)
        IDLE      : begin
          if(sortstart == 1'b1) begin
            // Grab all working data, store internally
            working_set <= needs_sorting;
            // Store position
            positions_y[0] <= 0;
            // Which Element are we Sorting?
            current_sort <= 1;
            // Where is the current values position?
            current_position <= 1;
            // Clear the output registered value
            sorted_y <= 0;
            // Compare First State
            sort_fsm <= COMPARE;
          end
        end
        /********************************************************************
          This Algorithm Works on one value at a time, starting from the
          left-most element, shifting it as needed to the left until the
          original list of values is sorted from lowest (on the left) to the
          highest (on the right).
          In this case the left-most position is array element 0.
        ********************************************************************/
        SHIFT     : begin
          //-----------------------------------------------
          // Shift the current value down
          working_set[current_position-1] <= working_set[current_position];
          // Shift the current position value down
          positions_y[current_position-1] <= positions_y[current_position];

          //-----------------------------------------------
          // Shift the lower value up
          working_set[current_position] <= working_set[current_position-1];
          // Shift the current position value down
          positions_y[current_position] <= positions_y[current_position-1];

          //-----------------------------------------------
          // Change the current position pointer
          current_position <= current_position - 1;

          //-----------------------------------------------
          // Now compare
          sort_fsm <= COMPARE;
        end
        COMPARE   : begin
          //-----------------------------------------------
          // If the current value has shifted to position 0
          //-----------------------------------------------
          if(current_position == 0) begin
            // Increment the current sorted value pointer to the next element
            current_sort <= current_sort + 1;
            // Change the current position pointer for the next sorted value
            // to the current element as it hasn't been moved yet
            current_position <= current_sort + 1;
            // Stay in this state as comparison needs to occur first
            sort_fsm <= COMPARE;
            // If we've sorted all the elements
            if(current_sort == (INPUTVALS-1)) begin
              // Flag the sorting is done
              sortdone_y <= 1'b1;
              // Copy the array to the output registers
              sorted_y <= working_set;
              sort_fsm <= IDLE;
            end
          end
          //----------------------------------------------------------
          // If the current value is in the correct position
          //----------------------------------------------------------
          else if(working_set[current_position] >= working_set[current_position - 1]) begin
            // Increment the current sorted value pointer to the next element
            current_sort <= current_sort + 1;
            // Change the current position pointer for the next sorted value
            // to the current element as it hasn't been moved yet
            current_position <= current_sort + 1;
            // Stay in this state as comparison needs to occur first
            sort_fsm <= COMPARE;
            // If we've sorted all the elements
            if(current_sort == (INPUTVALS-1)) begin
              // Flag the sorting is done
              sortdone_y <= 1'b1;
              // Copy the array to the output registers
              sorted_y <= working_set;
              sort_fsm <= IDLE;
            end
          end
          // If the current value is not in the correct position, shift
          else begin
            sort_fsm <= SHIFT;
          end
        end
        // Catch if the FSM goes into an unknown state
        default     : begin
          working_set <= 0;
          sortdone_y <= 0;
          // Generate the Position Array
          for(int i=0; i<INPUTVALS; i++) begin
            positions_y[i] <= i;
          end
          error_y <= 1;
          sort_fsm <= IDLE;
        end
      endcase
    end
  end

endmodule
