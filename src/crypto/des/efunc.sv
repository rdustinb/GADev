/*
File     : efunc.sv
Designer : Dustin Brothers <github.com/rdustinb>
Date     : April 23, 2011
Abstract : This function takes 32-bits and expands it
         to 48 bits as required by the DES/3DES cipher
         algorithm.

-----------------------------------------------------
Description    :
   This is an expansion algorithm according to 
FIPS46-3, page 17. It provides the necessary bit 
widening to match the 48 bits of the key schedule to
be used in an operation after this expansion.

Since DES/3DES operates on 64bit blocks of data, and
the operations are split into the upper-32bits and
lower-32bits, this is where this expansion occurs.

This is the first of two main operations of the
      f(R,K)
operation in the DES/3DES cipher.

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

module efunc(
   input [31:0]   din,
   output [47:0]  dout
   );

   // E Bit Mapping/ Expansion
   assign dout = {
    din[0],din[31],din[30],din[29],din[28],din[27],
   din[28],din[27],din[26],din[25],din[24],din[23],
   din[24],din[23],din[22],din[21],din[20],din[19],
   din[20],din[19],din[18],din[17],din[16],din[15],
   din[16],din[15],din[14],din[13],din[12],din[11],
   din[12],din[11],din[10],din[9], din[8], din[7],
    din[8], din[7], din[6], din[5], din[4], din[3],
    din[4], din[3], din[2], din[1], din[0],din[31]
   };

endmodule
