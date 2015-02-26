/*
    Author:     Dustin Brothers
    Date:       April 22, 2014
    Module:     i2c.sv

    Basic I2C Interface Module for reading and writing an I2C Slave. This
    block can be synthesized to support Standard Mode (100kbps), Fast Mode
    (400kbps), Fast Plus Mode (1Mbps) and Ultra Fast Mode (5Mbps) of the I2C
    Standard.

    Note that due to the speed of the I2C bus and the fact that this module
    assumes an internal FPGA Fabirc clock speed much greater than even the
    fastest I2C clock speed, that the internal fabric clock is divided down
    to properly Master the I2C bus at correct I2C clock speeds.

    This module is structured to allow any upper level module to control the
    next data byte. With basic I2C functionality, the user would simply keep
    the same RDWR bit value and strobe the go signal. But this structure
    allows the user to implement the SMBus or PMBus architecture with this 
    module which will be explained and developed in a future HDL release.

    - Basic Operation, Write -
    Drive in the slave_addr value and the rdwr bit, pulsing the go signal. This
    will cause the FSM to perform the address phase of the I2C bus cycle. When
    the FSM has completed the address phase the rdy signal will drive HI, which
    signals to the next layer up that the write data is ready to be loaded. 
    Next, the upper layer should drive the byte to be written into the data_w 
    bus and the go signal should be strobed again. When the byte is written to 
    the I2C bus successfully, the FSM will drive rdy HI again. If an error
    occured during the write access, the FSM will drive the err_dataw line HI
    and immediately return to IDLE.
    Loading of the data_w and strobing the go signal should be done as many 
    bytes as need to be transferred. Once the data has been transferred, the 
    upper layer should strobe the stop signal.

                Idle | Address Phase |       | Data Phase|       |  Stop | Idle 
                  _   _   _       _   _   _   _       _   _   _   _       _   _ 
    clk         _| |_| |_| |_) )_| |_| |_| |_| |_) )_| |_| |_| |_| |_) )_| |_| |
                  ___       ( (           ___   ( (                 ( (         
    go          _|   |_______) )_________|   |___) )_________________) )________
                            ( (                 ( (                 ( (         
    rdwr        _____________) )_________________) )_________________) )________
                            ( (                 ( (           ___   ( (         
    stop        _____________) )_________________) )_________|   |___) )________
                _ ___ ______( (_________________( (_________________( (_________
    slave_addr  _|VLD|_______) )_________________) )_________________) )________
                ____________( (__________ ___ __( (_________________( (_________
    data_w      _____________) )_________|VLD|___) )_________________) )________
                _____       ( (       _______   ( (       _______   ( (   ______
    rdy              |_______) )_____|       |___) )_____|       |___) )_|      

    - Basic Operation, Read -
    Drive in the slave_addr value and the rdwr bit, pulsing the go signal. This
    will cause the FSM to perform the address phase of the I2C bus cycle. When
    the FSM has completed the address phase the rdy signal will drive HI, which
    signals to the next layer up that the data is ready to be read across the 
    I2C bus. Next, the upper layer should simply strobe the go signal again to
    start the read of a byte across the I2C bus. When the data is read 
    successfully, the FSM will drive the rdy signal HI.
    The upper level may continue to strobe the go signal and wait for the rdy
    bit to go HI to continue reading data across the I2C bus. Then when all data
    needed is read, simply strobe the stop bit to return the FSM to IDLE.

                Idle | Address Phase |       |   Data Phase  |   |  Stop | Idle 
                  _   _   _       _   _   _   _       _   _   _   _       _   _ 
    clk         _| |_| |_| |_) )_| |_| |_| |_| |_) )_| |_| |_| |_| |_) )_| |_| |
                  ___       ( (           ___   ( (                 ( (         
    go          _|   |_______) )_________|   |___) )_________________) )________
                  ___       ( (           ___   ( (                 ( (         
    rdwr        _|   |_______) )_________|   |___) )_________________) )________
                            ( (                 ( (           ___   ( (         
    stop        _____________) )_________________) )_________|   |___) )________
                _ ___ ______( (_________________( (_________________( (_________
    slave_addr  _|VLD|_______) )_________________) )_________________) )________
                ____________( (_________________( (______ ___ ______( (_________
    data_r      _____________) )_________________) )_____|VLD|_______) )________
                _____       ( (       _______   ( (       _______   ( (   ______
    rdy              |_______) )_____|       |___) )_____|       |___) )_|      

*/

