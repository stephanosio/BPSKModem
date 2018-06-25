/*++

 RELEASED FOR ACADEMIC AND NON-COMMERCIAL USE ONLY

 Module Name:

    Plc_tb.sv

 Abstract:

    This module implements test inputs for the PLC Subsystem control logic module (Plc.sv).

 Author:

    Stephanos Ioannidis (root@stephanos.io)  7-Mar-2017

 Revision History:

--*/

`timescale 1ns / 100ps

module Plc_tb;

    reg BusClk, BusReset_n;
    reg [5:0] BusAddress;
    reg [3:0] BusByteEnable;
    reg [31:0] BusWriteData;
    reg BusWrite;
    
    Plc Plc_inst(
        .BusClk(BusClk),
        .BusReset_n(BusReset_n),
        
        .BusAddress(BusAddress),
        .BusByteEnable(BusByteEnable),
        .BusWriteData(BusWriteData),
        .BusWrite(BusWrite)
        );
    
    initial
    begin
        // Set initial state.
        BusClk = 0;
        BusReset_n = 0;
        
        // Deactivate reset signal.
        #5 BusReset_n = 1;
        #5 BusReset_n = 0;
        #5 BusReset_n = 1;
    end
    
    always
    begin
        // Tick clock every 2.5ns (1 cycle = 5ns = 200MHz).
        #2.5 BusClk = ~BusClk;
    end
    
    reg [7:0] TestClkCnt;
    
    always @ (posedge BusClk or negedge BusReset_n)
    begin
        if (!BusReset_n)
        begin
            //
            // Set initial variable state.
            //
            
            TestClkCnt <= 0;
            
            BusAddress <= 0;
            BusByteEnable <= 0;
            BusWriteData <= 0;
            BusWrite <= 0;
        end
        else
        begin
            //
            // .
            //
            
            if (TestClkCnt == 3)
            begin
                BusAddress <= 1;
                BusByteEnable <= 4'b1111;
                BusWriteData <= 32'h00000065;
                BusWrite <= 1;
                
                TestClkCnt <= TestClkCnt + 1;
            end
            else if (TestClkCnt == 4)
            begin
                BusAddress <= 0;
                BusByteEnable <= 4'b0001;
                BusWriteData <= 1;
                BusWrite <= 1;
                
                TestClkCnt <= TestClkCnt + 1;
            end
            else if (TestClkCnt == 5)
            begin
                BusWrite <= 0;
            end
            else
            begin
                TestClkCnt <= TestClkCnt + 1;
            end
        end
    end

endmodule
