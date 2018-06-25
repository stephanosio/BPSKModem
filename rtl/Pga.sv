/*++

 RELEASED FOR ACADEMIC AND NON-COMMERCIAL USE ONLY

 Module Name:

    Pga.v

 Abstract:

    This module implements control logic for MCP6S91 Programmable Gain Amplifier.

 Author:

    Stephanos Ioannidis (root@stephanos.io)  12-Aug-2016

 Revision History:
 
    Stephanos Ioannidis (root@stephanos.io)  10-Oct-2016
        Ported this module for use with the PLC Phase 2 development boards.
    
    Stephanos Ioannidis (root@stephanos.io)  13-Mar-2017
        Ported this module for use with prototype boards.

--*/

module Pga(
    // Base System
    input           Reset_n,
    input           Clk,
    
    // Module Control Interface
    input           Int,
    input   [2:0]   Gain,
    output          Done,
    
    // SPI Control Interface
    output          SPI_nCS,
    output          SPI_SO,
    output          SPI_SCK
    );
    
    //
    // Module Output
    //
    
    reg DoneDrv;
    reg SPI_nCSDrv;
    reg SPI_SODrv;
    reg SPI_SCKDrv;
    
    assign Done = DoneDrv;
    assign SPI_nCS = SPI_nCSDrv;
    assign SPI_SO = SPI_SODrv;
    assign SPI_SCK = SPI_SCKDrv;
    
    //
    // Transmit Clock Generator Block
    //
    
    parameter ClkDiv = 50;
    
    //
    // NOTE: Clock division ratio = Clk / 2 / CounterCriterion
    //       Given that the input Clk is 200MHz, the TxClk is 2MHz.
    //       TxClk is twice the frequency of the actual SPI serial clock.
    //
    
    reg TxClk;
    reg [6:0] TxClkDivCnt;
    
    always @ (posedge Clk or negedge Reset_n)
    begin
        if (!Reset_n)
        begin
            TxClk <= 0;
            TxClkDivCnt <= 0;
        end
        else if (TxClkDivCnt == ClkDiv)
        begin
            TxClk <= ~TxClk;
            TxClkDivCnt <= 0;
        end
        else
        begin
            TxClkDivCnt <= TxClkDivCnt + 1;
        end
    end
    
    //
    // Set Gain Interrupt Detector Block
    //
    // NOTE: This block detects a positive edge on the interrupt line.
    //
    
    reg IntPrev;
    
    always @ (posedge Clk or negedge Reset_n)
    begin
        if (!Reset_n)
        begin
            IntPrev <= 0;
        end
        else
        begin
            IntPrev <= Int;
        end
    end
    
    wire IntDetected = !IntPrev & Int;
    
    //
    // SPI Transmission Control Block
    //
    
    reg TxEnabled;
    reg [0:15] TxBits;
    reg TxDone;
    reg TxDonePrev;
    
    always @ (posedge Clk or negedge Reset_n)
    begin
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Disable transmission cycle.
            //
            
            TxEnabled <= 0;
            TxBits <= 0;
            TxDonePrev <= 0;
            DoneDrv <= 0;
        end
        else
        begin
            if (IntDetected)
            begin
                //
                // A transmit interrupt has been detected. Initiate a transmission cycle.
                //
                
                TxEnabled <= 1;
                
                // Instruction Register [7:0]
                TxBits[0:2]   <= 3'b010;  // [7:5] Command (Write to Register)
                TxBits[3:6]   <= 0;       // [4:1] Reserved
                TxBits[7]     <= 0;       // [0]   Address (Gain)
                
                // Gain Register [7:0]
                TxBits[8:12]  <= 0;       // [7:3] Reserved
                TxBits[13:15] <= Gain;    // [2:0] Gain
            end
            else if (!TxDonePrev && TxDone)
            begin
                //
                // If the previously initiated transmission cycle is completed, drive Done output
                // for one cycle and synchronise to the TxClk clock domain.
                //
                    
                DoneDrv <= 1;
            end
            else if (DoneDrv)
            begin
                //
                // Deactivate Done output one clock cycle after it is activated.
                //
                
                DoneDrv <= 0;
            end
            else if (TxDonePrev & !TxDone)
            begin
                //
                // A falling edge on TxDone has been detected. Deactivate TxEnabled.
                //
                
                TxEnabled <= 0;
            end
            
            //
            // Latch TxDone value for edge detection.
            //
            
            TxDonePrev <= TxDone;
        end
    end
    
    //
    // SPI Command Transmit Block
    //
    
    reg [5:0] TxIndex;
    
    always @ (posedge TxClk or negedge Reset_n)
    begin
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Reset the internal register values.
            //
            
            TxIndex <= 0;
            TxDone <= 0;
            
            //
            // Reset SPI outputs.
            //
            
            SPI_nCSDrv <= 1;
            SPI_SODrv <= 0;
            SPI_SCKDrv <= 0;
        end
        else
        begin
            if (TxEnabled)
            begin
                //
                // Drive CS to LOW when a transmission cycle begins.
                //
                
                if (TxIndex == 0)
                begin
                    //
                    // Enable CS (active low).
                    //
                    
                    SPI_nCSDrv <= 0;
                end
                
                //
                // Toggle clock and drive data output.
                //
                
                if (TxIndex <= 31)
                begin
                    if (TxIndex & 1)
                    begin
                        //
                        // If the transmission index is an odd number, drive clock to HIGH.
                        //
                        
                        SPI_SCKDrv <= 1;
                    end
                    else
                    begin
                        //
                        // If the transmission index is an even number, drive clock to LOW and
                        // drive output to corresponding bit.
                        //
                        
                        SPI_SCKDrv <= 0;
                        SPI_SODrv <= TxBits[TxIndex >> 1];
                    end
                end
                else if (TxIndex == 32)
                begin
                    //
                    // End of transmission cycle. Drive clock and data output to LOW.
                    //
                    
                    SPI_SCKDrv <= 0;
                    SPI_SODrv <= 0;
                end
                else if (TxIndex == 33)
                begin
                    //
                    // Disable CS and set TxDone.
                    //
                    
                    SPI_nCSDrv <= 1;
                    TxDone <= 1;
                end
                else if (TxIndex == 34)
                begin
                    //
                    // Disable TxDone and reset transmission index.
                    //
                    
                    TxDone <= 0;
                    TxIndex <= 0;
                end
                
                //
                // Increment transmission index.
                //
                
                if (TxIndex < 34)
                begin
                    TxIndex <= TxIndex + 1;
                end
            end
        end
    end

endmodule
