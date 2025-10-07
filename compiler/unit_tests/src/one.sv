module one (
  input clock,
  input reset,
  output [7:0] data,
  output valid
);

  `include "includes1_1.svh"

  logic [$clog2(`DLY_ONE):0] counter;
  logic [$left(data):0] data_q;
  logic valid_q;

  always@(posedge clock) begin : COUNTER_PROC
    if(reset == 1'b1) begin
      counter <= `DLY_ONE;
    end else begin
      if(counter == 'h0) begin
        counter <= `DLY_ONE;
      end else begin
        counter <= counter - 1;
      end
    end
  end

  always@(posedge clock) begin : DATA_PROC
    if(reset == 1'b1) begin
      data_q <= `RESET_ONE;
      valid_q <= 1'b0;
    end else begin
      data_q <= data_q + 1;
      valid_q <= 1'b0;
      if(counter == 'h0) begin
        valid_q <= 1'b1;
      end
    end
  end

  // Output Assignments
  assign valid = valid_q;
  assign data = data_q;

endmodule
