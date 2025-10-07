module four (
  input clock,
  input reset,
  output [7:0] data,
  output valid
);

  `include "includes2_1.svh"

  logic [$clog2(`DLY_FOUR):0] counter;
  logic [$left(data):0] data_q;
  logic valid_q;

  always@(posedge clock) begin : COUNTER_PROC
    if(reset == 1'b1) begin
      counter <= `DLY_FOUR;
    end else begin
      if(counter == 'h0) begin
        counter <= `DLY_FOUR;
      end else begin
        counter <= counter - 1;
      end
    end
  end

  // Instances
  logic [$left(data):0] data_i [1:3];
  logic valid_i [1:3];

  one Ione (
    .clock  (clock),
    .reset  (reset),
    .data   (data_i[1]),
    .valid  (valid_i[1])
  );

  two Itwo (
    .clock  (clock),
    .reset  (reset),
    .data   (data_i[2]),
    .valid  (valid_i[2])
  );

  three Ithree (
    .clock  (clock),
    .reset  (reset),
    .data   (data_i[3]),
    .valid  (valid_i[3])
  );

  // MUX the outputs
  logic [$left(data):0] data_q;
  logic valid_q;

  always@(posedge clock) begin : MUX_PROC
    case(counter)
      if(counter > `MUX_FOUR_ONE) begin
        valid_q <= valid_i[1];
        data_q <= data_i[1];
      end
      else if(counter > `MUX_FOUR_TWO) begin
        valid_q <= valid_i[2];
        data_q <= data_i[2];
      end
      else if(counter > `MUX_FOUR_THREE) begin
        valid_q <= valid_i[3];
        data_q <= data_i[3];
      end
    endcase
  end

  // Output Assignments
  assign valid = valid_q;
  assign data = data_q;

endmodule
