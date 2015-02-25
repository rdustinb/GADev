/*
File     : cla_256bit.sv
Designer : Dustin Brothers <github.com/rdustinb>
Date     : April 5, 2011
Abstract : Makes up the function of a 256+256 bit
         carry lookahead adder.

-----------------------------------------------------
Description    :
   This module depends on the logic contained in the
   cla_64bit module, whereby utilizing the group
   propagate and generate lines from a single 64-bit
   module. These generate and propagate lines are
   combined in sets of four to produce a CLA 256-bit
   adder.
   Since this will be used as the top level adder, the
   max depths of logic gates are specified at the top
   port level if a pipeline register is not used.

   With the current maximum single gate delay assumed
   to be about 1ns (at a 2um process size) per the
   Xilinx XAPP120 v2.0 app note, with 9 gate delays,
   the adder in it's current state could be run at
   about 110MHz max. After that it is not garunteed
   to meet timing. However on a smaller device
   process size, the purely combinatorial logic CLA
   may run at faster clock speeds without breaking
   timing.

   If a single pipeline delay is added, it would 
   allow the maximum gate depth to be reduced to 5
   thus allowing the max clock frequency be increased
   to 200MHz.

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

module cla_256bit(
   input [255:0]  din1,                // 256-bit word 1
   input [255:0]  din2,                // 256-bit word 2
   input          cin,                 // Carry in, 9-gates deep to dout
   output [255:0] dout,                // 256-bit word out
   output         cout,                // Carry out, 9-gates deep from din
   output         pg,                  // Group Propagate, 5-gates deep from din
   output         gg                   // Group Generate, 9-gates deep from din
   );

   // Internals
   wire [3:0] prop;
   wire [3:0] gen;
   wire [3:1] carry;

   // Instances
   cla_64bit CLA0(
   .din1(din1[63:0]),
   .din2(din2[63:0]),
   .cin(cin),                          // 7-gates deep, to dout
   .dout(dout[63:0]),                  // 3-gates deep, from din
   .cout(),                            // Don't care
   .pg(prop[0]),                       // 4-gates deep, from din
   .gg(gen[0])                         // 7-gates deep, from din
   );

   cla_64bit CLA1(
   .din1(din1[127:64]),
   .din2(din2[127:64]),
   .cin(carry[1]),                     // 7-gates deep, to dout
   .dout(dout[127:64]),                // 3-gates deep, from din
   .cout(),                            // Don't care
   .pg(prop[1]),                       // 4-gates deep, from din
   .gg(gen[1])                         // 7-gates deep, from din
   );

   cla_64bit CLA2(
   .din1(din1[191:128]),
   .din2(din2[191:128]),
   .cin(carry[2]),                     // 7-gates deep, to dout
   .dout(dout[191:128]),               // 3-gates deep, from din
   .cout(),                            // Don't care
   .pg(prop[2]),                       // 4-gates deep, from din
   .gg(gen[2])                         // 7-gates deep, from din
   );

   cla_64bit CLA3(
   .din1(din1[255:192]),
   .din2(din2[255:192]),
   .cin(carry[3]),                     // 7-gates deep, to dout
   .dout(dout[255:192]),               // 3-gates deep, from din
   .cout(),                            // Don't care
   .pg(prop[3]),                       // 4-gates deep, from din
   .gg(gen[3])                         // 7-gates deep, from din
   );

   // Group Generate and Propagate
   assign pg = &prop;
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
