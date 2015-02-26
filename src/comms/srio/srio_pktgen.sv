/* 
 --Summary--
    This module generates an entire AXI-Stream Packet with a payload length
    up to 256 Bytes, which is the maximum length of an SRIO Packet. Since the 
    upper level has absolute control over the header fields, this module could
    be used as an individual VC block.
    This module does not use any block RAM and is intended to be used at
    super high clock speeds.

    This module uses a Data Generator that includes the following modes of 
    data generation:
        Constant
        LFSR / PRNG (x^32 + x^22 + x^2 + x + 1)
        Increment
        Decrement
        Galloping Nibble
        Rotate Left
        Rotate Right

 --Module Interface Description--
    The upper level must monitor the "starving bit" as this module, once loaded
    with a delay count value, will notify the upper level when it needs to
    send a packet to maintain its loaded bandwidth. The following depicts 
    typical setup, note that all loadable values can be loaded simultaneously:
                      _   _   _   _   _   _   _   _   _   _   _   _   _ 
    clk             _| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |
                              ___
    ld_hello_hdr    _________|   |______________________________________
                    _________ ___ ______________________________________
    hello_hdr       ___X_____|Val|________________X_____________________
                              ___
    ld_payload_len  _________|   |______________________________________
                    _________ ___ ______________________________________
    payload_len     ___X_____|Val|________________X_____________________
                              ___
    ld_delay_count  _________|   |______________________________________
                    _________ ___ ______________________________________
    delay_count     ___X_____|Val|________________X_____________________
                              ___
    ld_seed         _________|   |______________________________________
                    _________ ___ ______________________________________
    seed            ___X_____|Val|________________X_____________________
                              ___
    ld_mode         _________|   |______________________________________
                    _________ ___ ______________________________________
    mode            ___X_____|Val|________________X_____________________
                              ___
    ld_pkt_count    _________|   |______________________________________
                    _________ ___ ______________________________________
    pkt_count       ___X_____|Val|________________X_____________________

    The next interface signalling that must be understood is the upper
    level handshaking and monitoring of the other control signals to and
    from this module:
                      _   _   _   _   _   _   _   _   _   _   _   _   _ 
    clk             _| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |
                                  _______
    send            _____________|       |_____________________________
                    _________________
    rdy_bsyf                         |_________________________________
                              _______
    stream_starving _________|       |_________________________________
                    

    Note that the send bit should be held HI until this module drops the
    rdy_bsyf signal LO. The upper level only then needs to monitor the 
    rdy_bsyf signal for when it goes LO as this module will monitor the
    AXI Stream Ready signal and hold off the upper level as necessary:
                      _   _   _   _   _   _   _   _   _   _   _   _   _ 
    clk             _| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |
                                  ___________________
    send            _____________|                   |_________________
                    _____________________________
    rdy_bsyf                                     |_____________________
                              ___________________
    stream_starving _________|                   |_____________________
                                                  _____________________
    axis_ready      _____________________________|

    After the upper level initiates a Stream Packet transmission, this
    module is self-contained and will handle any other flow control
    signals from the AXI-Stream interface. The upper level only need to
    monitor the rdy_bsyf signal for when it goes HI again to signal the
    this module has completed the packet transmission.
    Note that the delay counter only decrements when the "active" signal
    is driven HI into this module. This allows the user or the upper
    level to load the delay counter at some predefined time and then 
    later actually enable this module.

    For packets with payloads that are not multiples of 128-bits - 64
    (meaning the final AXI-Stream transmission doesn't utilize the entire 
    AXI-Stream bus) this module provides a small bus that has a single
    bit corresponding to each byte in the AXI-Stream Data bus. If the bit
    is HI, the corresponding byte in the AXI-Stream data bus is valid
    and real data:
                      _   _   _   _   _   _   _   _   _   _   _   _   _ 
    clk             _| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |
                              _______________________________
    axis_valid      _________|                               |_________
                                                          ___
    axis_last       _____________________________________|   |_________
                    _________ ___ ___ ___ ___ ___ ___ ___ ___ _________
    axis_data       ____X____|_H_|_D_|_D_|_D_|_D_|_D_|_D_|_D_|____X____
                    _____________________________________ ___ _________
    axis_bytes_good ______________16'hFFFF_______________|___|_________
                                                          _____________
    rdy_bsyf        _____________________________________|

 --Todo List--

*/

