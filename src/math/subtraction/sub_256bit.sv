/*
File     : sub_256bit.sv
Designer : Dustin Brothers <github.com/rdustinb>
Date     : April 10, 2011
Abstract : Makes up the function of a 256+256 bit
         borrow lookahead adder.

-----------------------------------------------------
Description    :
   This module depends on the logic contained in the
   sub_64bit module, whereby utilizing the group
   propagate and generate lines from a single 64-bit
   module. These generate and propagate lines are
   combined in sets of four to produce a sub 256-bit
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
   process size, the purely combinatorial logic sub
   may run at faster clock speeds without breaking
   timing.

   If a single pipeline delay is added, it would 
   allow the maximum gate depth to be reduced to 5
   thus allowing the max clock frequency be increased
   to 200MHz.

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

`ifdef SUB256
module sub_256bit(
   input [255:0]  din1,                // 256-bit word 1
   input [255:0]  din2,                // 256-bit word 2
   output [255:0] dout,                // 256-bit word out
   output         bout,                // borrow out, 9-gates deep from din
   output         pg,                  // Group Propagate, 5-gates deep from din
   output         gg                   // Group Generate, 9-gates deep from din
   );
   
   // Borrow in is 1 for Subtraction
   wire        bin;
   assign bin = 1'b1;
`else
module sub_256bit(
   input [255:0]  din1,                // 256-bit word 1
   input [255:0]  din2,                // 256-bit word 2
   input          bin,                 // borrow in, 9-gates deep to dout
   output [255:0] dout,                // 256-bit word out
   output         bout,                // borrow out, 9-gates deep from din
   output         pg,                  // Group Propagate, 5-gates deep from din
   output         gg                   // Group Generate, 9-gates deep from din
   );
`endif

   // Internals
   wire [3:0] prop;
   wire [3:0] gen;
   wire [3:1] borrow;

`ifndef SUB64
   // Instances
   sub_64bit sub0(
   .din1(din1[63:0]),
   .din2(din2[63:0]),
   .bin(bin),                          // 7-gates deep, to dout
   .dout(dout[63:0]),                  // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[0]),                       // 4-gates deep, from din
   .gg(gen[0])                         // 7-gates deep, from din
   );

   sub_64bit sub1(
   .din1(din1[127:64]),
   .din2(din2[127:64]),
   .bin(borrow[1]),                     // 7-gates deep, to dout
   .dout(dout[127:64]),                // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[1]),                       // 4-gates deep, from din
   .gg(gen[1])                         // 7-gates deep, from din
   );

   sub_64bit sub2(
   .din1(din1[191:128]),
   .din2(din2[191:128]),
   .bin(borrow[2]),                     // 7-gates deep, to dout
   .dout(dout[191:128]),               // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[2]),                       // 4-gates deep, from din
   .gg(gen[2])                         // 7-gates deep, from din
   );

   sub_64bit sub3(
   .din1(din1[255:192]),
   .din2(din2[255:192]),
   .bin(borrow[3]),                     // 7-gates deep, to dout
   .dout(dout[255:192]),               // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[3]),                       // 4-gates deep, from din
   .gg(gen[3])                         // 7-gates deep, from din
   );
`else
   // Instances
   sub_64bit sub0(
   .din1(din1[63:0]),
   .din2(din2[63:0]),
   .dout(dout[63:0]),                  // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[0]),                       // 4-gates deep, from din
   .gg(gen[0])                         // 7-gates deep, from din
   );

   sub_64bit sub1(
   .din1(din1[127:64]),
   .din2(din2[127:64]),
   .dout(dout[127:64]),                // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[1]),                       // 4-gates deep, from din
   .gg(gen[1])                         // 7-gates deep, from din
   );

   sub_64bit sub2(
   .din1(din1[191:128]),
   .din2(din2[191:128]),
   .dout(dout[191:128]),               // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[2]),                       // 4-gates deep, from din
   .gg(gen[2])                         // 7-gates deep, from din
   );

   sub_64bit sub3(
   .din1(din1[255:192]),
   .din2(din2[255:192]),
   .dout(dout[255:192]),               // 3-gates deep, from din
   .bout(),                            // Don't care
   .pg(prop[3]),                       // 4-gates deep, from din
   .gg(gen[3])                         // 7-gates deep, from din
   );
`endif

   // Group Generate and Propagate
   assign pg = &prop;
   assign gg = 
   (gen[3]) | 
   (prop[3]&gen[2]) | 
   (prop[3]&prop[2]&gen[1]) |
   (prop[3]&prop[2]&prop[1]&gen[0]);

   /*********** CL Logic ***********/
   // Generate Individual Borrow and Borrow Out, Each 2 gates deep
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
