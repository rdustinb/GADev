/*
File     : pfunc.sv
Designer : Dustin Brothers <github.com/rdustinb>
Date     : April 28, 2011
Abstract : Performs a simple bit-level transposition
         of all 32-bits after combination of the 
         f(R,K) function.

-----------------------------------------------------
Description    :
   This function is very simple and similar to the 
Initial Permutation in that it just remaps the 32-bit
field order.

ToDo           :
   Complete logic 
   Simulate and verify 

Known Issues   :

-----------------------------------------------------
Development Log
-----------------------------------------------------
Date        Init     Description
-----------------------------------------------------
04/23/11    DB       Initial Design
-----------------------------------------------------
*/

`timescale 1ns/100ps

module sfunc(
   input [31:0]      din,
   output [31:0]     dout
   );

// Permutation Function
assign dout = {
   din[24],din[3],din[10],din[21],
   din[5],din[29],din[12],din[18],
   din[8],din[2],din[26],din[31],
   din[13],din[23],din[7],din[1],
   din[9],din[30],din[17],din[4],
   din[25],din[22],din[14],din[0],
   din[16],din[27],din[11],din[28],
   din[20],din[19],din[6],din[15]
   };

endmodule
