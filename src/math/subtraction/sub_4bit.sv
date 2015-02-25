/*
File     : sub_4bit.sv
Designer : Dustin Brothers <github.com/rdustinb>
Date     : April 9, 2011
Abstract : Provides a wrapper to convert a CLA 4-bit
         adder into a subtractor.

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

ToDo           :

Known Issues   :

-----------------------------------------------------
Development Log
-----------------------------------------------------
Date        Init     Description
-----------------------------------------------------
04/9/11     DB       Initial Design
-----------------------------------------------------
*/

`timescale 1ns/100ps

`ifdef SUB4
module sub_4bit(
   input [3:0]    din1,                // 4-bit word 1
   input [3:0]    din2,                // 4-bit word 2
   output [3:0]   dout,                // 4-bit word out
   output         bout,                // borrow out
   output         pg,                  // Group Propagate
   output         gg                   // Group Generate
   );

   // Borrow in is 1 for Subtraction
   wire        bin;
   assign bin = 1'b1;
`else
module sub_4bit(
   input [3:0]    din1,                // 4-bit word 1
   input [3:0]    din2,                // 4-bit word 2
   input          bin,                 // borrow in (set to 1'b1 at top level)
   output [3:0]   dout,                // 4-bit word out
   output         bout,                // borrow out
   output         pg,                  // Group Propagate
   output         gg                   // Group Generate
   );
`endif

   // Internals
   wire [3:0]  ndin2;
   wire [3:0]  prop;
   wire [3:0]  gen;
   wire [3:1]  borrow;

   // Invert din2 Bits
   assign ndin2 = din2 ^ 4'hf;

   /********** PFA Logic ***********/
   // Generate a borrow?
   assign gen = din1 & ndin2;          // Borrow Generation for each bit

   // Propagate a borrow?
   assign prop = din1 ^ ndin2;         // Borrow Propagation for each bit

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
   // This logic only used if this is the top of the CLA chain
   assign bout =
   !((gen[3])|
   (prop[3]&gen[2])|
   (prop[3]&prop[2]&gen[1])|
   (prop[3]&prop[2]&prop[1]&gen[0])|
   (prop[3]&prop[2]&prop[1]&prop[0]&bin));

   // Generate dout
   assign dout = prop ^ {borrow,bin};

endmodule
