/*
File     : pc1.sv
Designer : Dustin Brothers <github.com/rdustinb>
Date     : April 30, 2011
Abstract : Initial Permutation Choice for key
         expansion.

-----------------------------------------------------
Description    :
   This operation is the initial "key splitting"
function to use during key expansion.

Note that the 'checksum' bits are ignored in the key
expansion, as seen in this module.

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

module pc1(
   input [63:0]   key,           // 64-bit Initial Key in
   output [27:0]  c,             // 28-bit C out
   output [27:0]  d              // 28-bit D out
   );
   
// Split the key, permutation choice 1
// FIPS46-3 page 23
assign c = {
   key[35],key[43],key[51],key[59],key[2],key[10],key[18],
   key[26],key[34],key[42],key[50],key[58],key[1],key[9],
   key[17],key[25],key[33],key[41],key[49],key[57],key[0],
   key[8],key[16],key[24],key[32],key[40],key[48],key[56]
   };

assign d = {
   key[3],key[11],key[19],key[27],key[4],key[12],key[20],
   key[28],key[36],key[44],key[52],key[60],key[5],key[13],
   key[21],key[29],key[37],key[45],key[53],key[61],key[6],
   key[14],key[22],key[30],key[38],key[46],key[54],key[62]
   };

endmodule
