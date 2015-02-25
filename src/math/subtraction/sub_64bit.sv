/*
File     : sub_64bit.sv
Designer : Dustin Brothers <github.com/rdustinb>
Date     : April 10, 2011
Abstract : Makes up the function of a 64+64 bit
         borrow lookahead subtractor.

-----------------------------------------------------
Description    :
   This module depends on the logic contained in the
   sub_16bit module, whereby utilizing the group
   propagate and generate lines from a single 16-bit
   module. These generate and propagate lines are
   combined in sets of four to produce a sub 64-bit
   adder.

ToDo           :

Known Issues   :

-----------------------------------------------------
Development Log
-----------------------------------------------------
Date     Init     Description
-----------------------------------------------------
04/10/11 DB       Initial Design
-----------------------------------------------------
*/

`timescale 1ns/100ps

`ifdef SUB64
module sub_64bit(
   input [63:0]   din1,                // 64-bit word 1
   input [63:0]   din2,                // 64-bit word 2
   output [63:0]  dout,                // 64-bit word out
   output         bout,                // borrow out, 7-gates
   output         pg,                  // 64-bit Group Propagate, 4-gates
   output         gg                   // 64-bit Group Generate, 7-gates
   );
   
   // Borrow in is 1 for Subtraction
   wire        bin;
   assign bin = 1'b1;
`else
module sub_64bit(
   input [63:0]   din1,                // 64-bit word 1
   input [63:0]   din2,                // 64-bit word 2
   input          bin,                 // borrow in (set to 1'b1 at top level)
   output [63:0]  dout,                // 64-bit word out
   output         bout,                // borrow out, 7-gates
   output         pg,                  // 64-bit Group Propagate, 4-gates
   output         gg                   // 64-bit Group Generate, 7-gates
   );
`endif
   
   // Internals
   wire [3:0] prop;
   wire [3:0] gen;
   wire [3:1] borrow;

`ifndef SUB16
   // Instances
   sub_16bit sub0(
   .din1(din1[15:0]),
   .din2(din2[15:0]),
   .bin(bin),                          // 5-gates deep, to dout
   .dout(dout[15:0]),                  // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[0]),                       // 3-gates deep, from din
   .gg(gen[0])                         // 5-gates deep, from din
   );

   sub_16bit sub1(
   .din1(din1[31:16]),
   .din2(din2[31:16]),
   .bin(borrow[1]),                     // 5-gates deep, to dout
   .dout(dout[31:16]),                 // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[1]),                       // 3-gates deep, from din
   .gg(gen[1])                         // 5-gates deep, from din
   );

   sub_16bit sub2(
   .din1(din1[47:32]),
   .din2(din2[47:32]),
   .bin(borrow[2]),                     // 5-gates deep, to dout
   .dout(dout[47:32]),                 // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[2]),                       // 3-gates deep, from din
   .gg(gen[2])                         // 5-gates deep, from din
   );

   sub_16bit sub3(
   .din1(din1[63:48]),
   .din2(din2[63:48]),
   .bin(borrow[3]),                     // 5-gates deep, to dout
   .dout(dout[63:48]),                 // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[3]),                       // 3-gates deep, from din
   .gg(gen[3])                         // 5-gates deep, from din
   );
`else
   // Instances
   sub_16bit sub0(
   .din1(din1[15:0]),
   .din2(din2[15:0]),
   .dout(dout[15:0]),                  // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[0]),                       // 3-gates deep, from din
   .gg(gen[0])                         // 5-gates deep, from din
   );

   sub_16bit sub1(
   .din1(din1[31:16]),
   .din2(din2[31:16]),
   .dout(dout[31:16]),                 // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[1]),                       // 3-gates deep, from din
   .gg(gen[1])                         // 5-gates deep, from din
   );

   sub_16bit sub2(
   .din1(din1[47:32]),
   .din2(din2[47:32]),
   .dout(dout[47:32]),                 // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[2]),                       // 3-gates deep, from din
   .gg(gen[2])                         // 5-gates deep, from din
   );

   sub_16bit sub3(
   .din1(din1[63:48]),
   .din2(din2[63:48]),
   .dout(dout[63:48]),                 // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[3]),                       // 3-gates deep, from din
   .gg(gen[3])                         // 5-gates deep, from din
   );
`endif

   // Group Generate and Propagate
   assign pg = &prop;                  // AND individual propagate bits
   assign gg = 
   (gen[3]) | 
   (prop[3]&gen[2]) | 
   (prop[3]&prop[2]&gen[1]) |
   (prop[3]&prop[2]&prop[1]&gen[0]);

   /*********** CL Logic ***********/
   // Generate Individual borrow and borrow Out, Each 2 gates deep
   assign borrow[1] = 
   (gen[0])|
   (prop[0]&bin);
   assign borrow[2] = 
   (gen[1])| 
   (prop[1]&gen[0])|
   (prop[1]&prop[0]&bin);
   assign borrow[3] =
   (gen[2])|
   (prop[2]&gen[1])|
   (prop[2]&prop[1]&gen[0])|
   (prop[2]&prop[1]&prop[0]&bin);
   // This logic only used if this is the top of the sub chain
   assign bout =
   !((gen[3])|
   (prop[3]&gen[2])|
   (prop[3]&prop[2]&gen[1])|
   (prop[3]&prop[2]&prop[1]&gen[0])|
   (prop[3]&prop[2]&prop[1]&prop[0]&bin));

endmodule
