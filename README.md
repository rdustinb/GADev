The purpose of this repository is to have a central location to capture all of the functional FPGA source code into a concise library based on type of function. This will be my primary FPGA development repository from now on and all other repos will soon be merged into this.

SRIO AXIS Packet Generator
===
This module generates random deterministic data payloads for the 
Xilinx SRIO Endpoint. This module utilizes the HELLO Header format
as specified in the Xilinx PG document:

http://www.xilinx.com/support/documentation/ip_documentation/srio_gen2/v2_0/pg007_srio_gen2.pdf

This module utilizes SystemVerilog constructs and was simulated with
QuestaSim 10.2.

Merge Sort
===
This design block provides the ability to sort up to 16 binary numbers. The block will output the original numbers, though sorted from lowest (position 0) to highest (position n-1).

The number of clock cycles delay required to process the ordering of all input numbers is based on the next highest value of 2^n - 1. Meaning if 3 values are being sorted, then the total clock cycle latency is (2^2 = 4) - 1 = 3 clock cycles. If 5 numbers are being sorted, then the total clock cycle latency is (2^3 = 8) - 1 = 7 clock cycles.

The block also provides an output of values signifying the input positional oputput transposition. Meaning, given the following inputs:

 * 0 - 16
 * 1 - 27
 * 2 - 7
 * 3 - 19

The output bus "sorted_positions" would be:

 * 2 - in sorted_positions[0]
 * 0 - in sorted_positions[1]
 * 3 - in sorted_positions[2]
 * 1 - in sorted_positions[3]

This bus is good for dereferencing memories of stored numbers, or maybe creating a priority queue of some kind.

Unused number inputs should be loaded with all 1s, where the used number inputs should be stacked at the bottom of the input number ports for logical consistency.

Synplify Pro Timing and Utilization Results, Targetting a Virtex 7
---
Compare 2 values
---
```
Clock              Constraint f   Estimated f   Slack 
merge_sort|clk     200.0 MHz      393.0 MHz     2.456
System             200.0 MHz      476.9 MHz     2.903
```

Mapping to part: **xc7vx690tffg1927-2**

Cell usage:

 * CARRY4          4 uses
 * FD              5 uses
 * FDR             1 use
 * FDRE            64 uses
 * GND             1 use
 * VCC             1 use
 * LUT3            66 uses
 * LUT4            32 uses
 * LUT5            4 uses
 * I/O ports: 136
 * I/O primitives: 136
 * IBUF           66 uses
 * IBUFG          1 use
 * OBUF           69 uses
 * BUFG           1 use

Compare 4 values
---
```
Clock              Constraint f   Estimated f   Slack 
merge_sort|clk     200.0 MHz      339.2 MHz     2.052
System             200.0 MHz      384.6 MHz     2.400
```

Mapping to part: **xc7vx690tffg1927-2**

Cell usage:

 * CARRY4          20 uses
 * FD              9 uses
 * FDR             7 uses
 * FDRE            274 uses
 * GND             1 use
 * VCC             1 use
 * LUT2            5 uses
 * LUT3            4 uses
 * LUT4            167 uses
 * LUT5            193 uses
 * LUT6            150 uses
 * I/O ports: 272
 * I/O primitives: 272
 * IBUF           130 uses
 * IBUFG          1 use
 * OBUF           141 uses
 * BUFG           1 use

Compare 8 values
---
```
Clock              Constraint f   Estimated f   Slack 
merge_sort|clk     200.0 MHz      282.2 MHz     1.456
System             200.0 MHz      349.4 MHz     2.138
```

Mapping to part: **xc7vx690tffg1927-2**

Cell usage:
 
 * CARRY4          80 uses
 * FD              15 uses
 * FDR             2 uses
 * FDRE            576 uses
 * GND             1 use
 * VCC             1 use
 * LUT2            12 uses
 * LUT3            20 uses
 * LUT4            787 uses
 * LUT5            221 uses
 * LUT6            727 uses
 * I/O ports: 548
 * I/O primitives: 548
 * IBUF           258 uses
 * IBUFG          1 use
 * OBUF           289 uses
 * BUFG           1 use

Compare 16 values
---
```
Clock              Constraint f   Estimated f   Slack 
merge_sort|clk     200.0 MHz      274.4 MHz     1.355
System             200.0 MHz      329.1 MHz     1.962    
```

Mapping to part: **xc7vx690tffg1927-2**

Cell usage:
 
 * CARRY4          304 uses
 * FD              18 uses
 * FDR             11 uses
 * FDRE            1184 uses
 * GND             1 use
 * MUXF7           1 use
 * VCC             1 use
 * LUT2            25 uses
 * LUT3            59 uses
 * LUT4            2546 uses
 * LUT5            513 uses
 * LUT6            2666 uses
 * I/O ports: 1108
 * I/O primitives: 1108
 * IBUF           514 uses
 * IBUFG          1 use
 * OBUF           593 uses
 * BUFG           1 use
