/*
File     : cla_64bit.sv
Designer : Dustin Brothers <github.com/rdustinb>
Date     : April 4, 2011
Abstract : Makes up the function of a 64+64 bit
         carry lookahead adder.

-----------------------------------------------------
Description    :
   This module depends on the logic contained in the
   cla_16bit module, whereby utilizing the group
   propagate and generate lines from a single 16-bit
   module. These generate and propagate lines are
   combined in sets of four to produce a CLA 64-bit
   adder.

ToDo           :
   Complete logic.
   Simulate and verify.

Known Issues   :

-----------------------------------------------------
Development Log
-----------------------------------------------------
Date     Init     Description
-----------------------------------------------------

-----------------------------------------------------
*/

`timescale 1ns/100ps

module cla_64bit(
   input [63:0]   din1,                // 64-bit word 1
   input [63:0]   din2,                // 64-bit word 2
   input          cin,                 // Carry in (if necessary)
   output [63:0]  dout,                // 64-bit word out
   output         cout,                // Carry out, 7-gates
   output         pg,                  // 64-bit Group Propagate, 4-gates
   output         gg                   // 64-bit Group Generate, 7-gates
   );

   // Internals
   wire [3:0] prop;
   wire [3:0] gen;
   wire [3:1] carry;

   // Instances
   cla_16bit CLA0(
   .din1(din1[15:0]),
   .din2(din2[15:0]),
   .cin(cin),                          // 5-gates deep, to dout
   .dout(dout[15:0]),                  // 3-gates deep, from din
   .cout(),                            // Don't care
   .pg(prop[0]),                       // 3-gates deep, from din
   .gg(gen[0])                         // 5-gates deep, from din
   );

   cla_16bit CLA1(
   .din1(din1[31:16]),
   .din2(din2[31:16]),
   .cin(carry[1]),                     // 5-gates deep, to dout
   .dout(dout[31:16]),                 // 3-gates deep, from din
   .cout(),                            // Don't care
   .pg(prop[1]),                       // 3-gates deep, from din
   .gg(gen[1])                         // 5-gates deep, from din
   );

   cla_16bit CLA2(
   .din1(din1[47:32]),
   .din2(din2[47:32]),
   .cin(carry[2]),                     // 5-gates deep, to dout
   .dout(dout[47:32]),                 // 3-gates deep, from din
   .cout(),                            // Don't care
   .pg(prop[2]),                       // 3-gates deep, from din
   .gg(gen[2])                         // 5-gates deep, from din
   );

   cla_16bit CLA3(
   .din1(din1[63:48]),
   .din2(din2[63:48]),
   .cin(carry[3]),                     // 5-gates deep, to dout
   .dout(dout[63:48]),                 // 3-gates deep, from din
   .cout(),                            // Don't care
   .pg(prop[3]),                       // 3-gates deep, from din
   .gg(gen[3])                         // 5-gates deep, from din
   );

   // Group Generate and Propagate
   assign pg = &prop;                  // AND individual propagate bits
   assign gg = 
   (gen[3]) | 
   (prop[3]&gen[2]) | 
   (prop[3]&prop[2]&gen[1]) |
   (prop[3]&prop[2]&prop[1]&gen[0]);

   /*********** CL Logic ***********/
   // Generate Individual Carry and Carry Out, Each 2 gates deep
   assign carry[1] = 
   (gen[0])|
   (prop[0]&cin);
   assign carry[2] = 
   (gen[1])| 
   (prop[1]&gen[0])|
   (prop[1]&prop[0]&cin);
   assign carry[3] =
   (gen[2])|
   (prop[2]&gen[1])|
   (prop[2]&prop[1]&gen[0])|
   (prop[2]&prop[1]&prop[0]&cin);
   // This logic only used if this is the top of the CLA chain
   assign cout =
   (gen[3])|
   (prop[3]&gen[2])|
   (prop[3]&prop[2]&gen[1])|
   (prop[3]&prop[2]&prop[1]&gen[0])|
   (prop[3]&prop[2]&prop[1]&prop[0]&cin);

endmodule
