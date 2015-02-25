/*
File     : cla_16bit.sv
Designer : Dustin Brothers <github.com/rdustinb>
Date     : March 29, 2011
Abstract : Makes up the function of a 16x16 bit
         carry lookahead adder.

-----------------------------------------------------
Description    :
   This module depends on the logic contained in the
   cla_4bit module, whereby utilizing the group
   propagate and generate lines from a single 4-bit
   module. These generate and propagate lines are
   combined in sets of four to produce a CLA 16-bit
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

module cla_16bit(
   input [15:0]   din1,                // 16-bit word 1
   input [15:0]   din2,                // 16-bit word 2
   input          cin,                 // Carry in (if necessary)
   output [15:0]  dout,                // 16-bit word out
   output         cout,                // Carry out
   output         pg,                  // Group Propagate
   output         gg                   // Group Generate
   );

   // Internals
   wire [3:0] prop;
   wire [3:0] gen;
   wire [3:1] carry;

   // Instances
   cla_4bit CLA0(
   .din1(din1[3:0]),
   .din2(din2[3:0]),
   .cin(cin),                          // 3-gates deep, to dout
   .dout(dout[3:0]),                   // 3-gates deep, from din
   .cout(),                            // Don't care
   .pg(prop[0]),                       // 2-gates deep, from din
   .gg(gen[0])                         // 3-gates deep, from din
   );

   cla_4bit CLA1(
   .din1(din1[7:4]),
   .din2(din2[7:4]),
   .cin(carry[1]),                     // 3-gates deep, to dout
   .dout(dout[7:4]),                   // 3-gates deep, from din
   .cout(),                            // Don't care
   .pg(prop[1]),                       // 2-gates deep, from din
   .gg(gen[1])                         // 3-gates deep, from din
   );

   cla_4bit CLA2(
   .din1(din1[11:8]),
   .din2(din2[11:8]),
   .cin(carry[2]),                     // 3-gates deep, to dout
   .dout(dout[11:8]),                  // 3-gates deep, from din
   .cout(),                            // Don't care
   .pg(prop[2]),                       // 2-gates deep, from din
   .gg(gen[2])                         // 3-gates deep, from din
   );

   cla_4bit CLA3(
   .din1(din1[15:12]),
   .din2(din2[15:12]),
   .cin(carry[3]),                     // 3-gates deep, to dout
   .dout(dout[15:12]),                 // 3-gates deep, from din
   .cout(),                            // Don't care
   .pg(prop[3]),                       // 2-gates deep, from din
   .gg(gen[3])                         // 3-gates deep, from din
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