module i2c #(
        parameter SLAVEADDRWIDTH            = 7,
        parameter CLKPERIOD                 = 30,                       // In ns
        parameter I2CSPEED                  = 0                         // 0 = Standard, 1 = Fast, 2 = Fast+, 3 = Highspeed, 4 = Ultra Fast
    )(
        input                               clk,
        input                               resetf,
        input                               go,                         // Proceed in the State Machine
        input                               stop,                       // Stop the transaction
        output                              rdy,                        // FSM Ready signal
        input                               rdwr,                       // I2C Read/Write Bit
        input   [(SLAVEADDRWIDTH-1):0]      slave_addr,                 // The I2C Slave Address
        input   [7:0]                       data_w,                     // Data to Write Bus
        output  [7:0]                       data_r,                     // Data to Read Bus
        input                               clr_err,                    // Clear the Error Bits
        output                              err_addr,                   // Error Bit, Address Phase
        output                              err_dataw,                  // Error Bit, Data Write Phase
        output                              err_datar,                  // Error Bit, Data Read Phase
        // I2C Bus and Control
        inout                               sda,                        // I2C Bidirectional Data Bus
        inout                               scl                         // I2C Bidirectional Clock Bus
    );

    // Clock Multiple Parameters
    integer STDCNT      = (10000 / CLKPERIOD);                          // Multiple Counts for Standard Mode
    integer FASTCNT     = (2500 / CLKPERIOD);                           // Multiple Counts for Fast Mode
    integer FASTPCNT    = (1000 / CLKPERIOD);                           // Multiple Counts for Fast Plus Mode
    integer HIGHCNT     = (294 / CLKPERIOD);                            // Multiple Counts for Highspeed Mode
    integer UFASTCNT    = (200 / CLKPERIOD);                            // Multiple Counts for Ultra Fast Mode

    // Output Assignments
    assign sda = (sda_en == 1'b0) ? 1'b0 : 1'bZ;                        // SDA is driven by the enable
    assign scl = (scl_en == 1'b0) ? 1'b0 : 1'bZ;                        // SCL is driven by the enable
    assign rdy = rdy_y;
    assign data_r = data_ry;
    assign err_addr = err_addr_y;
    assign err_dataw = err_dataw_y;
    assign err_datar = err_datar_y;

    // Core State Machine
    typedef enum logic[2:0] {IDLE,START,ADDR,ADDRSTALL,WDATA,RDATA,DATASTALL} States;
    States state;

    // Logic Signals
    logic sda_en, scl_en, rdy_y, err_addr_y, err_dataw_y, err_datar_y;
    logic clkhi;
    logic [$clog2(STDCNT):0] divcnt;
    logic [3:0] bitcnt;
    logic [SLAVEADDRWIDTH:0] addr;
    logic [7:0] data_wy, data_ry;

    // Core FSM Logic
    always@(posedge clk) begin
        if(resetf == 1'b0) begin                                        // Synchronous Reset
            state                           <= IDLE;
            sda_en                          <= 1;                       // Active LO, HI-Z in Reset
            scl_en                          <= 1;                       // Active LO, HI-Z in Reset
            clkhi                           <= 0;
            rdy_y                           <= 0;                       // Not ready in reset
            divcnt                          <= 0;
            bitcnt                          <= 0;
            data_wy                         <= 0;
            data_ry                         <= 0;
            err_addr_y                      <= 0;                       // Error is active-HI
            err_dataw_y                     <= 0;                       // Error is active-HI
            err_datar_y                     <= 0;                       // Error is active-HI
        end
        else begin
            // Clear Error Bits
            if(clr_err == 1'b1) begin
                err_addr_y                  <= 0;                       // Clear error when commanded
                err_dataw_y                 <= 0;                       // Clear error when commanded
                err_datar_y                 <= 0;                       // Clear error when commanded
            end

            // FSM
            case(state)
                IDLE        : begin                                     /* IDLE State */
                    rdy_y                   <= 1'b1;                    // Ready in IDLE
                    if(go == 1'b1) begin
                        state               <= START;                   // Go to the Address Phase
                        divcnt              <= 0;                       // Reset the division counter
                        bitcnt              <= 0;                       // Reset the bit counter
                        addr                <= {slave_addr,rdwr};       // Snapshot the Slave Address and the RDWR Bit
                        rdy_y               <= 1'b0;                    // Not ready leaving IDLE
                    end
                end

                START       : begin                                     /* START State */
                    if(divcnt == (STDCNT/4)) begin                      // At quarter-count, drive SDA LO
                        sda_en              <= 1'b0;
                    end
                    else if(divcnt == (STDCNT/2)) begin                 // At half-count, drive SCL LO
                        scl_en              <= 1'b0;
                        divcnt              <= 0;                       // Reset the Divide Counter
                        state               <= ADDR;
                    end
                    else begin
                        divcnt              <= divcnt + 1;
                    end
                end

                ADDR        : begin                                     /* ADDR State */
                    if(divcnt == (STDCNT/4)) begin                      // At quarter-count, drive out SDA
                        sda_en              <= addr[(SLAVEADDRWIDTH-bitcnt)];
                    end
                    else if(divcnt == (STDCNT/2)) begin                 // At half-count, toggle the SCL to HI
                        scl_en              <= 1'b1;
                        clkhi               <= 1'b1;                    // Signal we're driving clock HI
                    end
                    else if(divcnt == (STDCNT)) begin                   // At full-count, toggle the SCL back to LO
                        scl_en              <= 1'b0;
                        divcnt              <= 0;
                        clkhi               <= 0;                       // Clear the clock HI bit
                        bitcnt              <= bitcnt + 1;
                        if(bitcnt == SLAVEADDRWIDTH) begin
                            state           <= ADDRACK;                 // Check Address ACK
                            bitcnt          <= 0;
                        end
                        else begin
                            state           <= ADDR;
                        end
                    end
                    else if((clkhi == 1'b1) && (sda == 1'b1)) begin     // If we've started driving the clock HI, handle clock stretching
                        divcnt              <= divcnt + 1;
                    end
                    else if(clkhi == 1'b0) begin                        // If we aren't driving the clock HI yet, simply increment
                        divcnt              <= divcnt + 1;
                    end
                end

                ADDRACK     : begin
                    if(divcnt == (STDCNT/4)) begin                      // At half-count, toggle the SCL to HI
                        sda_en          <= 1'b1;                        // Release the SDA Bus for ACK
                    end
                    else if(divcnt == (STDCNT/2)) begin                 // At half-count, toggle the SCL to HI
                        scl_en              <= 1'b1;
                        clkhi               <= 1'b1;                    // Signal we're driving clock HI
                    end
                    else if(divcnt == (STDCNT)) begin                   // At full-count, toggle the SCL back to LO
                        scl_en              <= 1'b0;                    // Stalling occurs when SCL is LO so this is legit
                        divcnt              <= 0;
                        clkhi               <= 0;                       // Clear the clock HI bit
                        if(sda == 1'b0) begin                           // If the device ACK'd, keep going
                            state           <= ADDRSTALL;               // Stall for top-level interaction
                            rdy_y           <= 1'b1;                    // We're now ready
                        end
                        else begin
                            err_addr_y      <= 1'b1;                    // If nACK, throw error return to IDLE
                            state           <= IDLE;
                        end
                    end
                    else if((clkhi == 1'b1) && (sda == 1'b1)) begin     // If we've started driving the clock HI, handle clock stretching
                        divcnt              <= divcnt + 1;
                    end
                    else if(clkhi == 1'b0) begin                        // If we aren't driving the clock HI yet, simply increment
                        divcnt              <= divcnt + 1;
                    end
                end

                ADDRSTALL   : begin                                     /* ADDRSTALL State */
                    if(go == 1'b1) begin
                        if(rdwr == 1'b1) begin                          // The next byte is being Read
                            state           <= RDATA;
                            rdy_y           <= 1'b0;                    // Not ready when going to read
                        end
                        else begin                                      // The next byte is being Written
                            state           <= WDATA;
                            rdy_y           <= 1'b0;                    // Not ready when going to write
                            data_wy         <= data_w;                  // Snapshot the data to write
                        end
                    end
                    else if(stop == 1'b1) begin                         // For whatever reason, it is possible to STOP after the slave address phase
                        state               <= STOP;
                        rdy_y               <= 1'b0;                    // Not ready when going to stop
                    end
                end

                WDATA       : begin                                     /* WDATA State */
                    if(divcnt == (STDCNT/4)) begin                      // At quarter-count, drive out SDA
                        sda_en              <= data_wy[(7-bitcnt)];
                    end
                    else if(divcnt == (STDCNT/2)) begin                 // At half-count, toggle the SCL to HI
                        scl_en              <= 1'b1;
                        clkhi               <= 1'b1;                    // Signal we're driving clock HI
                    end
                    else if(divcnt == (STDCNT)) begin                   // At full-count, toggle the SCL back to LO
                        scl_en              <= 1'b0;                    // Stalling occurs when SCL is LO so this is legit
                        divcnt              <= 0;
                        clkhi               <= 0;                       // Clear the clock HI bit
                        bitcnt              <= bitcnt + 1;
                        if(bitcnt == 7) begin
                            state           <= WDATAACK;                // Wait for ACK
                            bitcnt          <= 0;
                        end
                        else begin
                            state           <= WDATA;                   // Stay here if we're still writing
                        end
                    end
                    else if((clkhi == 1'b1) && (sda == 1'b1)) begin     // If we've started driving the clock HI, handle clock stretching
                        divcnt              <= divcnt + 1;
                    end
                    else if(clkhi == 1'b0) begin                        // If we aren't driving the clock HI yet, simply increment
                        divcnt              <= divcnt + 1;
                    end
                end

                WDATAACK    : begin
                    if(divcnt == (STDCNT/4)) begin                      // At half-count, toggle the SCL to HI
                        sda_en          <= 1'b1;                        // Release the SDA Bus for ACK
                    end
                    else if(divcnt == (STDCNT/2)) begin                 // At half-count, toggle the SCL to HI
                        scl_en              <= 1'b1;
                        clkhi               <= 1'b1;                    // Signal we're driving clock HI
                    end
                    else if(divcnt == (STDCNT)) begin                   // At full-count, toggle the SCL back to LO
                        scl_en              <= 1'b0;                    // Stalling occurs when SCL is LO so this is legit
                        divcnt              <= 0;
                        clkhi               <= 0;                       // Clear the clock HI bit
                        if(sda == 1'b0) begin                           // If the device ACK'd, keep going
                            state           <= DATASTALL;               // Stall for top-level interaction
                            rdy_y           <= 1'b1;                    // We're now ready
                        end
                        else begin
                            state           <= STOP;
                            err_dataw_y     <= 1'b1;                    // If nACK, throw error return to IDLE
                        end
                    end
                    else if((clkhi == 1'b1) && (sda == 1'b1)) begin     // If we've started driving the clock HI, handle clock stretching
                        divcnt              <= divcnt + 1;
                    end
                    else if(clkhi == 1'b0) begin                        // If we aren't driving the clock HI yet, simply increment
                        divcnt              <= divcnt + 1;
                    end
                end

                RDATA       : begin                                     /* RDATA State */
                    if(divcnt == (STDCNT/4)) begin                      // At quarter-count, read in SDA
                        data_ry[(7-bitcnt)] <= sda;
                    end
                    else if(divcnt == (STDCNT/2)) begin                 // At half-count, toggle the SCL to HI
                        scl_en              <= 1'b1;
                        clkhi               <= 1'b1;                    // Signal we're driving clock HI
                    end
                    else if(divcnt == (STDCNT)) begin                   // At full-count, toggle the SCL back to LO
                        scl_en              <= 1'b0;                    // Stalling occurs when SCL is LO so this is legit
                        divcnt              <= 0;
                        clkhi               <= 0;                       // Clear the clock HI bit
                        bitcnt              <= bitcnt + 1;
                        if(bitcnt == 7) begin
                            state           <= RDATAACK;                // Wait for ACK
                            bitcnt          <= 0;
                        end
                        else begin
                            state           <= RDATA;                   // Stay here if we're still reading
                        end
                    end
                    else if((clkhi == 1'b1) && (sda == 1'b1)) begin     // If we've started driving the clock HI, handle clock stretching
                        divcnt              <= divcnt + 1;
                    end
                    else if(clkhi == 1'b0) begin                        // If we aren't driving the clock HI yet, simply increment
                        divcnt              <= divcnt + 1;
                    end
                end

                RDATAACK    : begin
                    if(divcnt == (STDCNT/4)) begin                      // At half-count, toggle the SCL to HI
                        sda_en          <= 1'b0;                        // ACK
                    end
                    else if(divcnt == (STDCNT/2)) begin                 // At half-count, toggle the SCL to HI
                        scl_en              <= 1'b1;
                        clkhi               <= 1'b1;                    // Signal we're driving clock HI
                    end
                    else if(divcnt == (STDCNT)) begin                   // At full-count, toggle the SCL back to LO
                        scl_en              <= 1'b0;                    // Stalling occurs when SCL is LO so this is legit
                        divcnt              <= 0;
                        clkhi               <= 0;                       // Clear the clock HI bit
                        state               <= DATASTALL;               // Stall for top-level interaction
                        rdy_y               <= 1'b1;                    // We're now ready
                    end
                    else if((clkhi == 1'b1) && (sda == 1'b1)) begin     // If we've started driving the clock HI, handle clock stretching
                        divcnt              <= divcnt + 1;
                    end
                    else if(clkhi == 1'b0) begin                        // If we aren't driving the clock HI yet, simply increment
                        divcnt              <= divcnt + 1;
                    end
                end

                DATASTALL   : begin                                     /* DATASTALL State */
                    if(go == 1'b1) begin
                        if(rdwr == 1'b1) begin                          // The next byte is being Read
                            state           <= RDATA;
                            rdy_y           <= 1'b0;                    // Not ready when going to read
                        end
                        else begin                                      // The next byte is being Written
                            state           <= WDATA;
                            rdy_y           <= 1'b0;                    // Not ready when going to write
                            data_wy         <= data_w;                  // Snapshot the data to write
                        end
                    end
                    else if(stop == 1'b1) begin
                        state               <= STOP;
                        rdy_y               <= 1'b0;                    // Not ready when going to stop
                    end
                end

                STOP        : begin
                    if(divcnt == (STDCNT/4)) begin                      // At quarter-count, drive SDA LO
                        sda_en              <= 1'b0;                    // STOP signal, SDA must be LO to start
                    end
                    else if(divcnt == (STDCNT/2)) begin                 // At half-count, drive SCL LO
                        scl_en              <= 1'b0;
                    end
                    else if(divcnt == ((STDCNT/4)+(STDCNT/2)))begin
                        sda_en              <= 1'b1;                    // Transition while Clock is HI, STOP
                        clkhi               <= 1'b1;                    // Signal we're driving clock HI
                    end
                    else if(divcnt == (STDCNT)) begin
                        scl_en              <= 1'b1;
                        sda_en              <= 1'b1;
                        divcnt              <= 0;
                        state               <= IDLE;                    // SDA, SCL go HI-Z, return to IDLE
                    end
                    else if((clkhi == 1'b1) && (sda == 1'b1)) begin     // If we've started driving the clock HI, handle clock stretching
                        divcnt              <= divcnt + 1;
                    end
                    else if(clkhi == 1'b0) begin                        // If we aren't driving the clock HI yet, simply increment
                        divcnt              <= divcnt + 1;
                    end
                end

                default     : begin
                    scl_en                  <= 1'b1;
                    sda_en                  <= 1'b1;
                    divcnt                  <= 0;
                    bitcnt                  <= 0;
                    state                   <= IDLE;
                end
            endcase
        end
    end

endmodule
