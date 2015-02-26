
module merge_sort #(
        parameter RSTPOL                                    = 0,
        parameter INPUTVALS                                 = 16,
        parameter INPUTBITWIDTHS                            = 32
    )(
        input                                               clk,
        input                                               reset,
        input                                               sortstart,          // Start the sorting, takes a few clock cycles
        input       [(INPUTVALS-1):0][(INPUTBITWIDTHS-1):0] needs_sorting,      // List of values that needs sorting
        output                                              sortdone,           // Flag goes HI when sorting is done
        output      [(INPUTVALS-1):0][(INPUTBITWIDTHS-1):0] sorted,             // List of input values in ascending order
        output      [(INPUTVALS-1):0][$clog2(INPUTVALS):0]  sorted_positions    // List of input positions, sorted by their values in ascending order
    );

    // Control Parameters

    // Enumerations
    typedef enum logic[3:0] {IDLE,MERGE2,MERGE4,MERGE8,MERGE16,MERGE32} States;
    States sort_fsm;

    // Signals
    logic step1, step2, step3, step4, step5, step6, step7;
    logic sortdone_y;
    logic [(INPUTVALS-1):0][(INPUTBITWIDTHS-1):0] working_set;
    logic [(INPUTVALS-1):0][$clog2(INPUTVALS):0] positions_y;

    // Output Assignments
    assign sortdone = sortdone_y;
    assign sorted = working_set;
    assign sorted_positions = positions_y;

    always@(posedge clk) begin
        if(reset == RSTPOL) begin
            working_set <= 0;
            sortdone_y <= 0;
            step1 <= 0;
            step2 <= 0;
            step3 <= 0;
            step4 <= 0;
            step5 <= 0;
            step6 <= 0;
            step7 <= 0;
            positions_y <= 0;
            sort_fsm <= IDLE;
        end
        else begin
            // Defaults
            sortdone_y <= 0;
            // FSM
            case(sort_fsm)
                IDLE        : begin
                    if(sortstart) begin
                        sort_fsm <= MERGE2;
                        working_set <= needs_sorting;
                        // Prime the positions array
                        for(int i=0; i<INPUTVALS; i++) begin
                            positions_y[i] <= i;
                        end
                    end
                end
    /***************************************************************************
    Compare and Swap (Number indicates position of working array only)
        _____     _____     _____     _____   ...   _____     _____
       |     |   |     |   |     |   |     |  ...  |     |   |     |
       |  0  |<->|  1  |   |  2  |<->|  3  |  ...  | n-1 |<->|  n  |
       |_____|   |_____|   |_____|   |_____|  ...  |_____|   |_____|

    Logically Merged (Number indicates position of working array only)
        _____ _____     _____ _____   ...   _____ _____
       |     |     |   |     |     |  ...  |     |     |
       |  0  |  1  |   |  2  |  3  |  ...  | n-1 |  n  |
       |_____|_____|   |_____|_____|  ...  |_____|_____|
    ***************************************************************************/
                MERGE2       : begin
                    // 1 Clock-Cycle Latency
                    // Do this for each block of 2 values
                    for(int i=0; i<(INPUTVALS/2); i++) begin
                        // If the sets 0,1 2,3 4,5 etc, are out of order, switch values
                        if(working_set[0+(i*2)] > working_set[1+(i*2)]) begin
                            {working_set[0+(i*2)], working_set[1+(i*2)]} <= {working_set[1+(i*2)], working_set[0+(i*2)]};
                            {positions_y[0+(i*2)], positions_y[1+(i*2)]} <= {positions_y[1+(i*2)], positions_y[0+(i*2)]};
                        end
                    end
                    if(INPUTVALS >= 4) begin
                        sort_fsm <= MERGE4;
                    end
                    else begin
                        sort_fsm <= IDLE;
                        sortdone_y <= 1;
                    end
                end
    /***************************************************************************
    Compare and Swap (Number indicates position of working array only)
        Step 1
        ___ ___     ___ ___     ___ ___     ___ ___   ...   ___ ___     ___ ___
       |   |   |   |   |   |   |   |   |   |   |   |  ...  |   |   |   |   |   |
       | 0 | 1 |<->| 2 | 3 |   | 4 | 5 |<->| 6 | 7 |  ...  |n-3|n-2|<->|n-1| n |
       |___|___|   |___|___|   |___|___|   |___|___|  ...  |___|___|   |___|___|

        Step 2
        ___ ___     ___ ___     ___ ___     ___ ___   ...   ___ ___     ___ ___
       |   |   |   |   |   |   |   |   |   |   |   |  ...  |   |   |   |   |   |
       | 0 | 1 |   | 2 | 3 |<->| 4 | 5 |   | 6 | 7 |<-...->|n-3|n-2|   |n-1| n |
       |___|___|   |___|___|   |___|___|   |___|___|  ...  |___|___|   |___|___|

    Logically Merged (Number indicates position of working array only)
        ___ ___ ___ ___     ___ ___ ___ ___   ...   ___ ___ ___ ___
       |   |   |   |   |   |   |   |   |   |  ...  |   |   |   |   |
       | 0 | 1 | 2 | 3 |   | 4 | 5 | 6 | 7 |  ...  |n-3|n-2|n-1| n |
       |___|___|___|___|   |___|___|___|___|  ...  |___|___|___|___|
    ***************************************************************************/
                MERGE4       : begin
                    // 2 Clock-Cycle Latency
                    if(step1 == 0) begin
                        // Do this for each block of 4 values
                        for(int i=0; i<(INPUTVALS/4); i++) begin
                            // If the sets 01,23 45,67 etc, are out of order, switch values
                            if(working_set[0+(i*4)] > working_set[2+(i*4)]) begin
                                {working_set[0+(i*4)], working_set[2+(i*4)]} <= {working_set[2+(i*4)], working_set[0+(i*4)]};
                                {positions_y[0+(i*4)], positions_y[2+(i*4)]} <= {positions_y[2+(i*4)], positions_y[0+(i*4)]};
                            end
                            if(working_set[1+(i*4)] > working_set[3+(i*4)]) begin
                                {working_set[1+(i*4)], working_set[3+(i*4)]} <= {working_set[3+(i*4)], working_set[1+(i*4)]};
                                {positions_y[1+(i*4)], positions_y[3+(i*4)]} <= {positions_y[3+(i*4)], positions_y[1+(i*4)]};
                            end
                        end
                        step1 <= 1;
                    end
                    else begin
                        // Do this for each block of 4 values
                        for(int i=0; i<(INPUTVALS/4); i++) begin
                            // For the sets 01,23 45,67 etc, swap middle values
                            if(working_set[1+(i*4)] > working_set[2+(i*4)]) begin
                                {working_set[1+(i*4)], working_set[2+(i*4)]} <= {working_set[2+(i*4)], working_set[1+(i*4)]};
                                {positions_y[1+(i*4)], positions_y[2+(i*4)]} <= {positions_y[2+(i*4)], positions_y[1+(i*4)]};
                            end
                        end
                        step1 <= 0;
                        if(INPUTVALS >= 8) begin
                            sort_fsm <= MERGE8;
                        end
                        else begin
                            sort_fsm <= IDLE;
                            sortdone_y <= 1;
                        end
                    end
                end
    /***************************************************************************
    Compare and Swap
        Step 1 - Compare all sets of fours, within a set of 8. Meaning position
            0123 values are compared with positions 4567 but NOT 89AB.
        Step 2 - Compare all sets of fours, within a set of 8, offset 1 on the
            first set. Meaning compare 123 to 456.
        Step 3 - Compare all sets of fours, within a set of 8, offset 2 on the
            first set. Meaning 23 to 45.
        Step 4 - Compare all sets of fours, within a set of 8, offset 3 on the
            first set. Meaning compare 3 to 4.

    Logically Merged (Number indicates position of working array only)
         _ _ _ _ _ _ _ _       ___ ___ ___ ___ ___ ___ ___ ___
        |0|1|2|3|4|5|6|7| ... |n-7|n-6|n-5|n-4|n-3|n-2|n-1| n |

    ***************************************************************************/
                MERGE8       : begin
                    // 4 Clock-Cycle Latency
                    if(step1 == 0) begin
                        // Do this for each block of 8 values
                        for(int i=0; i<(INPUTVALS/8); i++) begin
                            // If the sets 0123,4567 etc, are out of order, switch values
                            if(working_set[0+(i*8)] > working_set[4+(i*8)]) begin
                                {working_set[0+(i*8)], working_set[4+(i*8)]} <= {working_set[4+(i*8)], working_set[0+(i*8)]};
                                {positions_y[0+(i*8)], positions_y[4+(i*8)]} <= {positions_y[4+(i*8)], positions_y[0+(i*8)]};
                            end
                            if(working_set[1+(i*8)] > working_set[5+(i*8)]) begin
                                {working_set[1+(i*8)], working_set[5+(i*8)]} <= {working_set[5+(i*8)], working_set[1+(i*8)]};
                                {positions_y[1+(i*8)], positions_y[5+(i*8)]} <= {positions_y[5+(i*8)], positions_y[1+(i*8)]};
                            end
                            if(working_set[2+(i*8)] > working_set[6+(i*8)]) begin
                                {working_set[2+(i*8)], working_set[6+(i*8)]} <= {working_set[6+(i*8)], working_set[2+(i*8)]};
                                {positions_y[2+(i*8)], positions_y[6+(i*8)]} <= {positions_y[6+(i*8)], positions_y[2+(i*8)]};
                            end
                            if(working_set[3+(i*8)] > working_set[7+(i*8)]) begin
                                {working_set[3+(i*8)], working_set[7+(i*8)]} <= {working_set[7+(i*8)], working_set[3+(i*8)]};
                                {positions_y[3+(i*8)], positions_y[7+(i*8)]} <= {positions_y[7+(i*8)], positions_y[3+(i*8)]};
                            end
                        end
                        step1 <= 1;
                    end
                    else if(step2 == 0) begin
                        // Do this for each block of 8 values
                        for(int i=0; i<(INPUTVALS/8); i++) begin
                            // Compare 1-3 to 4-6
                            if(working_set[1+(i*8)] > working_set[4+(i*8)]) begin
                                {working_set[1+(i*8)], working_set[4+(i*8)]} <= {working_set[4+(i*8)], working_set[1+(i*8)]};
                                {positions_y[1+(i*8)], positions_y[4+(i*8)]} <= {positions_y[4+(i*8)], positions_y[1+(i*8)]};
                            end
                            if(working_set[2+(i*8)] > working_set[5+(i*8)]) begin
                                {working_set[2+(i*8)], working_set[5+(i*8)]} <= {working_set[5+(i*8)], working_set[2+(i*8)]};
                                {positions_y[2+(i*8)], positions_y[5+(i*8)]} <= {positions_y[5+(i*8)], positions_y[2+(i*8)]};
                            end
                            if(working_set[3+(i*8)] > working_set[6+(i*8)]) begin
                                {working_set[3+(i*8)], working_set[6+(i*8)]} <= {working_set[6+(i*8)], working_set[3+(i*8)]};
                                {positions_y[3+(i*8)], positions_y[6+(i*8)]} <= {positions_y[6+(i*8)], positions_y[3+(i*8)]};
                            end
                        end
                        step2 <= 1;
                    end
                    else if(step3 == 0) begin
                        // Do this for each block of 8 values
                        for(int i=0; i<(INPUTVALS/8); i++) begin
                            // Compare 2-3 to 4-5
                            if(working_set[2+(i*8)] > working_set[4+(i*8)]) begin
                                {working_set[2+(i*8)], working_set[4+(i*8)]} <= {working_set[4+(i*8)], working_set[2+(i*8)]};
                                {positions_y[2+(i*8)], positions_y[4+(i*8)]} <= {positions_y[4+(i*8)], positions_y[2+(i*8)]};
                            end
                            if(working_set[3+(i*8)] > working_set[5+(i*8)]) begin
                                {working_set[3+(i*8)], working_set[5+(i*8)]} <= {working_set[5+(i*8)], working_set[3+(i*8)]};
                                {positions_y[3+(i*8)], positions_y[5+(i*8)]} <= {positions_y[5+(i*8)], positions_y[3+(i*8)]};
                            end
                        end
                        step3 <= 1;
                    end
                    else begin
                        // Do this for each block of 8 values
                        for(int i=0; i<(INPUTVALS/8); i++) begin
                            // Compare 3 to 4
                            if(working_set[3+(i*8)] > working_set[4+(i*8)]) begin
                                {working_set[3+(i*8)], working_set[4+(i*8)]} <= {working_set[4+(i*8)], working_set[3+(i*8)]};
                                {positions_y[3+(i*8)], positions_y[4+(i*8)]} <= {positions_y[4+(i*8)], positions_y[3+(i*8)]};
                            end
                        end
                        step1 <= 0;
                        step2 <= 0;
                        step3 <= 0;
                        if(INPUTVALS >= 16) begin
                            sort_fsm <= MERGE16;
                        end
                        else begin
                            sort_fsm <= IDLE;
                            sortdone_y <= 1;
                        end
                    end
                end
    /***************************************************************************
    Compare and Swap
        Step 1 - Compare all sets of eights, within a set of 16. Meaning position
            0|1|2|3|5|6|7|8 values are compared with positions 8|9|A|B|C|D|E|F but
            NOT positions 10|11|12|13|14|15|16|17.
        Step 2 - Compare all sets of eights, within a set of 16, offset 1 on the
            first set. Meaning compare 1|2|3|4|5|6|7 to 8|9|A|B|C|D|E.
        Step 3 - Compare all sets of eights, within a set of 16, offset 2 on the
            first set. Meaning compare 2|3|4|5|6|7 to 8|9|A|B|C|D.
        Step 4 - Compare all sets of eights, within a set of 16, offset 3 on the
            first set. Meaning compare 3|4|5|6|7 to 8|9|A|B|C.
        Step 5 - Compare all sets of eights, within a set of 16, offset 4 on the
            first set. Meaning compare 4|5|6|7 to 8|9|A|B.
        Step 6 - Compare all sets of eights, within a set of 16, offset 5 on the
            first set. Meaning compare 5|6|7 to 8|9|A.
        Step 7 - Compare all sets of eights, within a set of 16, offset 6 on the
            first set. Meaning compare 6|7 to 8|9.
        Step 8 - Compare all sets of eights, within a set of 16, offset 7 on the
            first set. Meaning compare 7 to 8.
    ***************************************************************************/
                MERGE16      : begin
                    // 8 Clock-Cycle Latency
                    if(step1 == 0) begin
                        // Do this for each block of 16 values
                        for(int i=0; i<(INPUTVALS/16); i++) begin
                            // If the sets 01234567,89ABCDEF etc, are out of order, switch values
                            if(working_set[0+(i*16)] > working_set[8+(i*16)]) begin
                                {working_set[0+(i*16)], working_set[8+(i*16)]} <= {working_set[8+(i*16)], working_set[0+(i*16)]};
                                {positions_y[0+(i*16)], positions_y[8+(i*16)]} <= {positions_y[8+(i*16)], positions_y[0+(i*16)]};
                            end
                            if(working_set[1+(i*16)] > working_set[9+(i*16)]) begin
                                {working_set[1+(i*16)], working_set[9+(i*16)]} <= {working_set[9+(i*16)], working_set[1+(i*16)]};
                                {positions_y[1+(i*16)], positions_y[9+(i*16)]} <= {positions_y[9+(i*16)], positions_y[1+(i*16)]};
                            end
                            if(working_set[2+(i*16)] > working_set[10+(i*16)]) begin
                                {working_set[2+(i*16)], working_set[10+(i*16)]} <= {working_set[10+(i*16)], working_set[2+(i*16)]};
                                {positions_y[2+(i*16)], positions_y[10+(i*16)]} <= {positions_y[10+(i*16)], positions_y[2+(i*16)]};
                            end
                            if(working_set[3+(i*16)] > working_set[11+(i*16)]) begin
                                {working_set[3+(i*16)], working_set[11+(i*16)]} <= {working_set[11+(i*16)], working_set[3+(i*16)]};
                                {positions_y[3+(i*16)], positions_y[11+(i*16)]} <= {positions_y[11+(i*16)], positions_y[3+(i*16)]};
                            end
                            if(working_set[4+(i*16)] > working_set[12+(i*16)]) begin
                                {working_set[4+(i*16)], working_set[12+(i*16)]} <= {working_set[12+(i*16)], working_set[4+(i*16)]};
                                {positions_y[4+(i*16)], positions_y[12+(i*16)]} <= {positions_y[12+(i*16)], positions_y[4+(i*16)]};
                            end
                            if(working_set[5+(i*16)] > working_set[13+(i*16)]) begin
                                {working_set[5+(i*16)], working_set[13+(i*16)]} <= {working_set[13+(i*16)], working_set[5+(i*16)]};
                                {positions_y[5+(i*16)], positions_y[13+(i*16)]} <= {positions_y[13+(i*16)], positions_y[5+(i*16)]};
                            end
                            if(working_set[6+(i*16)] > working_set[14+(i*16)]) begin
                                {working_set[6+(i*16)], working_set[14+(i*16)]} <= {working_set[14+(i*16)], working_set[6+(i*16)]};
                                {positions_y[6+(i*16)], positions_y[14+(i*16)]} <= {positions_y[14+(i*16)], positions_y[6+(i*16)]};
                            end
                            if(working_set[7+(i*16)] > working_set[15+(i*16)]) begin
                                {working_set[7+(i*16)], working_set[15+(i*16)]} <= {working_set[15+(i*16)], working_set[7+(i*16)]};
                                {positions_y[7+(i*16)], positions_y[15+(i*16)]} <= {positions_y[15+(i*16)], positions_y[7+(i*16)]};
                            end
                        end
                        step1 <= 1;
                    end
                    else if(step2 == 0) begin
                        // Do this for each block of 16 values
                        for(int i=0; i<(INPUTVALS/16); i++) begin
                            // Compare 1234567 to 89ABCDE
                            if(working_set[1+(i*16)] > working_set[8+(i*16)]) begin
                                {working_set[1+(i*16)], working_set[8+(i*16)]} <= {working_set[8+(i*16)], working_set[1+(i*16)]};
                                {positions_y[1+(i*16)], positions_y[8+(i*16)]} <= {positions_y[8+(i*16)], positions_y[1+(i*16)]};
                            end
                            if(working_set[2+(i*16)] > working_set[9+(i*16)]) begin
                                {working_set[2+(i*16)], working_set[9+(i*16)]} <= {working_set[9+(i*16)], working_set[2+(i*16)]};
                                {positions_y[2+(i*16)], positions_y[9+(i*16)]} <= {positions_y[9+(i*16)], positions_y[2+(i*16)]};
                            end
                            if(working_set[3+(i*16)] > working_set[10+(i*16)]) begin
                                {working_set[3+(i*16)], working_set[10+(i*16)]} <= {working_set[10+(i*16)], working_set[3+(i*16)]};
                                {positions_y[3+(i*16)], positions_y[10+(i*16)]} <= {positions_y[10+(i*16)], positions_y[3+(i*16)]};
                            end
                            if(working_set[4+(i*16)] > working_set[11+(i*16)]) begin
                                {working_set[4+(i*16)], working_set[11+(i*16)]} <= {working_set[11+(i*16)], working_set[4+(i*16)]};
                                {positions_y[4+(i*16)], positions_y[11+(i*16)]} <= {positions_y[11+(i*16)], positions_y[4+(i*16)]};
                            end
                            if(working_set[5+(i*16)] > working_set[12+(i*16)]) begin
                                {working_set[5+(i*16)], working_set[12+(i*16)]} <= {working_set[12+(i*16)], working_set[5+(i*16)]};
                                {positions_y[5+(i*16)], positions_y[12+(i*16)]} <= {positions_y[12+(i*16)], positions_y[5+(i*16)]};
                            end
                            if(working_set[6+(i*16)] > working_set[13+(i*16)]) begin
                                {working_set[6+(i*16)], working_set[13+(i*16)]} <= {working_set[13+(i*16)], working_set[6+(i*16)]};
                                {positions_y[6+(i*16)], positions_y[13+(i*16)]} <= {positions_y[13+(i*16)], positions_y[6+(i*16)]};
                            end
                            if(working_set[7+(i*16)] > working_set[14+(i*16)]) begin
                                {working_set[7+(i*16)], working_set[14+(i*16)]} <= {working_set[14+(i*16)], working_set[7+(i*16)]};
                                {positions_y[7+(i*16)], positions_y[14+(i*16)]} <= {positions_y[14+(i*16)], positions_y[7+(i*16)]};
                            end
                        end
                        step2 <= 1;
                    end
                    else if(step3 == 0) begin
                        // Do this for each block of 16 values
                        for(int i=0; i<(INPUTVALS/16); i++) begin
                            // Compare 234567 to 89ABCD
                            if(working_set[2+(i*16)] > working_set[8+(i*16)]) begin
                                {working_set[2+(i*16)], working_set[8+(i*16)]} <= {working_set[8+(i*16)], working_set[2+(i*16)]};
                                {positions_y[2+(i*16)], positions_y[8+(i*16)]} <= {positions_y[8+(i*16)], positions_y[2+(i*16)]};
                            end
                            if(working_set[3+(i*16)] > working_set[9+(i*16)]) begin
                                {working_set[3+(i*16)], working_set[9+(i*16)]} <= {working_set[9+(i*16)], working_set[3+(i*16)]};
                                {positions_y[3+(i*16)], positions_y[9+(i*16)]} <= {positions_y[9+(i*16)], positions_y[3+(i*16)]};
                            end
                            if(working_set[4+(i*16)] > working_set[10+(i*16)]) begin
                                {working_set[4+(i*16)], working_set[10+(i*16)]} <= {working_set[10+(i*16)], working_set[4+(i*16)]};
                                {positions_y[4+(i*16)], positions_y[10+(i*16)]} <= {positions_y[10+(i*16)], positions_y[4+(i*16)]};
                            end
                            if(working_set[5+(i*16)] > working_set[11+(i*16)]) begin
                                {working_set[5+(i*16)], working_set[11+(i*16)]} <= {working_set[11+(i*16)], working_set[5+(i*16)]};
                                {positions_y[5+(i*16)], positions_y[11+(i*16)]} <= {positions_y[11+(i*16)], positions_y[5+(i*16)]};
                            end
                            if(working_set[6+(i*16)] > working_set[12+(i*16)]) begin
                                {working_set[6+(i*16)], working_set[12+(i*16)]} <= {working_set[12+(i*16)], working_set[6+(i*16)]};
                                {positions_y[6+(i*16)], positions_y[12+(i*16)]} <= {positions_y[12+(i*16)], positions_y[6+(i*16)]};
                            end
                            if(working_set[7+(i*16)] > working_set[13+(i*16)]) begin
                                {working_set[7+(i*16)], working_set[13+(i*16)]} <= {working_set[13+(i*16)], working_set[7+(i*16)]};
                                {positions_y[7+(i*16)], positions_y[13+(i*16)]} <= {positions_y[13+(i*16)], positions_y[7+(i*16)]};
                            end
                        end
                        step3 <= 1;
                    end
                    else if(step4 == 0) begin
                        // Do this for each block of 16 values
                        for(int i=0; i<(INPUTVALS/16); i++) begin
                            // Compare 34567 to 89ABC
                            if(working_set[3+(i*16)] > working_set[8+(i*16)]) begin
                                {working_set[3+(i*16)], working_set[8+(i*16)]} <= {working_set[8+(i*16)], working_set[3+(i*16)]};
                                {positions_y[3+(i*16)], positions_y[8+(i*16)]} <= {positions_y[8+(i*16)], positions_y[3+(i*16)]};
                            end
                            if(working_set[4+(i*16)] > working_set[9+(i*16)]) begin
                                {working_set[4+(i*16)], working_set[9+(i*16)]} <= {working_set[9+(i*16)], working_set[4+(i*16)]};
                                {positions_y[4+(i*16)], positions_y[9+(i*16)]} <= {positions_y[9+(i*16)], positions_y[4+(i*16)]};
                            end
                            if(working_set[5+(i*16)] > working_set[10+(i*16)]) begin
                                {working_set[5+(i*16)], working_set[10+(i*16)]} <= {working_set[10+(i*16)], working_set[5+(i*16)]};
                                {positions_y[5+(i*16)], positions_y[10+(i*16)]} <= {positions_y[10+(i*16)], positions_y[5+(i*16)]};
                            end
                            if(working_set[6+(i*16)] > working_set[11+(i*16)]) begin
                                {working_set[6+(i*16)], working_set[11+(i*16)]} <= {working_set[11+(i*16)], working_set[6+(i*16)]};
                                {positions_y[6+(i*16)], positions_y[11+(i*16)]} <= {positions_y[11+(i*16)], positions_y[6+(i*16)]};
                            end
                            if(working_set[7+(i*16)] > working_set[12+(i*16)]) begin
                                {working_set[7+(i*16)], working_set[12+(i*16)]} <= {working_set[12+(i*16)], working_set[7+(i*16)]};
                                {positions_y[7+(i*16)], positions_y[12+(i*16)]} <= {positions_y[12+(i*16)], positions_y[7+(i*16)]};
                            end
                        end
                        step4 <= 1;
                    end
                    else if(step5 == 0) begin
                        // Do this for each block of 16 values
                        for(int i=0; i<(INPUTVALS/16); i++) begin
                            // Compare 4567 to 89AB
                            if(working_set[4+(i*16)] > working_set[8+(i*16)]) begin
                                {working_set[4+(i*16)], working_set[8+(i*16)]} <= {working_set[8+(i*16)], working_set[4+(i*16)]};
                                {positions_y[4+(i*16)], positions_y[8+(i*16)]} <= {positions_y[8+(i*16)], positions_y[4+(i*16)]};
                            end
                            if(working_set[5+(i*16)] > working_set[9+(i*16)]) begin
                                {working_set[5+(i*16)], working_set[9+(i*16)]} <= {working_set[9+(i*16)], working_set[5+(i*16)]};
                                {positions_y[5+(i*16)], positions_y[9+(i*16)]} <= {positions_y[9+(i*16)], positions_y[5+(i*16)]};
                            end
                            if(working_set[6+(i*16)] > working_set[10+(i*16)]) begin
                                {working_set[6+(i*16)], working_set[10+(i*16)]} <= {working_set[10+(i*16)], working_set[6+(i*16)]};
                                {positions_y[6+(i*16)], positions_y[10+(i*16)]} <= {positions_y[10+(i*16)], positions_y[6+(i*16)]};
                            end
                            if(working_set[7+(i*16)] > working_set[11+(i*16)]) begin
                                {working_set[7+(i*16)], working_set[11+(i*16)]} <= {working_set[11+(i*16)], working_set[7+(i*16)]};
                                {positions_y[7+(i*16)], positions_y[11+(i*16)]} <= {positions_y[11+(i*16)], positions_y[7+(i*16)]};
                            end
                        end
                        step5 <= 1;
                    end
                    else if(step6 == 0) begin
                        // Do this for each block of 16 values
                        for(int i=0; i<(INPUTVALS/16); i++) begin
                            // Compare 567 to 89A
                            if(working_set[5+(i*16)] > working_set[8+(i*16)]) begin
                                {working_set[5+(i*16)], working_set[8+(i*16)]} <= {working_set[8+(i*16)], working_set[5+(i*16)]};
                                {positions_y[5+(i*16)], positions_y[8+(i*16)]} <= {positions_y[8+(i*16)], positions_y[5+(i*16)]};
                            end
                            if(working_set[6+(i*16)] > working_set[9+(i*16)]) begin
                                {working_set[6+(i*16)], working_set[9+(i*16)]} <= {working_set[9+(i*16)], working_set[6+(i*16)]};
                                {positions_y[6+(i*16)], positions_y[9+(i*16)]} <= {positions_y[9+(i*16)], positions_y[6+(i*16)]};
                            end
                            if(working_set[7+(i*16)] > working_set[10+(i*16)]) begin
                                {working_set[7+(i*16)], working_set[10+(i*16)]} <= {working_set[10+(i*16)], working_set[7+(i*16)]};
                                {positions_y[7+(i*16)], positions_y[10+(i*16)]} <= {positions_y[10+(i*16)], positions_y[7+(i*16)]};
                            end
                        end
                        step6 <= 1;
                    end
                    else if(step7 == 0) begin
                        // Do this for each block of 16 values
                        for(int i=0; i<(INPUTVALS/16); i++) begin
                            // Compare 67 to 89
                            if(working_set[6+(i*16)] > working_set[8+(i*16)]) begin
                                {working_set[6+(i*16)], working_set[8+(i*16)]} <= {working_set[8+(i*16)], working_set[6+(i*16)]};
                                {positions_y[6+(i*16)], positions_y[8+(i*16)]} <= {positions_y[8+(i*16)], positions_y[6+(i*16)]};
                            end
                            if(working_set[7+(i*16)] > working_set[9+(i*16)]) begin
                                {working_set[7+(i*16)], working_set[9+(i*16)]} <= {working_set[9+(i*16)], working_set[7+(i*16)]};
                                {positions_y[7+(i*16)], positions_y[9+(i*16)]} <= {positions_y[9+(i*16)], positions_y[7+(i*16)]};
                            end
                        end
                        step7 <= 1;
                    end
                    else begin
                        // Do this for each block of 16 values
                        for(int i=0; i<(INPUTVALS/16); i++) begin
                            // Compare 7 to 8
                            if(working_set[7+(i*16)] > working_set[8+(i*16)]) begin
                                {working_set[7+(i*16)], working_set[8+(i*16)]} <= {working_set[8+(i*16)], working_set[7+(i*16)]};
                                {positions_y[7+(i*16)], positions_y[8+(i*16)]} <= {positions_y[8+(i*16)], positions_y[7+(i*16)]};
                            end
                        end
                        step1 <= 0;
                        step2 <= 0;
                        step3 <= 0;
                        step4 <= 0;
                        step5 <= 0;
                        step6 <= 0;
                        step7 <= 0;
                        if(INPUTVALS >= 32) begin
                            sort_fsm <= MERGE32;
                        end
                        else begin
                            sort_fsm <= IDLE;
                            sortdone_y <= 1;
                        end
                    end
                end
                MERGE32     : begin
                    // Not Yet Supported
                    sort_fsm <= IDLE;
                    sortdone_y <= 1;
                end
            endcase
        end
    end

    /* Code Storage
    always@(posedge clk) begin
        if(reset == RSTPOL) begin
        end
        else begin
        end
    end
    */
endmodule
