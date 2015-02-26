/***************************************************************************

Designer        : Dustin Brothers <github.com/rdustinb>
Date            : November 18, 2013
Project         : SHA 1 Core

Description     : Basically the SHA algorithm has a set order of operations
    which will be captured for this particular variant of the SHA algorithm
    in this header.

    1) Pad the message - the padding is not just adding 0s to the end of
    the message to get it to a multiple of 512 or 1024 based on the variant 
    of the SHA algorithm. For SHA1, the algorithm is as follows:
        a) Append "1" to the end of the message.
        b) Append 0s to the message such that: 
                message size + 1 + 0s = 448 mod 512
        c) Append a final 64-bit field which is a binary count value of the
        length of the original message.
    This will create a final padded-message block of 512 bits for the SHA1
    algorithm.

Usage           :
    This core will start hashing on the fly, meaning the storage inside this
    block has a maximum of two times the block size of the hashing algorithm.
    The reason is that the first storage "block" is used to "catch" data 
    strobed in by the upper level block and the second storage "block" is used
    to actually perform the next round of hashing.
    The block uses two signals to control data coming into and the hashing
    being strobed out of the block. The "bsy" signal tells the upper level
    block that the hashing algorithm is currently running on the data that was 
    previously strobed in. Once the upper level block strobes the "lst_din" line
    the hashing block will immediately go into the padding phase of the final
    data that had previously been strobed in. Once the final hashing has been
    performed, the block will assert the "rdy" signal to the upper level block
    from whence it may strobe the "str_out" signal to get the final hash value
    out of the block.

Todo List       :

***************************************************************************/

`timescale 100 ps / 1 ps

module sha1 #(
        parameter CLKF                  = 200000000,
        parameter BUSWIDTH              = 8
    )(
        input                           clk,
        input                           rst,
        input                           str_in,
        input                           lst_din
        input   [(BUSWIDTH-1):0]        din,
        input                           str_out,
        output                          bsy,
        output                          rdy,
        output  [(BUSWIDTH-1):0]        dout
    );

    // Determine number of bytes in a block
    localparam SHABLOCK = 512;
    localparam BLOCKBYTES = SHABLOCK / 8;

    // Catch in simulation if the bus width is not a multiple of 8
    initial
    begin
        if(BUSWIDTH%8 != 0) begin
            $display( "sha1 Block Error > The input/output bus width is not a modulus of 8!" );
            $finish;
        end
    end

    // Local Data Storage
    logic [(SHABLOCK-1):0] mem1, mem2;

    // State Machine
    typedef enum logic[3:0] {IDLE} States;
    States fsm;

    // Core State Machine Process
    always_ff@(posedge clk) begin
        if(rst == 1'b1) begin
            fsm                         <= IDLE;
            wr_ptr                      <= 0;
        end
        else begin
            // Independent of the FSM is the strobing in of the Data
            if(str_in == 1'b1) begin
                // Loop Through All byte coming in based on the input data bus size
                for(int i = 0; i < BUSWIDTH; i + 8) begin
                    // Data gets stuffed to highest byte first, reference the top most bit
                    mem1[(SHABLOCK - i*8*wr_ptr - 1)-:8] <= din[(BUSWIDTH - i*8 - 1)-:8];
                    // This pointer counts bytes
                    wr_ptr <= wr_ptr + (BUSWIDTH/8);
                end
            end

            // FSM
            case(fsm)
                IDLE        : begin
                    // Hash the block if we have enough data
                    if(wr_ptr == 512) begin
                        // Reset the strobe pointer
                        wr_ptr <= 0;
                        // Grab the current data
                        mem2 <= mem1;
                        // Go to the first hashing state
                        fsm <= 
                    end
                end
            endcase
        end
    end

endmodule

