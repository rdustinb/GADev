/*
File     : kshift.sv
Designer : Dustin Brothers <github.com/rdustinb>
Date     : April 30, 2011
Abstract : Key shift operation based on a given
         number input to this block.

-----------------------------------------------------
Description    :
   This operation is used as part of the key expansion
algorithm to mix the current state of both the C and
D data values.

If a 0 is applied to the shift port, the left shift
only moves one bit place. If a 1 is applied to the 
shift port, the left shift moves two bit places.

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

module kshift(
   input [27:0]   din,           // 28-bit Data in
   input          shift,         // Shift control
   output [27:0]  dout           // 28-bit Data out
   );

// Shift Left!
assign dout = (shift) ?
   {din[25:0],din[27:26]} :      // If shift == 1, shift two places
   {din[26:0],din[27]} ;         // Else shift one place
   
endmodule
