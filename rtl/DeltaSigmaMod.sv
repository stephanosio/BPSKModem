/*++

 RELEASED FOR ACADEMIC AND NON-COMMERCIAL USE ONLY

 Module Name:

    DeltaSigmaMod.v

 Abstract:

    This module implements a Delta-Sigma Modulator logic for analog signal output.
    
    When the output of this module is connected to an RC filter, the output is of an analog value
    that is dependent on the duty cycle of the digital output waveform.

 Author:

    Stephanos Ioannidis (root@stephanos.io)  18-Aug-2016

 Revision History:

--*/

module DeltaSigmaMod(
    // Base System
    input               Reset_n,
    input               Clk,
    
    // Delta-Sigma Modulator
    input   [7:0]       In,
    output              Out
    );
    
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\\\//
    // Delta-Sigma Modulator Block //
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\\\//
    
    reg [8:0] Accum;
    
    always @ (posedge Clk or negedge Reset_n)
    begin
        //
        // This block generates the modulated digital waveform for digital signal generation.
        //
        // The core of this Delta-Sigma modulator implementation is the accumulator. The input value
        // is added to the lower 7 bits of the accumulator from the last cycle, and the MSB of the
        // accumulator is used to drive the output. Note that the MSB will be high only if the
        // IN + Accum[7:0] overflows.
        //
        // The value of the input determines how fast the accumulator overflows and hence the number
        // of high levels output- a high input value would result in the accumulator overflowing
        // faster and therefore more high outputs.
        //
        // This implementation compares to the classic Delta Sigma Modulator topology as follows:
        //  * the differentiator (delta) corresponds to the wrap-around effect of the register
        //      overflow
        //  * the integrator (sigma) corresponds to the accumulator register.
        //  * the comparator corresponds to the bit length of the accumulator register.
        //
        
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Clear the accumulator.
            //
            
            Accum <= 0;
        end
        else
        begin
            //
            // Add the lower 7 bits of the accumulator to the input value.
            //
            
            Accum <= Accum[7:0] + In;
        end
    end
    
    //
    // Assign the output value to be the 8th bit of the accumulator.
    //
    // Note that the output value will be high only when the existing accumulator value added to
    // the input value overflows.
    //
    
    assign Out = Accum[8];

endmodule
