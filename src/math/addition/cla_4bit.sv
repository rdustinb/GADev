/*
File        : cla_4bit.sv
Designer    : Dustin Brothers <github.com/rdustinb>
Date        : March 28, 2011
Abstract    : Create a single-clock CLA operation for
            two four-bit hex numbers.

-----------------------------------------------------
Description    :
   This module will provide the combinatorial logic
   to binarily add two 4-bit numbers together. Care
   must be taken to register the data into and out
   of this module.

   The individual group propagate and group generate
   bits that are output are piped into an upper layer
   4-bit CLA logic module to combine 4 4-bit CLAs.

   The adder is divided into two blocks of logic, the
   partial full (PF) adder which generates, dout, gen 
   and prop vectors.
   The second is the carry lookahead logic, which will
   generate the carry-out bits. The carry out bit will
   only be looked at at the end of the CLA chain, thus
   if four of these 4-bit CLAs are used, only the end
   of instance 4 will the carry out be looked at.

   The depth of gates to the outputs are specified, 
   yet it must be noted that some texts state take 
   into account that an XOR is a two-gate depth. This 
   module only assumes one gate depth for any logic
   type.

ToDo           :
   Complete logic -- Done, 3/28/11
   Simulate and verify -- Done, 3/28/11

Known Issues   :

-----------------------------------------------------
Development Log
-----------------------------------------------------
Date        Init    Description
-----------------------------------------------------
03/28/11    DB      Initial Design
-----------------------------------------------------
*/

`timescale 1ns/100ps

module cla_4bit(
    input [3:0]     din1,                   // 4-bit word 1
    input [3:0]     din2,                   // 4-bit word 2
    input           cin,                    // Carry in (if necessary)
    output [3:0]    dout,                   // 4-bit word out
    output          cout,                   // Carry out
    output          pg,                     // Group Propagate
    output          gg                      // Group Generate
    );

    // Internals
    wire [3:0] prop;
    wire [3:0] gen;
    wire [3:1] carry;

    /********** PFA Logic ***********/
    // Generate a Carry?
    assign gen = din1 & din2;               // Carry Generation for each bit

    // Propagate a Carry?
    assign prop = din1 ^ din2;              // Carry Propagation for each bit

    // Group Generate and Propagate
    assign pg = &prop;                      // AND individual propagate bits
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

    // Generate dout
    assign dout = prop ^ {carry,cin};

endmodule
