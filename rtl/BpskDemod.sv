/*++

 RELEASED FOR ACADEMIC AND NON-COMMERCIAL USE ONLY

 Module Name:

    Demodulator.v

 Abstract:

    This module implements a Binary Phase Shift Keying (BPSK) demodulator.

 Author:

    Stephanos Ioannidis (root@stephanos.io)  30-Aug-2016

 Revision History:

--*/

module BpskDemod(
    // Base System
    input                       Clk,            // We assume 200MHz clock input by default.
    input                       Reset_n,
    
    // Demodulator Input Signals
    input                       AdcClk,
    input   [9:0]               AdcIn,          // Q9:0
    
    // Data Control Signals
    output                      Int,
    output  [31:0]              Data [0:15],
    input                       Ack
    );
    
    parameter ModemBusClkDiv = 4;
    
    integer i;
    
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\//
    // Module-wide State Signals and Registers //
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\//
    
    wire signed [17:0] mSig;        // Input BPSK Modulated Signal
    reg [8:0] NcoPhase;             // Phase of NCO
    
    // Sign-extend Data in Q9.0 format to Q17.0.
    assign mSig = { { 8{AdcIn[9]} }, AdcIn[9:0] };
    
    //\\\\\\\\\\\\\\\\\\\\\\\\//
    // Sinusoid Look-up Table //
    //\\\\\\\\\\\\\\\\\\\\\\\\//
    
    //
    // NOTE: This look-up table consists of 255 entries that equate to 0 - 179.3 degree output of
    //       the sine function. Each value is encoded in Q7.10 fixed-point format.
    //
    
    wire signed [17:0] SinLUT[0:255] /* synthesis ramstyle = "auto" */;
    
    assign SinLUT[0] = 18'b0000000_0000000000;
    assign SinLUT[1] = 18'b0000000_0000001100;
    assign SinLUT[2] = 18'b0000000_0000011001;
    assign SinLUT[3] = 18'b0000000_0000100101;
    assign SinLUT[4] = 18'b0000000_0000110010;
    assign SinLUT[5] = 18'b0000000_0000111110;
    assign SinLUT[6] = 18'b0000000_0001001011;
    assign SinLUT[7] = 18'b0000000_0001010111;
    assign SinLUT[8] = 18'b0000000_0001100100;
    assign SinLUT[9] = 18'b0000000_0001110000;
    assign SinLUT[10] = 18'b0000000_0001111101;
    assign SinLUT[11] = 18'b0000000_0010001001;
    assign SinLUT[12] = 18'b0000000_0010010110;
    assign SinLUT[13] = 18'b0000000_0010100010;
    assign SinLUT[14] = 18'b0000000_0010101111;
    assign SinLUT[15] = 18'b0000000_0010111011;
    assign SinLUT[16] = 18'b0000000_0011000111;
    assign SinLUT[17] = 18'b0000000_0011010100;
    assign SinLUT[18] = 18'b0000000_0011100000;
    assign SinLUT[19] = 18'b0000000_0011101100;
    assign SinLUT[20] = 18'b0000000_0011111000;
    assign SinLUT[21] = 18'b0000000_0100000100;
    assign SinLUT[22] = 18'b0000000_0100010001;
    assign SinLUT[23] = 18'b0000000_0100011101;
    assign SinLUT[24] = 18'b0000000_0100101001;
    assign SinLUT[25] = 18'b0000000_0100110101;
    assign SinLUT[26] = 18'b0000000_0101000001;
    assign SinLUT[27] = 18'b0000000_0101001101;
    assign SinLUT[28] = 18'b0000000_0101011000;
    assign SinLUT[29] = 18'b0000000_0101100100;
    assign SinLUT[30] = 18'b0000000_0101110000;
    assign SinLUT[31] = 18'b0000000_0101111100;
    assign SinLUT[32] = 18'b0000000_0110000111;
    assign SinLUT[33] = 18'b0000000_0110010011;
    assign SinLUT[34] = 18'b0000000_0110011110;
    assign SinLUT[35] = 18'b0000000_0110101010;
    assign SinLUT[36] = 18'b0000000_0110110101;
    assign SinLUT[37] = 18'b0000000_0111000001;
    assign SinLUT[38] = 18'b0000000_0111001100;
    assign SinLUT[39] = 18'b0000000_0111010111;
    assign SinLUT[40] = 18'b0000000_0111100010;
    assign SinLUT[41] = 18'b0000000_0111101101;
    assign SinLUT[42] = 18'b0000000_0111111000;
    assign SinLUT[43] = 18'b0000000_1000000011;
    assign SinLUT[44] = 18'b0000000_1000001110;
    assign SinLUT[45] = 18'b0000000_1000011001;
    assign SinLUT[46] = 18'b0000000_1000100011;
    assign SinLUT[47] = 18'b0000000_1000101110;
    assign SinLUT[48] = 18'b0000000_1000111000;
    assign SinLUT[49] = 18'b0000000_1001000011;
    assign SinLUT[50] = 18'b0000000_1001001101;
    assign SinLUT[51] = 18'b0000000_1001010111;
    assign SinLUT[52] = 18'b0000000_1001100001;
    assign SinLUT[53] = 18'b0000000_1001101100;
    assign SinLUT[54] = 18'b0000000_1001110101;
    assign SinLUT[55] = 18'b0000000_1001111111;
    assign SinLUT[56] = 18'b0000000_1010001001;
    assign SinLUT[57] = 18'b0000000_1010010011;
    assign SinLUT[58] = 18'b0000000_1010011100;
    assign SinLUT[59] = 18'b0000000_1010100110;
    assign SinLUT[60] = 18'b0000000_1010101111;
    assign SinLUT[61] = 18'b0000000_1010111000;
    assign SinLUT[62] = 18'b0000000_1011000010;
    assign SinLUT[63] = 18'b0000000_1011001011;
    assign SinLUT[64] = 18'b0000000_1011010100;
    assign SinLUT[65] = 18'b0000000_1011011100;
    assign SinLUT[66] = 18'b0000000_1011100101;
    assign SinLUT[67] = 18'b0000000_1011101110;
    assign SinLUT[68] = 18'b0000000_1011110110;
    assign SinLUT[69] = 18'b0000000_1011111111;
    assign SinLUT[70] = 18'b0000000_1100000111;
    assign SinLUT[71] = 18'b0000000_1100001111;
    assign SinLUT[72] = 18'b0000000_1100010111;
    assign SinLUT[73] = 18'b0000000_1100011111;
    assign SinLUT[74] = 18'b0000000_1100100111;
    assign SinLUT[75] = 18'b0000000_1100101110;
    assign SinLUT[76] = 18'b0000000_1100110110;
    assign SinLUT[77] = 18'b0000000_1100111101;
    assign SinLUT[78] = 18'b0000000_1101000101;
    assign SinLUT[79] = 18'b0000000_1101001100;
    assign SinLUT[80] = 18'b0000000_1101010011;
    assign SinLUT[81] = 18'b0000000_1101011010;
    assign SinLUT[82] = 18'b0000000_1101100001;
    assign SinLUT[83] = 18'b0000000_1101100111;
    assign SinLUT[84] = 18'b0000000_1101101110;
    assign SinLUT[85] = 18'b0000000_1101110100;
    assign SinLUT[86] = 18'b0000000_1101111010;
    assign SinLUT[87] = 18'b0000000_1110000001;
    assign SinLUT[88] = 18'b0000000_1110000111;
    assign SinLUT[89] = 18'b0000000_1110001100;
    assign SinLUT[90] = 18'b0000000_1110010010;
    assign SinLUT[91] = 18'b0000000_1110011000;
    assign SinLUT[92] = 18'b0000000_1110011101;
    assign SinLUT[93] = 18'b0000000_1110100010;
    assign SinLUT[94] = 18'b0000000_1110101000;
    assign SinLUT[95] = 18'b0000000_1110101101;
    assign SinLUT[96] = 18'b0000000_1110110010;
    assign SinLUT[97] = 18'b0000000_1110110110;
    assign SinLUT[98] = 18'b0000000_1110111011;
    assign SinLUT[99] = 18'b0000000_1110111111;
    assign SinLUT[100] = 18'b0000000_1111000100;
    assign SinLUT[101] = 18'b0000000_1111001000;
    assign SinLUT[102] = 18'b0000000_1111001100;
    assign SinLUT[103] = 18'b0000000_1111010000;
    assign SinLUT[104] = 18'b0000000_1111010011;
    assign SinLUT[105] = 18'b0000000_1111010111;
    assign SinLUT[106] = 18'b0000000_1111011010;
    assign SinLUT[107] = 18'b0000000_1111011110;
    assign SinLUT[108] = 18'b0000000_1111100001;
    assign SinLUT[109] = 18'b0000000_1111100100;
    assign SinLUT[110] = 18'b0000000_1111100111;
    assign SinLUT[111] = 18'b0000000_1111101001;
    assign SinLUT[112] = 18'b0000000_1111101100;
    assign SinLUT[113] = 18'b0000000_1111101110;
    assign SinLUT[114] = 18'b0000000_1111110000;
    assign SinLUT[115] = 18'b0000000_1111110010;
    assign SinLUT[116] = 18'b0000000_1111110100;
    assign SinLUT[117] = 18'b0000000_1111110110;
    assign SinLUT[118] = 18'b0000000_1111111000;
    assign SinLUT[119] = 18'b0000000_1111111001;
    assign SinLUT[120] = 18'b0000000_1111111011;
    assign SinLUT[121] = 18'b0000000_1111111100;
    assign SinLUT[122] = 18'b0000000_1111111101;
    assign SinLUT[123] = 18'b0000000_1111111110;
    assign SinLUT[124] = 18'b0000000_1111111110;
    assign SinLUT[125] = 18'b0000000_1111111111;
    assign SinLUT[126] = 18'b0000000_1111111111;
    assign SinLUT[127] = 18'b0000000_1111111111;
    assign SinLUT[128] = 18'b0000001_0000000000;
    assign SinLUT[129] = 18'b0000000_1111111111;
    assign SinLUT[130] = 18'b0000000_1111111111;
    assign SinLUT[131] = 18'b0000000_1111111111;
    assign SinLUT[132] = 18'b0000000_1111111110;
    assign SinLUT[133] = 18'b0000000_1111111110;
    assign SinLUT[134] = 18'b0000000_1111111101;
    assign SinLUT[135] = 18'b0000000_1111111100;
    assign SinLUT[136] = 18'b0000000_1111111011;
    assign SinLUT[137] = 18'b0000000_1111111001;
    assign SinLUT[138] = 18'b0000000_1111111000;
    assign SinLUT[139] = 18'b0000000_1111110110;
    assign SinLUT[140] = 18'b0000000_1111110100;
    assign SinLUT[141] = 18'b0000000_1111110010;
    assign SinLUT[142] = 18'b0000000_1111110000;
    assign SinLUT[143] = 18'b0000000_1111101110;
    assign SinLUT[144] = 18'b0000000_1111101100;
    assign SinLUT[145] = 18'b0000000_1111101001;
    assign SinLUT[146] = 18'b0000000_1111100111;
    assign SinLUT[147] = 18'b0000000_1111100100;
    assign SinLUT[148] = 18'b0000000_1111100001;
    assign SinLUT[149] = 18'b0000000_1111011110;
    assign SinLUT[150] = 18'b0000000_1111011010;
    assign SinLUT[151] = 18'b0000000_1111010111;
    assign SinLUT[152] = 18'b0000000_1111010011;
    assign SinLUT[153] = 18'b0000000_1111010000;
    assign SinLUT[154] = 18'b0000000_1111001100;
    assign SinLUT[155] = 18'b0000000_1111001000;
    assign SinLUT[156] = 18'b0000000_1111000100;
    assign SinLUT[157] = 18'b0000000_1110111111;
    assign SinLUT[158] = 18'b0000000_1110111011;
    assign SinLUT[159] = 18'b0000000_1110110110;
    assign SinLUT[160] = 18'b0000000_1110110010;
    assign SinLUT[161] = 18'b0000000_1110101101;
    assign SinLUT[162] = 18'b0000000_1110101000;
    assign SinLUT[163] = 18'b0000000_1110100010;
    assign SinLUT[164] = 18'b0000000_1110011101;
    assign SinLUT[165] = 18'b0000000_1110011000;
    assign SinLUT[166] = 18'b0000000_1110010010;
    assign SinLUT[167] = 18'b0000000_1110001100;
    assign SinLUT[168] = 18'b0000000_1110000111;
    assign SinLUT[169] = 18'b0000000_1110000001;
    assign SinLUT[170] = 18'b0000000_1101111010;
    assign SinLUT[171] = 18'b0000000_1101110100;
    assign SinLUT[172] = 18'b0000000_1101101110;
    assign SinLUT[173] = 18'b0000000_1101100111;
    assign SinLUT[174] = 18'b0000000_1101100001;
    assign SinLUT[175] = 18'b0000000_1101011010;
    assign SinLUT[176] = 18'b0000000_1101010011;
    assign SinLUT[177] = 18'b0000000_1101001100;
    assign SinLUT[178] = 18'b0000000_1101000101;
    assign SinLUT[179] = 18'b0000000_1100111101;
    assign SinLUT[180] = 18'b0000000_1100110110;
    assign SinLUT[181] = 18'b0000000_1100101110;
    assign SinLUT[182] = 18'b0000000_1100100111;
    assign SinLUT[183] = 18'b0000000_1100011111;
    assign SinLUT[184] = 18'b0000000_1100010111;
    assign SinLUT[185] = 18'b0000000_1100001111;
    assign SinLUT[186] = 18'b0000000_1100000111;
    assign SinLUT[187] = 18'b0000000_1011111111;
    assign SinLUT[188] = 18'b0000000_1011110110;
    assign SinLUT[189] = 18'b0000000_1011101110;
    assign SinLUT[190] = 18'b0000000_1011100101;
    assign SinLUT[191] = 18'b0000000_1011011100;
    assign SinLUT[192] = 18'b0000000_1011010100;
    assign SinLUT[193] = 18'b0000000_1011001011;
    assign SinLUT[194] = 18'b0000000_1011000010;
    assign SinLUT[195] = 18'b0000000_1010111000;
    assign SinLUT[196] = 18'b0000000_1010101111;
    assign SinLUT[197] = 18'b0000000_1010100110;
    assign SinLUT[198] = 18'b0000000_1010011100;
    assign SinLUT[199] = 18'b0000000_1010010011;
    assign SinLUT[200] = 18'b0000000_1010001001;
    assign SinLUT[201] = 18'b0000000_1001111111;
    assign SinLUT[202] = 18'b0000000_1001110101;
    assign SinLUT[203] = 18'b0000000_1001101100;
    assign SinLUT[204] = 18'b0000000_1001100001;
    assign SinLUT[205] = 18'b0000000_1001010111;
    assign SinLUT[206] = 18'b0000000_1001001101;
    assign SinLUT[207] = 18'b0000000_1001000011;
    assign SinLUT[208] = 18'b0000000_1000111000;
    assign SinLUT[209] = 18'b0000000_1000101110;
    assign SinLUT[210] = 18'b0000000_1000100011;
    assign SinLUT[211] = 18'b0000000_1000011001;
    assign SinLUT[212] = 18'b0000000_1000001110;
    assign SinLUT[213] = 18'b0000000_1000000011;
    assign SinLUT[214] = 18'b0000000_0111111000;
    assign SinLUT[215] = 18'b0000000_0111101101;
    assign SinLUT[216] = 18'b0000000_0111100010;
    assign SinLUT[217] = 18'b0000000_0111010111;
    assign SinLUT[218] = 18'b0000000_0111001100;
    assign SinLUT[219] = 18'b0000000_0111000001;
    assign SinLUT[220] = 18'b0000000_0110110101;
    assign SinLUT[221] = 18'b0000000_0110101010;
    assign SinLUT[222] = 18'b0000000_0110011110;
    assign SinLUT[223] = 18'b0000000_0110010011;
    assign SinLUT[224] = 18'b0000000_0110000111;
    assign SinLUT[225] = 18'b0000000_0101111100;
    assign SinLUT[226] = 18'b0000000_0101110000;
    assign SinLUT[227] = 18'b0000000_0101100100;
    assign SinLUT[228] = 18'b0000000_0101011000;
    assign SinLUT[229] = 18'b0000000_0101001101;
    assign SinLUT[230] = 18'b0000000_0101000001;
    assign SinLUT[231] = 18'b0000000_0100110101;
    assign SinLUT[232] = 18'b0000000_0100101001;
    assign SinLUT[233] = 18'b0000000_0100011101;
    assign SinLUT[234] = 18'b0000000_0100010001;
    assign SinLUT[235] = 18'b0000000_0100000100;
    assign SinLUT[236] = 18'b0000000_0011111000;
    assign SinLUT[237] = 18'b0000000_0011101100;
    assign SinLUT[238] = 18'b0000000_0011100000;
    assign SinLUT[239] = 18'b0000000_0011010100;
    assign SinLUT[240] = 18'b0000000_0011000111;
    assign SinLUT[241] = 18'b0000000_0010111011;
    assign SinLUT[242] = 18'b0000000_0010101111;
    assign SinLUT[243] = 18'b0000000_0010100010;
    assign SinLUT[244] = 18'b0000000_0010010110;
    assign SinLUT[245] = 18'b0000000_0010001001;
    assign SinLUT[246] = 18'b0000000_0001111101;
    assign SinLUT[247] = 18'b0000000_0001110000;
    assign SinLUT[248] = 18'b0000000_0001100100;
    assign SinLUT[249] = 18'b0000000_0001010111;
    assign SinLUT[250] = 18'b0000000_0001001011;
    assign SinLUT[251] = 18'b0000000_0000111110;
    assign SinLUT[252] = 18'b0000000_0000110010;
    assign SinLUT[253] = 18'b0000000_0000100101;
    assign SinLUT[254] = 18'b0000000_0000011001;
    assign SinLUT[255] = 18'b0000000_0000001100;
    
    //\\\\\\\\\\\\\\\\\\\//
    // Cosine Computer I //
    //\\\\\\\\\\\\\\\\\\\//
    
    reg [8:0] NcoIAngle;
    wire [8:0] NcoIShiftAngle = NcoIAngle + NcoPhase;
    
    // Q7.10
    wire signed [17:0] NcoI = (NcoIShiftAngle <= 255) ? SinLUT[NcoIShiftAngle] :
                                                        -SinLUT[255 - (511 - NcoIShiftAngle)];
    
    always @ (posedge AdcClk or negedge Reset_n)
    begin
        //
        // This block computes the cosine value for the I signal.
        //
        
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Clear the current LUT index.
            //
            
            NcoIAngle <= 128;
        end
        else
        begin
            //
            // Increment the NCO I angle by 1/10-th of a full cycle (1/10*360). We do this because
            // the carrier frequency is 1/10-th of the ADC sampling clock frequency.
            //
            // Delta = 512 / (AdcFreq / CarrierFreq)
            //
            
            NcoIAngle <= NcoIAngle + 51;
        end
    end
    
    //\\\\\\\\\\\\\\\\\//
    // Sine Computer Q //
    //\\\\\\\\\\\\\\\\\//
    
    reg [8:0] NcoQAngle;
    wire [8:0] NcoQShiftAngle = NcoQAngle + NcoPhase;
    
    // Q7.10
    wire signed [17:0] NcoQ = (NcoQShiftAngle <= 255) ? -SinLUT[NcoQShiftAngle] :
                                                        SinLUT[255 - (511 - NcoQShiftAngle)];
    
    always @ (posedge AdcClk or negedge Reset_n)
    begin
        //
        // This block computes the sine value for the Q signal.
        //
        
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Clear the current LUT index.
            //
            
            NcoQAngle <= 0;
        end
        else
        begin
            //
            // Increment the NCO Q angle by 1/10-th of a full cycle (1/10*360). We do this because
            // the carrier frequency is 1/10-th of the ADC sampling clock frequency.
            //
            // Delta = 512 / (AdcFreq / CarrierFreq)
            //
            
            NcoQAngle <= NcoQAngle + 51;
        end
    end
    
    //\\\\\\\\\//
    // Mixer I //
    //\\\\\\\\\//
    
    wire signed [27:0] MixICur = mSig * NcoI; // Q17.10
    reg signed [27:0] MixI[0:9]; // Q17.10
    
    always @ (posedge AdcClk or negedge Reset_n)
    begin
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Initialise the mixer value array.
            //
            
            for (i = 0; i < 10; i = i + 1) begin
                MixI[i] <= 0;
            end
        end
        else
        begin
            //
            // Concatenate the current mixer value to the mixer value array.
            //
            // NOTE: The following statement requires SystemVerilog for proper synthesis.
            //
            
            //MixI[0:19] <= { MixICur, MixI[0:18] };
            
            MixI[0]  <= MixICur;  MixI[1]  <= MixI[0];  MixI[2]  <= MixI[1];  MixI[3]  <= MixI[2];
            MixI[4]  <= MixI[3];  MixI[5]  <= MixI[4];  MixI[6]  <= MixI[5];  MixI[7]  <= MixI[6];
            MixI[8]  <= MixI[7];  MixI[9]  <= MixI[8];
        end
    end
    
    //\\\\\\\\\//
    // Mixer Q //
    //\\\\\\\\\//
    
    wire signed [27:0] MixQCur = mSig * NcoQ; // Q17.10
    reg signed [27:0] MixQ[0:9]; // Q17.10
    
    always @ (posedge AdcClk or negedge Reset_n)
    begin
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Initialise the mixer value array.
            //
            
            for (i = 0; i < 10; i = i + 1) begin
                MixQ[i] <= 0;
            end
        end
        else
        begin
            //
            // Concatenate the current mixer value to the mixer value array.
            //
            // NOTE: The following statement requires SystemVerilog for proper synthesis.
            //
            
            //MixQ[0:19] <= { MixQCur, MixQ[0:18] };
            
            MixQ[0]  <= MixQCur;  MixQ[1]  <= MixQ[0];  MixQ[2]  <= MixQ[1];  MixQ[3]  <= MixQ[2];
            MixQ[4]  <= MixQ[3];  MixQ[5]  <= MixQ[4];  MixQ[6]  <= MixQ[5];  MixQ[7]  <= MixQ[6];
            MixQ[8]  <= MixQ[7];  MixQ[9]  <= MixQ[8];
        end
    end

    //\\\\\\\\\\\\\\\\\\\//
    // Low-pass Filter I //
    //\\\\\\\\\\\\\\\\\\\//
    
    reg signed [27:0] LpfI; // Q17.10
    
    always @ (posedge AdcClk or negedge Reset_n)
    begin
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Initialise the low-pass filter value.
            //
            
            LpfI <= 0;
        end
        else
        begin
            //
            // Integrate the mixer values.
            //
            
            LpfI <= MixI[0]  + MixI[1]  + MixI[2]  + MixI[3]  + MixI[4]  +
                    MixI[5]  + MixI[6]  + MixI[7]  + MixI[8]  + MixI[9];
        end
    end
    
    //\\\\\\\\\\\\\\\\\\\//
    // Low-pass Filter Q //
    //\\\\\\\\\\\\\\\\\\\//
    
    reg signed [27:0] LpfQ; // Q17.10
    
    always @ (posedge AdcClk or negedge Reset_n)
    begin
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Initialise the low-pass filter value.
            //
            
            LpfQ <= 0;
        end
        else
        begin
            //
            // Integrate the mixer values.
            //
            
            LpfQ <= MixQ[0]  + MixQ[1]  + MixQ[2]  + MixQ[3]  + MixQ[4]  +
                    MixQ[5]  + MixQ[6]  + MixQ[7]  + MixQ[8]  + MixQ[9];
        end
    end
    
    //\\\\\\\\\\//
    // Mixer FB //
    //\\\\\\\\\\//
    
    wire signed [17:0] LpfIReduced = LpfI >>> 10; // Q17.0
    wire signed [17:0] LpfQReduced = LpfQ >>> 10; // Q17.0
    
    wire signed [35:0] MixFB = LpfIReduced * LpfQReduced; // Q35.0
    
    //\\\\\\\\\\\\\\\\\\\\\//
    // Feedback Controller //
    //\\\\\\\\\\\\\\\\\\\\\//
    
    always @ (posedge AdcClk or negedge Reset_n)
    begin
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Reset the NCO phase.
            //
            
            NcoPhase <= 0;
        end
        else
        begin
            //
            // Increment or decrement NCO phase based on the feedback mixer sign.
            //
            
            if (MixFB[35] == 0) // Positive Feedback
                NcoPhase <= NcoPhase + 1;
            else // Negative Feedback
                NcoPhase <= NcoPhase - 1;
        end
    end
    
    //\\\\\\\\\\\\\\\\\\\\//
    // Data Clock Divider //
    //\\\\\\\\\\\\\\\\\\\\//
    
    reg RxDataClk;
    reg [4:0] RxDataClkDivCnt;
    
    always @ (posedge AdcClk or negedge Reset_n)
    begin
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Clear the data clock divider counter.
            //
            
            RxDataClk <= 0;
            RxDataClkDivCnt <= 0;
        end
        else
        begin
            if (RxDataClkDivCnt == 9)
            begin
                //
                // If the counter reached the threshold, tick the data clock and reset the counter.
                //
                
                RxDataClk = ~RxDataClk;
                RxDataClkDivCnt <= 0;
            end
            else
            begin
                //
                // Increment the data clock divider counter.
                //
                
                RxDataClkDivCnt <= RxDataClkDivCnt + 1;
            end
        end
    end
    
    //\\\\\\\\\\\\//
    // Data Latch //
    //\\\\\\\\\\\\//
    
    reg RxDataBit;
    reg RxInverted;
    
    always @ (posedge RxDataClk or negedge Reset_n)
    begin
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Clear the data bit.
            //
            
            RxDataBit <= 0;
        end
        else
        begin
            //
            // Digitise the analog data from the LPF-I output. The value of the data bit depends
            // on the sign bit (27-th) of the LpfI value.
            //
            
            RxDataBit <= (RxInverted == 0) ? ~LpfI[27] : LpfI[27];
        end
    end
    
    //\\\\\\\\\\\\\\\\\\\\//
    // Receive Controller //
    //\\\\\\\\\\\\\\\\\\\\//
    
    `define RXSTATE_WAITMAGIC       0
    `define RXSTATE_RECVDATA        1
    `define RXSTATE_RECVXSUM        2
    `define RXSTATE_VERIFYXSUM      3
    
    reg [1:0] RxState;
    reg [63:0] RxMagicTemp;
    reg [31:0] RxXsumTemp;
    reg [31:0] RxXsumExpected;
    reg [10:0] RxBitIndex;
    reg [31:0] RxData [0:15] /* synthesis ramstyle = "M9K" */;
    reg RxInt;
    
    always @ (negedge RxDataClk or negedge Reset_n)
    begin
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Clear the receive data buffer and set the current receive
            // state to "wait magic".
            //
            
            RxState <= `RXSTATE_WAITMAGIC;
            RxInverted <= 0;
            RxMagicTemp <= 0;
            RxXsumTemp <= 0;
            RxXsumExpected <= 0;
            RxData[0] <= 0; // FIXME: Init all.
            RxBitIndex <= 0;
            RxInt <= 0;
        end
        else
        begin
            //
            // Reset interrupt request if set.
            //
            
            if (RxInt == 1)
            begin
                RxInt <= 0;
            end
            
            //
            // Process based on the receive state.
            //
            
            if (RxState == `RXSTATE_WAITMAGIC)
            begin
                //
                // The current receive controller state is "wait magic."
                //
                // Detect the magic packet consisting of the following bit sequence:
                //  1011_0101_1010_0110_1111_1111_1111_1111_  (B5 A6 FF FF) 
                //  1001_1011_1110_0011_0111_1100_0011_1001   (9B E3 7C 39)
                //
                
                RxMagicTemp = (RxMagicTemp << 1) | RxDataBit;
                
                if (RxMagicTemp == 64'hB5A6FFFF9BE37C39) // Non-inverted Bit Sequence
                begin
                    //
                    // A non-inverted bit sequence has been received. Switch to receive data state
                    // without data inversion.
                    //
                    
                    RxState <= `RXSTATE_RECVDATA;
                    RxInverted <= 0;
                    RxBitIndex <= 0;
                end
                else if (RxMagicTemp == ~(64'hB5A6FFFF9BE37C39)) // Inverted Bit Sequence
                begin
                    //
                    // An inverting bit sequence has been received. Switch to receive data state
                    // with data inversion.
                    //
                    
                    RxState <= `RXSTATE_RECVDATA;
                    RxInverted <= 1;
                    RxBitIndex <= 0;
                end
            end
            else if (RxState == `RXSTATE_RECVDATA)
            begin
                //
                // A data bit has been received. Latch the received data bit.
                //
                
                RxData[RxBitIndex >> 5] <= (RxData[RxBitIndex >> 5] << 1) | RxDataBit;
                
                if (RxBitIndex == 511)
                begin
                    //
                    // Received the last bit. Reset the bit index for reuse during the receive
                    // checksum stage.
                    //
                    
                    RxBitIndex <= 0;
                    
                    //
                    // Transition to receive checksum state.
                    //
                    
                    RxState <= `RXSTATE_RECVXSUM;
                end
                else
                begin
                    //
                    // Increment the data bit index.
                    //
                    
                    RxBitIndex <= RxBitIndex + 1;
                end
            end
            else if (RxState == `RXSTATE_RECVXSUM)
            begin
                //
                // Latch in the checksum bits.
                //
                
                RxXsumTemp[31 - RxBitIndex] <= RxDataBit;
                
                if (RxBitIndex == 31)
                begin
                    //
                    // Compute the checksum from the received data.
                    //
                    
                    RxXsumExpected <=
                        RxData[0]  ^ RxData[1]  ^ RxData[2]  ^ RxData[3]  ^
                        RxData[4]  ^ RxData[5]  ^ RxData[6]  ^ RxData[7]  ^
                        RxData[8]  ^ RxData[9]  ^ RxData[10] ^ RxData[11] ^
                        RxData[12] ^ RxData[13] ^ RxData[14] ^ RxData[15];
                    
                    //
                    // Received the last checksum bit. Transition to the verify checksum stage.
                    //
                    
                    RxState <= `RXSTATE_VERIFYXSUM;
                end
                else
                begin
                    //
                    // Increment the data bit index.
                    //
                    
                    RxBitIndex <= RxBitIndex + 1;
                end
            end
            else if (RxState == `RXSTATE_VERIFYXSUM)
            begin
                //
                // Reset the bit index and bit inversion state.
                //
                
                RxInverted <= 0;
                RxBitIndex <= 0;
                
                if (RxXsumTemp == RxXsumExpected)
                begin
                    //
                    // Raise the data receive interrupt only when the received checksum is valid.
                    //
                    
                    RxInt <= 1;
                end
                
                //
                // Return to the "wait magic" state.
                //
                
                RxState <= `RXSTATE_WAITMAGIC;
            end
        end
    end
    
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\//
    // Receive Interrupt Edge Detector Block //
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\//
    
    reg [1:0] RIDetect;
    
    always @ (posedge Clk or negedge Reset_n)
    begin
        //
        // This block detects the receive interrupt by storing last three bits and comparing their
        // values to the latest values.
        //
        
        if (!Reset_n)
        begin
            //
            // A reset has been issued. Clear all edge detection buffer bits.
            //
            
            RIDetect <= 0;
        end
        else
        begin
            //
            // Shift the detector buffer left and insert the latest RX bit.
            //
            
            RIDetect <= (RIDetect << 1) | RxInt;
        end
    end
    
    //
    // Detect the rising edge on the receive interrupt line.
    //
    
    wire RIRisingEdge = !RIDetect[1] & RIDetect[0];
    
    //
    // Synchronise the transmit interrupt rising edge signal to sequencer clock.
    //
    
    reg [7:0] RIDetectedSyncCnt;
    reg RIDetected;
    
    reg [31:0] DataDrv [0:15] /* synthesis ramstyle = "M9K" */;
    assign Data = DataDrv;
    
    always @ (posedge Clk or negedge Reset_n)
    begin
        if (!Reset_n)
        begin
            //
            // Initialise sync counter and TIDetected signal.
            //
            
            RIDetectedSyncCnt <= 0;
            RIDetected <= 0;
        end
        else
        begin
            if (RIRisingEdge && (RIDetectedSyncCnt == 0))
            begin
                //
                // If a rising edge is detected and the counter is not started, assert RIDetected
                // and begin synchronisation.
                //
                
                RIDetected <= 1;
                RIDetectedSyncCnt <= 1;
                
                //
                // Latch data bits only when Ack is high (i.e. interrupt is acknowledged by the
                // processor, pending = 0).
                //
                
                if (Ack)
                begin
                    //
                    // A depulicate copy is required in order to prevent processor excess contention.
                    //
                    
                    DataDrv[0] <= RxData[0];
                    DataDrv[1] <= RxData[1];
                    DataDrv[2] <= RxData[2];
                    DataDrv[3] <= RxData[3];
                    DataDrv[4] <= RxData[4];
                    DataDrv[5] <= RxData[5];
                    DataDrv[6] <= RxData[6];
                    DataDrv[7] <= RxData[7];
                    DataDrv[8] <= RxData[8];
                    DataDrv[9] <= RxData[9];
                    DataDrv[10] <= RxData[10];
                    DataDrv[11] <= RxData[11];
                    DataDrv[12] <= RxData[12];
                    DataDrv[13] <= RxData[13];
                    DataDrv[14] <= RxData[14];
                    DataDrv[15] <= RxData[15];
                    /*DataDrv[16] <= RxData[16];
                    DataDrv[17] <= RxData[17];
                    DataDrv[18] <= RxData[18];
                    DataDrv[19] <= RxData[19];
                    DataDrv[20] <= RxData[20];
                    DataDrv[21] <= RxData[21];
                    DataDrv[22] <= RxData[22];
                    DataDrv[23] <= RxData[23];
                    DataDrv[24] <= RxData[24];
                    DataDrv[25] <= RxData[25];
                    DataDrv[26] <= RxData[26];
                    DataDrv[27] <= RxData[27];
                    DataDrv[28] <= RxData[28];
                    DataDrv[29] <= RxData[29];
                    DataDrv[30] <= RxData[30];
                    DataDrv[31] <= RxData[31];*/
                end
            end
            else if (RIDetectedSyncCnt != 0)
            begin
                //
                // Wait for the ModemClk-BusClk division ratio cycles in ModemClk domain.
                //
                
                if (RIDetectedSyncCnt == ModemBusClkDiv)
                begin
                    RIDetected <= 0;
                    RIDetectedSyncCnt <= 0;
                end
                else
                begin
                    RIDetectedSyncCnt <= RIDetectedSyncCnt + 1;
                end
            end
        end
    end
    
    //
    // Connect RIDetected to Int output.
    //
    
    assign Int = RIDetected;
	
endmodule
