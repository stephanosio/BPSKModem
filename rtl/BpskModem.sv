/*++

 RELEASED FOR ACADEMIC AND NON-COMMERCIAL USE ONLY

 Module Name:

    BPSK.v

 Abstract:

    This module implements a Binary Phase Shift Keying (BPSK) modem.

 Author:

    Stephanos Ioannidis (root@stephanos.io)  22-Aug-2016

 Revision History:

--*/

module BpskModem(
    // Base System
    input               Clk,
    input               Reset_n,
    
    // Modulator Signals
    input   [2:0]       ModOutDiv,
    input               ModInt,
    input   [31:0]      ModData [0:15],
    output              ModDone,
    output  [7:0]       ModOut,
    
    // Demodulator Signals
    input               DemodAdcClk,
    input   [9:0]       DemodAdcIn,
    output              DemodInt,
    output  [31:0]      DemodData [0:15],
    input               DemodAck
    );
    
    //
    // Modulator Block
    //
    
    BpskMod modulator(
        .Reset_n(Reset_n),
        .Clk(Clk),
        
        .OutDiv(ModOutDiv),
        .Data(ModData),
        .Int(ModInt),
        .Done(ModDone),
        
        .Out(ModOut)
    );
    
    //
    // Demodulator Block
    //
    
    BpskDemod demodulator(
        .Reset_n(Reset_n),
        .Clk(Clk),
        
        .AdcClk(DemodAdcClk),
        .AdcIn(DemodAdcIn),
        
        .Int(DemodInt),
        .Data(DemodData),
        .Ack(DemodAck)
    );
    
endmodule
