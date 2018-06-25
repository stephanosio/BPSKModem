/*++

 RELEASED FOR ACADEMIC AND NON-COMMERCIAL USE ONLY

 Module Name:

    Plc.sv

 Abstract:

    This module is the top level module of Power Line Communication controller logic.

 Author:

    Stephanos Ioannidis (root@stephanos.io)  06-Mar-2017

 Revision History:

--*/

module Plc(
    //
    // Bus Interface Signals
    //
    
    input           BusClk,
    input           BusReset_n,
    input   [5:0]   BusAddress,
    input   [3:0]   BusByteEnable,
    input   [31:0]  BusWriteData,
    output  [31:0]  BusReadData,
    input           BusWrite,
    input           BusRead,
    
    //
    // Modem Clock
    //
    
    input           ModemClk,
    
    //
    // Board Power-Line Communication Control Signals
    //
    
    output          RX_VGA_CS,
    output          RX_VGA_SCK,
    output          RX_VGA_SI,
    
    output          RX_ADC_OE,
    output          RX_ADC_CLK,
    input   [7:0]   RX_ADC_DATA,
    
    output          TX_DRV
    );
    
    //
    // NOTE: Only modem is driven by a higher clock frequency and the rest of the logic is driven
    //       by the lower bus clock frequency to reduce power consumption.
    //
    
    //
    // Bus Interface Internal Registers
    //
    
    reg             CtlTxDo;
    wire            CtlTxDone;
    reg     [2:0]   CtlTxDiv;
    
    reg             CtlRxPending;
    reg     [2:0]   CtlRxGain;
    
    reg     [31:0]  CtlTxData [0:15] /* synthesis ramstyle = "M9K" */;
    wire    [31:0]  CtlRxData [0:15];
    
    //
    // Instantiate BPSK Modem.
    //
    
    wire TxInt;
    wire TxDone;
    wire [31:0] TxData [0:15];
    wire [7:0] TxOut;
    
    wire RxAdcClk;
    wire [7:0] RxAdcIn;
    wire RxInt;
    wire [31:0] RxData [0:15];
    
    BpskModem modem(
        .Clk(ModemClk),
        .Reset_n(BusReset_n),
        
        .ModOutDiv(CtlTxDiv),
        .ModInt(TxInt),
        .ModData(TxData),
        .ModDone(TxDone),
        .ModOut(TxOut),
        
        .DemodAdcClk(RxAdcClk),
        .DemodAdcIn(RxAdcIn),
        .DemodInt(RxInt),
        .DemodData(RxData),
        .DemodAck(~CtlRxPending)
        );
    
    assign TxInt = CtlTxDo;
    assign CtlTxDone = TxDone;
    assign TxData = CtlTxData;
    
    assign CtlRxData = RxData;
    
    //
    // Instantiate Delta Sigma Modulator.
    //
    
    DeltaSigmaMod dsm(
        .Reset_n(BusReset_n),
        .Clk(BusClk),
        
        .In(TxOut),
        .Out(TX_DRV)
        );
    
    //
    // Instantiate Programmable Gain Amplifier Controller.
    //
    
    reg RxPgaGainUpdateInt;
    wire RxPgaGainUpdateDone;
    
    Pga pga(
        .Reset_n(BusReset_n),
        .Clk(BusClk),
        
        .Int(RxPgaGainUpdateInt),
        .Gain(CtlRxGain),
        .Done(RxPgaGainUpdateDone),
        
        .SPI_nCS(RX_VGA_CS),
        .SPI_SO(RX_VGA_SI),
        .SPI_SCK(RX_VGA_SCK)
        );
    
    //
    // Instantiate Analog-to-Digital Converter Controller.
    //
    // NOTE: ModemClk is used for ADC Controller because it is impossible to generate 10MHz ADC
    //       clock from 50MHz input.
    //
    
    wire [7:0] AdcData;
    
    Adc adc(
        .Reset_n(BusReset_n),
        .Clk(ModemClk),
        
        .Data(RX_ADC_DATA),
        
        .nOE(RX_ADC_OE),
        .ClkOut(RxAdcClk),
        
        .DataOut(RxAdcIn)
        );
    
    assign RX_ADC_CLK = RxAdcClk;
    
    //
    // Programmable Gain Amplifier Gain Update Loop
    //
    
    reg     [31:0]  RxPgaWaitCnt;
    
    always @ (posedge BusClk or negedge BusReset_n)
    begin
        if (!BusReset_n)
        begin
            RxPgaWaitCnt <= 0;
        end
        else
        begin
            if (RxPgaWaitCnt == 50000000)
            begin
                //
                // Transmit a gain setting packet by issuing an interrupt.
                //
                
                RxPgaGainUpdateInt <= 1;
                RxPgaWaitCnt <= RxPgaWaitCnt + 1;
            end
            else if (RxPgaWaitCnt == 50000001)
            begin
                //
                // Deactivate the interrupt after one primary clock cycle.
                //
                
                RxPgaGainUpdateInt <= 0;
                RxPgaWaitCnt <= 0;
            end
            else
            begin
                RxPgaWaitCnt <= RxPgaWaitCnt + 1;
            end
        end
    end
    
    //
    // Bus Interface Register File
    //
    
    wire    [31:0]  RegFile [0:64];
    
    // Transmit Control Register (TXCON)
    assign RegFile[0][0] = CtlTxDo;
    assign RegFile[0][1] = CtlTxDone;
    assign RegFile[0][4:2] = CtlTxDiv;
    
    // Receive Control Register (RXCON)
    assign RegFile[0][8] = CtlRxPending;
    assign RegFile[0][12:10] = CtlRxGain;
    
    // Transmit Data Register
    /*assign RegFile[1] = CtlTxData[0];
    assign RegFile[2] = CtlTxData[1];
    assign RegFile[3] = CtlTxData[2];
    assign RegFile[4] = CtlTxData[3];
    assign RegFile[5] = CtlTxData[4];
    assign RegFile[6] = CtlTxData[5];
    assign RegFile[7] = CtlTxData[6];
    assign RegFile[8] = CtlTxData[7];
    assign RegFile[9] = CtlTxData[8];
    assign RegFile[10] = CtlTxData[9];
    assign RegFile[11] = CtlTxData[10];
    assign RegFile[12] = CtlTxData[11];
    assign RegFile[13] = CtlTxData[12];
    assign RegFile[14] = CtlTxData[13];
    assign RegFile[15] = CtlTxData[14];
    assign RegFile[16] = CtlTxData[15];
    assign RegFile[17] = CtlTxData[16];
    assign RegFile[18] = CtlTxData[17];
    assign RegFile[19] = CtlTxData[18];
    assign RegFile[20] = CtlTxData[19];
    assign RegFile[21] = CtlTxData[20];
    assign RegFile[22] = CtlTxData[21];
    assign RegFile[23] = CtlTxData[22];
    assign RegFile[24] = CtlTxData[23];
    assign RegFile[25] = CtlTxData[24];
    assign RegFile[26] = CtlTxData[25];
    assign RegFile[27] = CtlTxData[26];
    assign RegFile[28] = CtlTxData[27];
    assign RegFile[29] = CtlTxData[28];
    assign RegFile[30] = CtlTxData[29];
    assign RegFile[31] = CtlTxData[30];
    assign RegFile[32] = CtlTxData[31];*/
    
    // Receive Data Register
    assign RegFile[17] = CtlRxData[0];
    assign RegFile[18] = CtlRxData[1];
    assign RegFile[19] = CtlRxData[2];
    assign RegFile[20] = CtlRxData[3];
    assign RegFile[21] = CtlRxData[4];
    assign RegFile[22] = CtlRxData[5];
    assign RegFile[23] = CtlRxData[6];
    assign RegFile[24] = CtlRxData[7];
    assign RegFile[25] = CtlRxData[8];
    assign RegFile[26] = CtlRxData[9];
    assign RegFile[27] = CtlRxData[10];
    assign RegFile[28] = CtlRxData[11];
    assign RegFile[29] = CtlRxData[12];
    assign RegFile[30] = CtlRxData[13];
    assign RegFile[31] = CtlRxData[14];
    assign RegFile[32] = CtlRxData[15];
    /*assign RegFile[49] = CtlRxData[16];
    assign RegFile[50] = CtlRxData[17];
    assign RegFile[51] = CtlRxData[18];
    assign RegFile[52] = CtlRxData[19];
    assign RegFile[53] = CtlRxData[20];
    assign RegFile[54] = CtlRxData[21];
    assign RegFile[55] = CtlRxData[22];
    assign RegFile[56] = CtlRxData[23];
    assign RegFile[57] = CtlRxData[24];
    assign RegFile[58] = CtlRxData[25];
    assign RegFile[59] = CtlRxData[26];
    assign RegFile[60] = CtlRxData[27];
    assign RegFile[61] = CtlRxData[28];
    assign RegFile[62] = CtlRxData[29];
    assign RegFile[63] = CtlRxData[30];
    assign RegFile[64] = CtlRxData[31];*/
    
    //
    // Bus Interface Controller
    //
    
    assign BusReadData = BusRead ? RegFile[BusAddress] : { 32{ 1'bz } };

    always @ (posedge BusClk or negedge BusReset_n)
    begin
        if (!BusReset_n)
        begin
            CtlTxDo <= 0;
            CtlTxData[0] <= 0;
        end
        else if (BusWrite)
        begin
            if (BusAddress == 0)
            begin
                //
                // TxCon Register
                //
                
                if (BusByteEnable[0])
                begin
                    CtlTxDo <= BusWriteData[0];
                    CtlTxDiv <= BusWriteData[4:2];
                end
                
                //
                // RxCon Register
                //
                
                if (BusByteEnable[1])
                begin
                    //
                    // TODO: RxCon register structure to be determined.
                    //
                end
            end
            else
            begin
                //
                // Process Transmit Data Registers Write
                //
                
                case (BusAddress)
                    1:  CtlTxData[0] <= BusWriteData;
                    2:  CtlTxData[1] <= BusWriteData;
                    3:  CtlTxData[2] <= BusWriteData;
                    4:  CtlTxData[3] <= BusWriteData;
                    5:  CtlTxData[4] <= BusWriteData;
                    6:  CtlTxData[5] <= BusWriteData;
                    7:  CtlTxData[6] <= BusWriteData;
                    8:  CtlTxData[7] <= BusWriteData;
                    9:  CtlTxData[8] <= BusWriteData;
                    10: CtlTxData[9] <= BusWriteData;
                    11: CtlTxData[10] <= BusWriteData;
                    12: CtlTxData[11] <= BusWriteData;
                    13: CtlTxData[12] <= BusWriteData;
                    14: CtlTxData[13] <= BusWriteData;
                    15: CtlTxData[14] <= BusWriteData;
                    16: CtlTxData[15] <= BusWriteData;
                    /*17: CtlTxData[16] <= BusWriteData;
                    18: CtlTxData[17] <= BusWriteData;
                    19: CtlTxData[18] <= BusWriteData;
                    20: CtlTxData[19] <= BusWriteData;
                    21: CtlTxData[20] <= BusWriteData;
                    22: CtlTxData[21] <= BusWriteData;
                    23: CtlTxData[22] <= BusWriteData;
                    24: CtlTxData[23] <= BusWriteData;
                    25: CtlTxData[24] <= BusWriteData;
                    26: CtlTxData[25] <= BusWriteData;
                    27: CtlTxData[26] <= BusWriteData;
                    28: CtlTxData[27] <= BusWriteData;
                    29: CtlTxData[28] <= BusWriteData;
                    30: CtlTxData[29] <= BusWriteData;
                    31: CtlTxData[30] <= BusWriteData;
                    32: CtlTxData[31] <= BusWriteData;*/
                endcase
            end
        end
    end
    
    //
    // Receive State Controller
    //
    
    always @ (posedge BusClk or negedge BusReset_n)
    begin
        if (!BusReset_n)
        begin
            CtlRxPending <= 0;
        end
        else if (RxInt)
        begin
            //
            // RxPending is set when a receive interrupt is generated by the modem. 
            //
            
            CtlRxPending <= 1;
        end
        else if (BusWrite && (BusAddress == 0) && BusByteEnable[1] && BusWriteData[9])
        begin
            //
            // RxPending is reset when ACK bit is written in TXCON register.
            //
            
            CtlRxPending <= 0;
        end
    end
    

endmodule
