/*
File     : pc2.sv
Designer : Dustin Brothers <github.com/rdustinb>
Date     : April 30, 2011
Abstract : Initial Permutation Choice for key
         expansion.

-----------------------------------------------------
Description    :
   This operation is the key schedule "key combine"
function to use during key expansion.

Note: Each key used during encryption/ decryption
is a 48-bit key schedule.

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

module pc2(
   input [28:0]   c,             // 28-bit C in
   input [28:0]   d,             // 28-bit D in
   output [47:0]  keyS           // 47-bit Key Scheduled out
   );

// Internals
wire [63:0] comb;

assign comb = {c,d};

// Combine the key, permutation choice 2
// FIPS46-3 page 25
assign keyS = {
   comb[31],comb[28],comb[35],comb[49],comb[41],comb[45],
   comb[52],comb[33],comb[55],comb[38],comb[48],comb[43],
   comb[47],comb[32],comb[44],comb[50],comb[39],comb[29],
   comb[54],comb[46],comb[36],comb[30],comb[51],comb[40],
   comb[1], comb[12],comb[19],comb[26],comb[6], comb[15],
   comb[7], comb[25],comb[3], comb[11],comb[18],comb[22],
   comb[9], comb[20],comb[5], comb[14],comb[27],comb[2],
   comb[4], comb[0], comb[23],comb[10],comb[16],comb[13]
   };

endmodule