`timescale 100 ps / 1 ps

module srio_pktgen_axis #(
        parameter RSTPOL                                = 0,
        parameter HDRWIDTH                              = 64,
        parameter PLDCNTWIDTH                           = 16,
        parameter DLYWIDTH                              = 32,
        parameter SEEDWIDTH                             = 32,
        parameter MODEWIDTH                             = 3,
        parameter PKTCNTWIDTH                           = 64,
        parameter AXISWIDTH                             = 128
    )(
        input                                           clk,
        input                                           reset,
        input                                           send,
        input                                           active,
        input                                           axis_ready,
        input                                           ld_hello_hdr,
        input   [(HDRWIDTH-1):0]                        hello_hdr,
        input                                           ld_payload_len,
        input   [(PLDCNTWIDTH-1):0]                     payload_len,
        input                                           ld_delay_count,
        input   [(DLYWIDTH-1):0]                        delay_count,
        input                                           ld_seed,
        input   [(SEEDWIDTH-1):0]                       seed,
        input                                           ld_mode,
        input   [(MODEWIDTH-1):0]                       mode,
        input                                           ld_pkt_count,
        input   [(PKTCNTWIDTH-1):0]                     pkt_count,
        output                                          rdy_bsyf,
        output                                          stream_starving,
        output                                          axis_valid,
        output                                          axis_last,
        output  [(AXISWIDTH-1):0]                       axis_data,
        output  [((AXISWIDTH/8)-1):0]                   axis_bytes_good
    );

    // Logic
    logic rdy_bsyf_y;
    logic rdy_bsyf_r;
    logic stream_starving_y;
    logic axis_valid_y;
    logic axis_last_y;
    logic [(AXISWIDTH-1):0] axis_data_y;
    logic [((AXISWIDTH/8)-1):0] axis_bytes_good_y;
    logic [(HDRWIDTH-1):0] hello_hdr_y;
    logic [(PLDCNTWIDTH-1):0] payload_len_y;
    logic [(DLYWIDTH-1):0] delay_count_y, starving_cntr;
    logic [(SEEDWIDTH-1):0] seed_y;
    logic [(PKTCNTWIDTH-1):0] pkt_count_y;
    logic dgen_strobe_lo;
    logic dgen_strobe_hi;
    logic dgen_pulse;
    logic [(PLDCNTWIDTH-1):0] payload_byte_cnt;
    logic [(AXISWIDTH-1):0] data;
    logic [(SEEDWIDTH-1):0] tmp1, tmp2, tmp3, tmp4;

    // Output Assignments
    assign rdy_bsyf = rdy_bsyf_y;
    assign stream_starving = stream_starving_y;
    assign axis_valid = axis_valid_y;
    assign axis_last = axis_last_y;
    assign axis_data = axis_data_y;
    assign axis_bytes_good = axis_bytes_good_y;

    typedef enum logic[2:0] {IDLE,PAYLOAD} States;
    States state;

    typedef enum logic[(MODEWIDTH-1):0] {FIX,PRN,INC,DEC,GAL,RL,RR} Patterns;
    Patterns mode_y;

    // Latched values
    always@(posedge clk) begin
        if(reset == RSTPOL) begin
            payload_len_y       <= 0;
            delay_count_y       <= 0;
            seed_y              <= 0;
            mode_y              <= FIX;                 // Reset default DGen Mode
            pkt_count_y         <= 0;
        end
        else begin
            // Load the Header
            if(ld_hello_hdr) begin
                hello_hdr_y <= hello_hdr;
            end
            // Load the Payload Length
            if(ld_payload_len) begin
                payload_len_y <= payload_len;
            end
            // Load the Delay Counter
            if(ld_delay_count) begin
                delay_count_y <= delay_count;
            end
            // Load the Seed
            if(ld_seed) begin
                seed_y <= seed;
            end
            // Load the Mode
            if(ld_mode) begin
                mode_y <= Patterns'(mode);              // Cast to the Typedef type
            end
            // Load the Packet Counter
            if(ld_pkt_count) begin
                pkt_count_y <= pkt_count;
            end
        end
    end

    // Main FSM
    always@(posedge clk) begin
        if(reset == RSTPOL) begin
            state <= IDLE;
            dgen_pulse <= 1'b0;
            axis_data_y <= {AXISWIDTH{1'b0}};
            axis_valid_y <= 1'b0;
            axis_last_y <= 1'b0;
            rdy_bsyf_y <= 1'b1;
            payload_byte_cnt <= 0;
        end
        else begin
            // Defaults
            dgen_pulse <= 1'b0;

            // FSM Decode
            case(state)
                IDLE    : begin
                    axis_valid_y <= 1'b0;
                    axis_last_y <= 1'b0;
                    rdy_bsyf_y <= 1'b1;
                    if(axis_ready) begin                // Is the AXI-Stream ready?
                        if(send) begin                  // Upon send reception, immediately hit the AXI Steam Bus
                            axis_data_y <= {hello_hdr_y, data[(AXISWIDTH-1):(AXISWIDTH-HDRWIDTH)]};
                            axis_valid_y <= 1'b1;
                            // If there isn't a payload, stay here
                            if(0 == payload_len_y) begin
                                state <= IDLE;
                                axis_last_y <= 1'b1;
                            end
                            else begin
                                dgen_pulse <= 1'b1;
                                // Header Bytes are at least good
                                axis_bytes_good_y[(AXISWIDTH/8 - 1):0] <= {(AXISWIDTH/8){1'b1}};
                                // If the payload is super short, stay here
                                if((AXISWIDTH/8 - HDRWIDTH/8) >= payload_len_y) begin
                                    state <= IDLE;
                                    axis_last_y <= 1'b1;
                                    payload_byte_cnt <= 0;
                                    // Zero out the bytes that should be ignored
                                    axis_bytes_good_y[(AXISWIDTH/8 - HDRWIDTH/8 - 1):0] <= (axis_bytes_good_y[(AXISWIDTH/8 - HDRWIDTH/8 - 1):0] << (AXISWIDTH/8 - HDRWIDTH/8 - payload_byte_cnt));
                                end
                                else begin
                                    rdy_bsyf_y <= 1'b0; // No longer ready
                                    payload_byte_cnt <= (payload_len_y - (AXISWIDTH/8 - HDRWIDTH/8));
                                    axis_bytes_good_y[(AXISWIDTH/8 - HDRWIDTH/8 - 1):0] <= {(AXISWIDTH/8 - HDRWIDTH/8){1'b1}};
                                    state <= PAYLOAD;   // Start sending Payload
                                end
                            end
                        end
                    end
                end
                PAYLOAD : begin
                    axis_valid_y <= 1'b0;
                    axis_last_y <= 1'b0;
                    if(axis_ready) begin                // Is the AXI-Stream still ready?
                        // If the payload is shorter than another AXI-Stream bus width, stay here
                        if((AXISWIDTH/8) >= payload_byte_cnt) begin
                            state <= IDLE;
                            axis_valid_y <= 1'b1;
                            axis_last_y <= 1'b1;
                            rdy_bsyf_y <= 1'b1;         // Now ready
                            payload_byte_cnt <= 0;
                            axis_bytes_good_y[(AXISWIDTH/8 - 1):0] <= {(AXISWIDTH/8){1'b1}};
                            // Zero out the bytes that should be ignored
                            axis_bytes_good_y[(AXISWIDTH/8 - 1):0] <= (axis_bytes_good_y[(AXISWIDTH/8 - 1):0] << (AXISWIDTH/8 - payload_byte_cnt));
                            axis_data_y <= data;
                            axis_valid_y <= 1'b1;
                        end
                        else begin
                            dgen_pulse <= 1'b1;         // Pulse the Data Generator to update
                            state <= PAYLOAD;           // Start sending Payload
                            payload_byte_cnt <= (payload_byte_cnt - (AXISWIDTH/8));
                            axis_bytes_good_y[(AXISWIDTH/8 - 1):0] <= {(AXISWIDTH/8){1'b1}};
                            axis_data_y <= data;
                            axis_valid_y <= 1'b1;
                        end
                    end
                end
            endcase
        end
    end

    // Data Generator Logic
    always@(posedge clk) begin
        if(reset == RSTPOL) begin
            data <= 0;
        end
        else begin
            // Load Mode, Init Data
            if(ld_mode) begin
                case(Patterns'(mode))                   // Cast the incoming pattern to the Patterns type
                    FIX : begin
                        data <= {4{seed}};
                    end
                    PRN : begin
                        //data <= {(seed+0),(seed+10),(seed+20),(seed+30)};
                        tmp1=seed;
                        tmp2={seed[30:0],(seed[31]~^seed[21]~^seed[1]~^seed[0])};
                        tmp3={tmp2[30:0],(tmp2[31]~^tmp2[21]~^tmp2[1]~^tmp2[0])};
                        tmp4={tmp3[30:0],(tmp3[31]~^tmp3[21]~^tmp3[1]~^tmp3[0])};
                        data <= {tmp1, tmp2, tmp3, tmp4};
                    end
                    INC : begin
                        data <= {(seed+0),(seed+1),(seed+2),(seed+3)};
                    end
                    DEC : begin
                        data <= {(seed-0),(seed-1),(seed-2),(seed-3)};
                    end
                    GAL : begin
                        data <= {
                            (seed),
                            (((seed<<4)&(32'hFFFFFFF0))|((seed>>28)&(32'hF))),
                            (((seed<<8)&(32'hFFFFFF00))|((seed>>24)&(32'hFF))),
                            (((seed<<12)&(32'hFFFFF000))|((seed>>20)&(32'hFFF)))
                        };
                    end
                    RL  : begin
                        data <= {
                            (seed),
                            (((seed<<1)&(32'hFFFFFFFE))|((seed>>31)&(32'h1))),
                            (((seed<<2)&(32'hFFFFFFFC))|((seed>>30)&(32'h3))),
                            (((seed<<3)&(32'hFFFFFFF8))|((seed>>29)&(32'h7)))
                        };
                    end
                    RR  : begin
                        data <= {
                            (seed),
                            (((seed<<31)&(32'h80000000))|((seed>>1)&(32'h7FFFFFFF))),
                            (((seed<<30)&(32'hC0000000))|((seed>>2)&(32'h3FFFFFFF))),
                            (((seed<<29)&(32'hE0000000))|((seed>>3)&(32'h1FFFFFFF)))
                        };
                    end
                endcase
            end
            // Decode off the FSM
            case(state)
                IDLE,PAYLOAD : begin
                    if(send || dgen_pulse) begin
                        case(mode_y)
                            FIX : begin
                                data <= {4{seed_y}};
                            end
                            PRN : begin
                                if(send) begin
                                    tmp1={data[30:0],(data[31]~^data[21]~^data[1]~^data[0])};
                                    tmp2={tmp1[30:0],(tmp1[31]~^tmp1[21]~^tmp1[1]~^tmp1[0])};
                                    tmp3={tmp2[30:0],(tmp2[31]~^tmp2[21]~^tmp2[1]~^tmp2[0])};
                                    tmp4={tmp3[30:0],(tmp3[31]~^tmp3[21]~^tmp3[1]~^tmp3[0])};
                                    data[127:64] <= {data[63:0], tmp1, tmp2};
                                end
                                else begin
                                    tmp1={data[30:0],(data[31]~^data[21]~^data[1]~^data[0])};
                                    tmp2={tmp1[30:0],(tmp1[31]~^tmp1[21]~^tmp1[1]~^tmp1[0])};
                                    tmp3={tmp2[30:0],(tmp2[31]~^tmp2[21]~^tmp2[1]~^tmp2[0])};
                                    tmp4={tmp3[30:0],(tmp3[31]~^tmp3[21]~^tmp3[1]~^tmp3[0])};
                                    data[127:64] <= {tmp1, tmp2, tmp3, tmp4};
                                end
                            end
                            INC : begin
                                if(send) begin
                                    data <= {data[63:0],(data[127:96]+4),(data[95:64]+4)};
                                end
                                else begin
                                    data <= {(data[127:96]+4),(data[95:64]+4),(data[63:32]+4),(data[31:0]+4)};
                                end
                            end
                            DEC : begin
                                if(send) begin
                                    data <= {data[63:0], (data[127:96]-4),(data[95:64]-4)};
                                end
                                else begin
                                    data <= {(data[127:96]-4),(data[95:64]-4),(data[63:32]-4),(data[31:0]-4)};
                                end
                            end
                            GAL : begin
                                if(send) begin
                                    data <= {
                                        data[63:0],
                                        ((data[127:96]<<4) & 32'hFFFFFFF0)|((data[127:96]>>28) & 32'hF),
                                        ((data[95:64]<<4) & 32'hFFFFFFF0)|((data[95:64]>>28) & 32'hF)
                                    };
                                end
                                else begin
                                    data <= {
                                        ((data[127:96]<<4) & 32'hFFFFFFF0)|((data[127:96]>>28) & 32'hF),
                                        ((data[95:64]<<4) & 32'hFFFFFFF0)|((data[95:64]>>28) & 32'hF),
                                        ((data[63:32]<<4) & 32'hFFFFFFF0)|((data[63:32]>>28) & 32'hF),
                                        ((data[31:0]<<4) & 32'hFFFFFFF0)|((data[31:0]>>28) & 32'hF)
                                    };
                                end
                            end
                            RL  : begin
                                if(send) begin
                                    data <= {
                                        data[63:0],
                                        ((data[31:0]<<1)&(32'hFFFFFFFE))|((data[31:0]>>31)&(32'h1)),
                                        ((data[31:0]<<2)&(32'hFFFFFFFC))|((data[31:0]>>30)&(32'h3))
                                    };
                                end
                                else begin
                                    data <= {
                                        ((data[31:0]<<1)&(32'hFFFFFFFE))|((data[31:0]>>31)&(32'h1)),
                                        ((data[31:0]<<2)&(32'hFFFFFFFC))|((data[31:0]>>30)&(32'h3)),
                                        ((data[31:0]<<3)&(32'hFFFFFFF8))|((data[31:0]>>29)&(32'h7)),
                                        ((data[31:0]<<4)&(32'hFFFFFFF0))|((data[31:0]>>28)&(32'hF))
                                    };
                                end
                            end
                            RR  : begin
                                    data <= {
                                        ((data[31:0]<<31)&(32'h80000000))|((data[31:0]>>1)&(32'h7FFFFFFF)),
                                        ((data[31:0]<<30)&(32'hC0000000))|((data[31:0]>>2)&(32'h3FFFFFFF)),
                                        ((data[31:0]<<29)&(32'hE0000000))|((data[31:0]>>3)&(32'h1FFFFFFF)),
                                        ((data[31:0]<<28)&(32'hF0000000))|((data[31:0]>>4)&(32'h0FFFFFFF))
                                    };
                            end
                        endcase
                    end
                end
            endcase
        end
    end

    // Stream Delay Counter
    always@(posedge clk) begin                                              // Should this be the system clock?
        if(reset == RSTPOL) begin
            starving_cntr <= 0;
            stream_starving_y <= 1'b0;
            rdy_bsyf_r <= 1'b1;
        end
        else begin
            rdy_bsyf_r <= rdy_bsyf_y;                                       // Edge-Detect
            stream_starving_y <= 1'b0;                                      // By default, starving is inactive
            if(active) begin
                if((rdy_bsyf_y) && (!rdy_bsyf_r)) begin                     // Reset the counter
                    starving_cntr <= delay_count_y;
                end
                else if((starving_cntr != 1) && (rdy_bsyf_y != 0)) begin    // Do not count when sending data
                    starving_cntr <= starving_cntr - 1;                     // Decrement Every Clock
                end
                else if((starving_cntr == 1) && (rdy_bsyf_y != 0)) begin    // Do not drive the starving signal when we're sending data
                    stream_starving_y <= 1'b1;
                end
            end
            if(ld_delay_count) begin                                        // On initial loading, also load this counter
                starving_cntr <= delay_count;
            end
        end
    end

/************** Code Snippets
    always@(posedge clk) begin
        if(reset == RSTPOL) begin
        end
        else begin
        end
    end
****************************/
endmodule
