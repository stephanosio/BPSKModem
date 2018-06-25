/*++

 RELEASED FOR ACADEMIC AND NON-COMMERCIAL USE ONLY

 Module Name:

    Modulator.v

 Abstract:

    This module implements a Binary Phase Shift Keying (BPSK) modulator.

 Author:

    Stephanos Ioannidis (root@stephanos.io)  22-Aug-2016

 Revision History:

--*/

//
// NOTE: When this module outputs a constant 0 on its output, the delta sigma modulator output
//       driven by Out of this module is also constant zero. Since there is a DC blocking capacitor
//       in the line coupler, as long as there is no change in voltage over time, no output goes
//       through.
//

module BpskMod(
    // Base System
    input                       Clk,
    input                       Reset_n,
    
    // Data Control Signals
    input   [2:0]               OutDiv,
    input   [31:0]              Data [0:15],
    input                       Int,
    output                      Done,
    
    // Modulator Output Signals
    output  [7:0]               Out
    );
    
    //\\\\\\\\\\\\\\\\\\\//
    // Module Parameters //
    //\\\\\\\\\\\\\\\\\\\//
    
    //
    // Carrier Sequencer Divisor:
    //      This parameter specifies the division ratio for the carrier sequencer clock.
    //      The resultant carrier frequency is calculated as follows:
    //          F_out = Clk / 2 / (CSEQDiv + 1) / CSEQElemCnt
    //
    
    parameter CSEQDiv = 4;
    
    //
    // Modulation Index:
    //      This parameter specifies the phase modulation index for the carrier wave.
    //      The higher the modulation index number, the less frequently modulated the carrier wave is.
    //
    
    parameter ModIdx = 2;
    
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\//
    // Transmit Done Signal Driver Block //
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\//
    
    reg DoneDrv;
    
    assign Done = DoneDrv & Int;
    
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\//
    // Carrier Sequencer Clock Generator Block //
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\//
    
    reg CSEQ_Clk;
    reg [15:0] CSEQClkDivCnt;
    
    always @ (posedge Clk or negedge Reset_n)
    begin
        //
        // This block divides the main input clock by a pre-set factor to generate carrier
        // sequencer clock.
        //
        
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Reset the counter and clock output.
            //
            
            CSEQ_Clk <= 0;
            CSEQClkDivCnt <= 0;
        end
        else if (CSEQClkDivCnt == CSEQDiv)
        begin
            //
            // Flip the clock bit once the counter reaches a pre-set value.
            //
            
            CSEQ_Clk <= ~CSEQ_Clk;
            CSEQClkDivCnt <= 0;
        end
        else
        begin
            //
            // Increment the ADC clock divider counter.
            //
            
            CSEQClkDivCnt <= CSEQClkDivCnt + 1;
        end
    end
    
    //\\\\\\\\\\\\\\\\\\\\\\\\\//
    // Carrier Sequencer Block //
    //\\\\\\\\\\\\\\\\\\\\\\\\\//
    
    reg [4:0] SeqSel;
    reg [7:0] SeqOut;
    
    always @ (posedge CSEQ_Clk or negedge Reset_n)
    begin
        //
        // This block sequences the carrier waveform value.
        //
        
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Set the sequence element selector index to 0.
            //
            
            SeqSel <= 0;
        end
        else
        begin
            //
            // Output value based on the sequence element selector index.
            //
            
            case (SeqSel)
                0:  SeqOut = 127;
                1:  SeqOut = 166;
                2:  SeqOut = 202;
                3:  SeqOut = 230;
                4:  SeqOut = 248;
                5:  SeqOut = 254;
                6:  SeqOut = 248;
                7:  SeqOut = 230;
                8:  SeqOut = 202;
                9:  SeqOut = 166;
                10: SeqOut = 127;
                11: SeqOut = 88;
                12: SeqOut = 52;
                13: SeqOut = 24;
                14: SeqOut = 6;
                15: SeqOut = 0;
                16: SeqOut = 6;
                17: SeqOut = 24;
                18: SeqOut = 52;
                19: SeqOut = 88;
            endcase
            
            //
            // Reset the sequence element selector index to 0 once the selector index reaches 19.
            //
            
            if (SeqSel == 19)
                SeqSel <= 0;
            else
                SeqSel <= SeqSel + 1;
        end
    end
    
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\//
    // Transmit Interrupt Edge Detector Block //
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\//
    
    reg [1:0] TIDetect;
    
    always @ (posedge Clk or negedge Reset_n)
    begin
        //
        // This block detects the transmit interrupt by storing last three bits and comparing their
        // values to the latest values.
        //
        
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Clear all edge detection buffer bits.
            //
            
            TIDetect <= 0;
        end
        else
        begin
            //
            // Shift the detector buffer left and insert the latest RX bit.
            //
            
            TIDetect <= (TIDetect << 1) | Int;
        end
    end
    
    //
    // Detect the rising edge on the transmit interrupt line.
    //
    
    wire TIRisingEdge = !TIDetect[1] & TIDetect[0];
    
    //
    // Synchronise the transmit interrupt rising edge signal to sequencer clock.
    //
    
    reg [7:0] TIDetectedSyncCnt;
    reg TIDetected;
    
    always @ (posedge Clk or negedge Reset_n)
    begin
        if (!Reset_n)
        begin
            //
            // Initialise sync counter and TIDetected signal.
            //
            
            TIDetectedSyncCnt <= 0;
            TIDetected <= 0;
        end
        else
        begin
            if (TIRisingEdge && (TIDetectedSyncCnt == 0))
            begin
                //
                // If a rising edge is detected and the counter is not started, assert TIDetected
                // and begin synchronisation.
                //
                
                TIDetected <= 1;
                TIDetectedSyncCnt <= 1;
            end
            else if (TIDetectedSyncCnt != 0)
            begin
                //
                // Wait for the Clk-CSEQ_Clk division ratio cycles in Clk domain.
                //
                
                if (TIDetectedSyncCnt == ((CSEQDiv + 1) * 2))
                begin
                    TIDetected <= 0;
                    TIDetectedSyncCnt <= 0;
                end
                else
                begin
                    TIDetectedSyncCnt <= TIDetectedSyncCnt + 1;
                end
            end
        end
    end
    
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\//
    // Carrier Phase Shift Block //
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\//
    
    reg Phase;
    reg OutEnable;
    
    //
    // Out output value is dependent on the Phase register value.
    //
    // If the Phase register contains 0, the Out output is simply the sequencer output value.
    // If the Phase register contains 1, the Out output is the inverted value of the sequencer
    // output value.
    //
    // Output is always zero regardless of the carrier sequencer output when OutEnable is inactive.
    //
    
    wire [7:0] PhaseModSeqOut = (Phase == 0) ? (SeqOut) >> OutDiv : (254 - SeqOut) >> OutDiv;

    assign Out = (OutEnable == 0) ? 0 : PhaseModSeqOut;
    
    //\\\\\\\\\\\\\\\\\\\\\\//
    // Data Sequencer Block //
    //\\\\\\\\\\\\\\\\\\\\\\//
    
    reg [9:0] WaitCnt;
    reg [10:0] BitIndex;     // NOTE: Make sure to change this when the data bit length changes.
    reg [1:0] ModIdxCnt;
    reg [31:0] Checksum;
    
    wire [0:63] MagicPattern = 64'hB5A6FFFF9BE37C39;
    
    always @ (posedge CSEQ_Clk or negedge Reset_n)
    begin
        //
        // This block inverts the sequencer output value based on the phase value.
        //
        
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Reset the phase to 0 deg and modulation index counter to 0.
            // Also disable modulator analog output upon reset.
            //
            
            ModIdxCnt <= 0;
            Phase <= 0;
            OutEnable <= 0;
            DoneDrv <= 0;
            Checksum <= 0;
        end
        else if (TIDetected && !OutEnable)
        begin
            //
            // A transmit interrupt has been detected. Latch the transmit data and enable modulator
            // output. Also initialise the wait counter value for warm-up cycles.
            //
            
            OutEnable <= 1;
            WaitCnt <= 0;
            BitIndex <= 0;
            DoneDrv <= 0;
            
            //
            // Compute the data frame checksum by XOR-ing all data words.
            //
            
            Checksum <=
                Data[0]  ^ Data[1]  ^ Data[2]  ^ Data[3]  ^
                Data[4]  ^ Data[5]  ^ Data[6]  ^ Data[7]  ^
                Data[8]  ^ Data[9]  ^ Data[10] ^ Data[11] ^
                Data[12] ^ Data[13] ^ Data[14] ^ Data[15];
        end
        else if (OutEnable)
        begin
            //
            // This block executes when a transmit cycle is active.
            //
            
            if (SeqSel == 0)
            begin
                //
                // This block executes at the beginning of each carrier cycle.
                //
                
                if (WaitCnt < 1000)
                begin
                    //
                    // Increment the wait counter until 100 carrier cycles have been driven. This
                    // allows the receiver Costas Loop to lock on the transmitted carrier.
                    //
                    
                    WaitCnt <= WaitCnt + 1;
                end
                else
                begin
                    //
                    // If a transmit cycle is active and the wait counter value (of 100) is reached,
                    // begin modulating the output data.
                    //
                    
                    if (ModIdxCnt == (ModIdx - 1))
                    begin
                        //
                        // Modulation index counter hit the preset index.
                        //
                        
                        if (BitIndex < 64)
                        begin
                            //
                            // Bit index is less than 16. Transmit "magic" bit pattern.
                            //
                            
                            Phase <= MagicPattern[BitIndex];
                            BitIndex <= BitIndex + 1;
                        end
                        else if (BitIndex < 576) // 64 + (32 * 16)
                        begin
                            //
                            // Modify the carrier phase based on the data value and increment the
                            // bit index.
                            //
                            
                            Phase <= Data[(BitIndex - 64) >> 5][31 - ((BitIndex - 64) & 11'h1F)];
                            BitIndex <= BitIndex + 1;
                        end
                        else if (BitIndex < 608) // 576 + 32
                        begin
                            //
                            // Transmit data frame checksum.
                            //
                            
                            Phase <= Checksum[607 - BitIndex];
                            BitIndex <= BitIndex + 1;
                        end
                        else
                        begin
                            //
                            // Reached the last word. Disable the carrier output and activate
                            // the transmit done signal.
                            //
                            
                            OutEnable <= 0;
                            DoneDrv <= 1;
                        end
                        
                        ModIdxCnt <= 0;
                    end
                    else
                    begin
                        //
                        // One carrier period has elapsed. Increment the modulation index counter.
                        //
                        
                        ModIdxCnt <= ModIdxCnt + 1;
                    end
                end
            end
        end
    end
    
endmodule
