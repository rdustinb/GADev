// The core of the function is this, get the smallest
// number of valid bits that are needed to have the
// number of SET valid bits equal to the number of
// bytes available input value.

module mask_data #(
    parameter BUSBYTEWIDTH              = 16,
    parameter BYTESAVAIL                = 16
  )(
    input                               clk,
    input                               reset,
    input   [($clog2(BYTESAVAIL)-1):0]  bytesavailin,
    input                               businvld,
    input   [(BUSBYTEWIDTH-1):0]        businkeep,
    input   [(BUSBYTEWIDTH*8-1):0]      busin,
    output                              busoutvld,
    output  [(BUSBYTEWIDTH-1):0]        busoutkeep,
    output  [(BUSBYTEWIDTH*8-1):0]      busout
  );

  logic                             businvld_r;
  logic [(BUSBYTEWIDTH-1):0]        businkeep_r;
  logic [(BUSBYTEWIDTH*8-1):0]      busin_r;
  logic [($clog2(BYTESAVAIL)-1):0]  bytesavailin_r;
  logic                             businvld_rr;
  logic [(BUSBYTEWIDTH-1):0]        businkeep_rr;
  logic [(BUSBYTEWIDTH*8-1):0]      busin_rr;
  logic [($clog2(BYTESAVAIL)-1):0]  counts_of_vld_set;
  logic [($clog2(BYTESAVAIL)-1):0]  counts_of_vld_set_r;
  logic [($clog2(BYTESAVAIL)-1):0]  keepbitcountactive;
  logic [($clog2(BYTESAVAIL)-1):0]  keepbitcountactive_r;

  // Input Pipeline
  always@(posedge clk) begin : Input_Pipeline
    businvld_r            <= businvld;
    businkeep_r           <= businkeep;
    busin_r               <= busin;
    bytesavailin_r        <= byteavailin;
  end

  // Combinatorial Cloud 1
  always@(*) begin : Comb_Cloud_1
    // counts index of bit counts only
    // meaning to store the counts of all set bits
    // looking at only bit 1, then bits 1,2, then bits
    // 1,2,3, etc. This is a combinatorial cloud.
    for(int i=0; i<BUSBYTEWIDTH; i++) begin
      // Cout set bits in *i* number of valid bits
      // Number of valid bits index
      for(int j=0; j<(i+1); j++) begin
        if(j == 0) begin
          counts_of_vld_set[i] <= 0 + businkeep_r[j];
        end
        else begin
          counts_of_vld_set[i] <= counts_of_vld_set[i] + businkeep_r[j];
        end
      end
    end
  end

  // Pipeline 1
  always@(posedge clk) begin : Pipeline_1
    // Match the input bus pipeline
    businkeep_rr          <= businkeep_r;
    businvld_rr           <= businvld_r;
    busin_rr              <= busin_r;
    bytesavailin_rr       <= byteavailin_r;
    // Register the count results
    counts_of_vld_set_r   <= counts_of_vld_set;
  end

  // Combinatorial Cloud 2
  always@(*) begin : Comb_Cloud_2
    // This logic block finds the number of keep bits
    // necessary to equal the count of available bytes
    // This is a needed step as the number of keep bits
    // does not necessarily equal the number of available
    // bytes of storage.
    for(int i=0; i<BUSBYTEWIDTH; i++) begin
      if(counts_of_vld_set_r[i] == bytesavailin_rr) begin
        keepbitcountactive <= '(i);
      end
    end
  end

  // Pipeline 2
  always@(posedge clk) begin : Pipeline_2
    // Match the input bus pipeline
    businkeep_rrr         <= businkeep_rr;
    businvld_rrr          <= businvld_rr;
    busin_rrr             <= busin_rr;
    bytesavailin_rrr      <= byteavailin_rr;
    // Register the active-inactive boundary
    keepbitcountactive_r  <= keepbitcountactive;
  end

  // Combinatorial Cloud 3
  always@(*) begin : Comb_Cloud_3
    // This block decodes the two corner cases of the bytes available
    // of storage: no available storage, so simply flag all data
    // bytes as no-keep. More available storage than bytes flagged
    // as keep, in this case the value from cloud 2 above will be 0.
    // The last decode is using the value from cloud 2 above as a
    // boundary index for for which of the bits of businkeep to use
    // vs. throwing away the others.
    if(bytesavailin_rrr == 'h0) begin
      busoutkeep_y <= 'h0;
    end
    else if(keepbitcountactive_r == 0) begin
      busoutkeep_y <= businkeep_rrr;
    end
    else begin
      busoutkeep_y <= 'h0;
      busoutkeep_y[0+:keepbitcountactive_r] <= 
        businkeep_rrr[0+:keepbitcountactive_r];
    end

    // Tie up the other output busses
    busoutvld_y <= businvld_rrr;
    busout_y <= busin_rrr;
  end

  // Output Pipeline
  always@(posedge clk) begin : Output_Pipeline
    busoutvld_r   <= busoutvld_y;
    busoutkeep_r  <= busoutkeep_y;
    busout_r      <= busout_y;
  end

endmodule
