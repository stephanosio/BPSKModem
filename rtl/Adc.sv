/*++

 RELEASED FOR ACADEMIC AND NON-COMMERCIAL USE ONLY

 Module Name:

    Adc.v

 Abstract:

    This module implements the control logic for the parallel 8-bit Analog-to-Digital Converter.

 Author:

    Stephanos Ioannidis (root@stephanos.io)  17-Oct-2016

 Revision History:
 
    Stephanos Ioannidis (root@stephanos.io)  13-Mar-2017
        Ported this module for use with prototype boards.

--*/

module Adc(
    // Base System
    input               Clk,
    input               Reset_n,
    
    // ADC Input
    input   [7:0]       Data,
    
    // ADC Control Signals
    output              nOE,
    output              ClkOut,
    
    // Data Output
    output  [7:0]       DataOut
    );
    
    //\\\\\\\\\\\\\\\\\\\\\\\\\//
    // ADC Output Driver Block //
    //\\\\\\\\\\\\\\\\\\\\\\\\\//
    
    reg nOEDrv;
    assign nOE = nOEDrv;
    
    always @ (posedge Clk or negedge Reset_n)
    begin
        //
        // This block drives the output enable signal for the ADC module.
        //
        
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Disable the ADC module output.
            //
            
            nOEDrv <= 1;
        end
        else
        begin
            //
            // Enable the ADC module output.
            //
            
            nOEDrv <= 0;
        end
    end
    
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\//
    // ADC Clock Generator Block //
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\//
    
    //
    // NOTE: F_div = F_Clk / 2 / (ADCClkDIV + 1)
    //
    
    parameter AdcClkDiv = 9;
    
    reg ClkOutDrv;
    assign ClkOut = ClkOutDrv;
    
    reg [7:0] AdcClkDivCnt;
    
    always @ (posedge Clk or negedge Reset_n)
    begin
        //
        // This block generates 10MHz ADC clock from the 200MHz internal PLL clock.
        //
        
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Reset the counter and clock output.
            //
            
            ClkOutDrv <= 1;
            AdcClkDivCnt <= 0;
        end
        else if (AdcClkDivCnt == AdcClkDiv)
        begin
            //
            // Flip the clock bit once the counter reaches a pre-set value.
            //
            
            ClkOutDrv <= ~ClkOutDrv;
            AdcClkDivCnt <= 0;
        end
        else
        begin
            //
            // Increment the ADC clock divider counter.
            //
            
            AdcClkDivCnt <= AdcClkDivCnt + 1;
        end
    end
    
    //\\\\\\\\\\\\\\\\\\\\\\//
    // ADC Data Latch Block //
    //\\\\\\\\\\\\\\\\\\\\\\//
    
    reg [7:0] AdcData;
    
    assign DataOut = AdcData;
    
    always @ (posedge ClkOut or negedge Reset_n)
    begin
        //
        // This block latches the ADC data at every rising edge of the clock cycle
        // (ADC data is valid at the rising edge of every clock).
        //
        
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Clear the internal ADC data buffer.
            //
            
            AdcData <= 0;
        end
        else
        begin
            //
            // Latch the ADC data line to the internal ADC data buffer.
            //
            
            AdcData <= Data;
        end
    end
    
endmodule
