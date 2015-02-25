/*
File     : sub_16bit.sv
Designer : Dustin Brothers <github.com/rdustinb>
Date     : March 29, 2011
Abstract : Makes up the function of a 16x16 bit
         borrow lookahead adder.

-----------------------------------------------------
Description    :
   Due to the awesomness of binary logic, a borrow Look
   Ahead adder may be converted into a Borrow Look
   Ahead Subtractor. This is possible by simply taking
   word 2 of the formula (word 1 + word 2 + borrow in)
   and inverting all of the bits.
   Then by simply changing the borrow in bit to a 
   constant 1, the CLA now acts as a subtractor. Thus
   the above formula becomes (word 1 - word 2).

   This module depends on the logic contained in the
   sub_4bit module, whereby utilizing the group
   propagate and generate lines from a single 4-bit
   module. These generate and propagate lines are
   combined in sets of four to produce a sub 16-bit
   subtractor.

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

`ifdef SUB16
module sub_16bit(
   input [15:0]   din1,                // 16-bit word 1
   input [15:0]   din2,                // 16-bit word 2
   output [15:0]  dout,                // 16-bit word out
   output         bout,                // borrow out
   output         pg,                  // Group Propagate
   output         gg                   // Group Generate
   );

   // Borrow in is 1 for Subtraction
   wire        bin;
   assign bin = 1'b1;
`else
module sub_16bit(
   input [15:0]   din1,                // 16-bit word 1
   input [15:0]   din2,                // 16-bit word 2
   input          bin,                 // borrow in (set to 1'b1 at top level)
   output [15:0]  dout,                // 16-bit word out
   output         bout,                // borrow out
   output         pg,                  // Group Propagate
   output         gg                   // Group Generate
   );
`endif

   // Internals
   wire [3:0]  prop;
   wire [3:0]  gen;
   wire [3:1]  borrow;

`ifndef SUB4
   // Instances
   sub_4bit sub0(
   .din1(din1[3:0]),
   .din2(din2[3:0]),
   .bin(bin),                          // 3-gates deep, to dout
   .dout(dout[3:0]),                   // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[0]),                       // 2-gates deep, from din
   .gg(gen[0])                         // 3-gates deep, from din
   );

   sub_4bit sub1(
   .din1(din1[7:4]),
   .din2(din2[7:4]),
   .bin(borrow[1]),                     // 3-gates deep, to dout
   .dout(dout[7:4]),                   // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[1]),                       // 2-gates deep, from din
   .gg(gen[1])                         // 3-gates deep, from din
   );

   sub_4bit sub2(
   .din1(din1[11:8]),
   .din2(din2[11:8]),
   .bin(borrow[2]),                     // 3-gates deep, to dout
   .dout(dout[11:8]),                  // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[2]),                       // 2-gates deep, from din
   .gg(gen[2])                         // 3-gates deep, from din
   );

   sub_4bit sub3(
   .din1(din1[15:12]),
   .din2(din2[15:12]),
   .bin(borrow[3]),                     // 3-gates deep, to dout
   .dout(dout[15:12]),                 // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[3]),                       // 2-gates deep, from din
   .gg(gen[3])                         // 3-gates deep, from din
   );
`else
   // Instances
   sub_4bit sub0(
   .din1(din1[3:0]),
   .din2(din2[3:0]),
   .dout(dout[3:0]),                   // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[0]),                       // 2-gates deep, from din
   .gg(gen[0])                         // 3-gates deep, from din
   );

   sub_4bit sub1(
   .din1(din1[7:4]),
   .din2(din2[7:4]),
   .dout(dout[7:4]),                   // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[1]),                       // 2-gates deep, from din
   .gg(gen[1])                         // 3-gates deep, from din
   );

   sub_4bit sub2(
   .din1(din1[11:8]),
   .din2(din2[11:8]),
   .dout(dout[11:8]),                  // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[2]),                       // 2-gates deep, from din
   .gg(gen[2])                         // 3-gates deep, from din
   );

   sub_4bit sub3(
   .din1(din1[15:12]),
   .din2(din2[15:12]),
   .dout(dout[15:12]),                 // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[3]),                       // 2-gates deep, from din
   .gg(gen[3])                         // 3-gates deep, from din
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
   // Generate Individual borrow and Carry Out, Each 2 gates deep
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
