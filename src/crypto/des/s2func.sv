/*
File     : s2func.sv
Designer : Dustin Brothers <github.com/rdustinb>
Date     : April 30, 2011
Abstract : This is a sub function that takes 6-bit
         input and performs a "lookup" to a known
         DES table to generate a 4-bit output.

-----------------------------------------------------
Description    :
   There are eight similar operations like this one 
that operate within the f(R,K) function dependent on
"location" within the internal data state.
   This operation uses the MSb:LSb as a 2-bit address
for the rows of the lookup table. The 4 center-bits
of the 6-bit input makeup the columns of the lookup 
table.

As this is the second of two operations of the 
   f(R,K)
function, we will register it to provide the necessary
timing for the FPGA. At this point there are 4-5 gates
deep.

      din -> {LOGIC} -> stran -> {REG} -> dout

ToDo           :
   Complete logic 
   Simulate and verify 

Known Issues   :

-----------------------------------------------------
Development Log
-----------------------------------------------------
Date        Init     Description
-----------------------------------------------------
04/30/11    DB       Initial Design
-----------------------------------------------------
*/

`timescale 1ns/100ps

module s2func(
   input             clk,
   input             reset,
   input [5:0]       din,
   output reg [3:0]  dout
   );

// Internals
reg [3:0] stran;

// Register It Out
always@(posedge clk)
begin
   if( ~reset )                  // Active Low Reset, Synchronous
      dout <= 4'b0;
   else
      dout <= stran;
end

// Combinatorial Lookup Mapping
always@(din)
begin
   case(din)
      6'h00 : stran <= 4'hf;
      6'h01 : stran <= 4'h3;
      6'h02 : stran <= 4'h1;
      6'h03 : stran <= 4'hd;
      6'h04 : stran <= 4'h8;
      6'h05 : stran <= 4'h4;
      6'h06 : stran <= 4'he;
      6'h07 : stran <= 4'h7;
      6'h08 : stran <= 4'h6;
      6'h09 : stran <= 4'hf;
      6'h0a : stran <= 4'hb;
      6'h0b : stran <= 4'h2;
      6'h0c : stran <= 4'h3;
      6'h0d : stran <= 4'h8;
      6'h0e : stran <= 4'h4;
      6'h0f : stran <= 4'he;
      6'h10 : stran <= 4'h9;
      6'h11 : stran <= 4'hc;
      6'h12 : stran <= 4'h7;
      6'h13 : stran <= 4'h0;
      6'h14 : stran <= 4'h2;
      6'h15 : stran <= 4'h1;
      6'h16 : stran <= 4'hd;
      6'h17 : stran <= 4'ha;
      6'h18 : stran <= 4'hc;
      6'h19 : stran <= 4'h6;
      6'h1a : stran <= 4'h0;
      6'h1b : stran <= 4'h9;
      6'h1c : stran <= 4'h5;
      6'h1d : stran <= 4'hb;
      6'h1e : stran <= 4'ha;
      6'h1f : stran <= 4'h5;
      6'h20 : stran <= 4'h0;
      6'h21 : stran <= 4'hd;
      6'h22 : stran <= 4'he;
      6'h23 : stran <= 4'h8;
      6'h24 : stran <= 4'h7;
      6'h25 : stran <= 4'ha;
      6'h26 : stran <= 4'hb;
      6'h27 : stran <= 4'h1;
      6'h28 : stran <= 4'ha;
      6'h29 : stran <= 4'h3;
      6'h2a : stran <= 4'h4;
      6'h2b : stran <= 4'hf;
      6'h2c : stran <= 4'hd;
      6'h2d : stran <= 4'h4;
      6'h2e : stran <= 4'h1;
      6'h2f : stran <= 4'h2;
      6'h30 : stran <= 4'h5;
      6'h31 : stran <= 4'hb;
      6'h32 : stran <= 4'h8;
      6'h33 : stran <= 4'h6;
      6'h34 : stran <= 4'hc;
      6'h35 : stran <= 4'h7;
      6'h36 : stran <= 4'h6;
      6'h37 : stran <= 4'hc;
      6'h38 : stran <= 4'h9;
      6'h39 : stran <= 4'h0;
      6'h3a : stran <= 4'h3;
      6'h3b : stran <= 4'h5;
      6'h3c : stran <= 4'h2;
      6'h3d : stran <= 4'he;
      6'h3e : stran <= 4'hf;
      6'h3f : stran <= 4'h9;
      default  : stran <= 4'h0;   // Catch bad cases
   endcase
end

endmodule
