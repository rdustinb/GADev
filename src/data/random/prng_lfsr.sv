`timescale 1ns / 1ps

// Local Parameters
parameter int MAXSYMBOLWIDTH = 128;

module prng_lfsr (
    input clock,
    input resetn,
  
    input load_mode,
    input [$clog2(MAXSYMBOLWIDTH):0] mode,
    input enable,
    output valid,
    output lfsr
  );

  // New Types
  typedef enum logic[$clog2(MAXSYMBOLWIDTH):0] {
    LFSR8 = 'd8,
    LFSR16 = 'd16,
    LFSR20 = 'd20,
    LFSR32 = 'd32,
    LFSR40 = 'd40,
    LFSR52 = 'd52,
    LFSR64 = 'd64,
    LFSR80 = 'd80,
    LFSR96 = 'd96,
    LFSR128 = 'd128
  } mode_t;

  // Signals
  logic load_mode_r;
  mode_t mode_r;
  int mode_idx;
  logic enable_r;
  logic feedback;
  logic [MAXSYMBOLWIDTH-1:0] lfsr_bus;
  logic lfsr_r;
  logic valid_r;

  // Pipeline the Inputs
  always@(posedge clock) begin : CONTROL_SEQ
    // Gated Loading
    if(load_mode == 1'b1) begin
      mode_r <= mode_t'(mode);
    end
    // Pipeline Only
    load_mode_r <= load_mode;
    enable_r <= enable;
  end

  // Define the Polynomial Feedback Path
  always@(*) begin : FEEDBACK_POLYNOMIAL_COMB
    case(mode_r)
      // XNOR Feedback
      LFSR8   : feedback = !(lfsr_bus[  7] ^ lfsr_bus[  5] ^ lfsr_bus[  4] ^ lfsr_bus[  3]);
      LFSR16  : feedback = !(lfsr_bus[ 15] ^ lfsr_bus[ 14] ^ lfsr_bus[ 12] ^ lfsr_bus[  3]);
      LFSR20  : feedback = !(lfsr_bus[ 19] ^ lfsr_bus[ 16]);
      LFSR32  : feedback = !(lfsr_bus[ 31] ^ lfsr_bus[ 21] ^ lfsr_bus[  1] ^ lfsr_bus[  0]);
      LFSR40  : feedback = !(lfsr_bus[ 39] ^ lfsr_bus[ 37] ^ lfsr_bus[ 20] ^ lfsr_bus[ 18]);
      LFSR52  : feedback = !(lfsr_bus[ 51] ^ lfsr_bus[ 48]);
      LFSR64  : feedback = !(lfsr_bus[ 63] ^ lfsr_bus[ 62] ^ lfsr_bus[ 60] ^ lfsr_bus[ 59]);
      LFSR80  : feedback = !(lfsr_bus[ 79] ^ lfsr_bus[ 78] ^ lfsr_bus[ 42] ^ lfsr_bus[ 41]);
      LFSR96  : feedback = !(lfsr_bus[ 95] ^ lfsr_bus[ 93] ^ lfsr_bus[ 48] ^ lfsr_bus[ 46]);
      LFSR128 : feedback = !(lfsr_bus[127] ^ lfsr_bus[125] ^ lfsr_bus[100] ^ lfsr_bus[ 98]);
      // Default is LFSR 32Bit
      default : feedback = !(lfsr_bus[ 31] ^ lfsr_bus[ 21] ^ lfsr_bus[  1] ^ lfsr_bus[  0]);
    endcase
  end

  // Bit Indexer
  always@(*) begin : BIT_INDEX_COMB
    mode_idx = int'(mode_r) - 1;
  end

  // Fundamental LFSR Array
  always@(posedge clock) begin : LFSR_SEQ
    if(resetn === 1'b0 || load_mode_r === 1'b1 || enable_r == 1'b0) begin
      lfsr_bus <= 'h0;
    end else begin
      // Always shift left the entire bus, the output tap changes based on mode
      lfsr_bus <= {lfsr_bus[0+:MAXSYMBOLWIDTH-1], feedback};
    end
  end

  // Drive out the Valid flag
  always@(posedge clock) begin : VALID_SEQ
    if(enable_r === 1'b1) begin
      valid_r <= 1'b1;
    end else begin
      valid_r <= 1'b0;
    end
  end

  // Drive out the LFSR bit based on mode
  always@(posedge clock) begin : LFSR_OUT_MUX
    lfsr_r <= lfsr_bus[int'(mode_r) - 1] & enable_r;
  end

  // Output Assignment
  assign valid = valid_r;
  assign lfsr = lfsr_r;

endmodule
