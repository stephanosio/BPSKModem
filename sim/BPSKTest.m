%++
%
% RELEASED FOR ACADEMIC AND NON-COMMERCIAL USE ONLY
%
% Module Name:
%
%    BPSKTest.m
%
% Abstract:
%
%    This module implements a test routine for the BPSK modem.
%
% Author:
%
%    Stephanos Ioannidis (root@stephanos.io)  25-Aug-2016
%
% Revision History:
%
%--

function [bitErrorRate, finalPhase] = BPSKTest()

% ==
% Global Parameters
% ==

% Define modem parameters.
samplingFrequency = 10E6; % 10MHz
carrierFrequency = 1E6; % 1MHz
modulationIndex = 2; % Modulate at one bit per two cycles
noiseVariance = 0.0;
dataLength = 1024 * 8; % 8192 bits
dataSet = 1;    % 0 = Preset 1, 1 = Random, 2 = Alternating 0/1, 3 = Zeros,
                % 4 = BPSK Demod Test Sequence

% Define source digital data.

% -- Preset Data
if dataSet == 0
    txData = [ 0 1 0 0 1 1 0 1 ];
    dataLength = 8;
end
% --

% -- Random Data
if dataSet == 1
    txData = randi([0 1], 1, dataLength);
end
% --

% -- Alternating 0s and 1s
if dataSet == 2
    txData = 1 : 1 : dataLength;
    txData = mod(txData, 2);
end
% --

% -- Zeros
if dataSet == 3
    txData = zeros(1, dataLength);
end
% --

% -- BPSK Demod Test Sequence
if dataSet == 4
    txData = [ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ]; % Null
    txData = [ txData 1 0 1 1 0 1 0 1 1 0 1 0 0 1 1 0 ]; % Magic
    txData = [ txData 0 0 1 0 1 1 1 1 ]; % Data
    txData = [ txData 1 0 0 0 1 0 0 0 ]; % Rubbish
    dataLength = 48;
end
% --

if dataSet >= 5
    disp('Invalid data set type.');
    error;
end

% ==
% Transmitter
% ==

% Modulate.
[txCarrierWave, txNrzData, txModulatedWave] = BPSKModulator( ...
    samplingFrequency, carrierFrequency, modulationIndex, txData);

% Plot carrier and modulated waves.
figure;

subplot(3, 1, 1);
plot(txCarrierWave);
title('TX Carrier');

subplot(3, 1, 2);
stem(txData);
title('TX Data');

subplot(3, 1, 3);
plot(txModulatedWave);
title('TX Modulated');

% ==
% Transmission Line
% ==

lineNoise = sqrt(noiseVariance) * randn(1, length(txModulatedWave));

rxModulatedWave = txModulatedWave + lineNoise;

% ==
% Receiver
% ==

% Demodulate.

[rxCarrierWave, rxData, rxLPF1, rxPhase] = BPSKDemodulator( ...
    samplingFrequency, carrierFrequency, modulationIndex, rxModulatedWave);

% Plot carrier and demodulated wave.
figure;

subplot(3, 2, 1);
plot(rxModulatedWave);
title('RX Modulated');

subplot(3, 2, 2);
plot(rxPhase);
title('RX Costas Loop Phase');

subplot(3, 2, 3);
plot(rxCarrierWave);
title('RX Carrier');

subplot(3, 2, 4);
plot(rxLPF1);
title('RX Costas Loop LPF1');

subplot(3, 2, 5);
stem(rxData);
title('RX Data');

% Generate constellation diagram.
rxConstellationI = zeros(1, dataLength);
rxConstellationQ = zeros(1, dataLength);

T = 1 / carrierFrequency; % Carrier Period: 1 / Carrier Frequency
Ts = 1 / samplingFrequency; % Sampling Period: 1 / Sampling Frequency

saPerCycl = T / Ts; % Samples per Cycle
saPerSym = saPerCycl * modulationIndex; % Samples per Symbol

for i = 1 : dataLength
    rxConstellationI(i) = rxLPF1(i * saPerSym);
end

subplot(3, 2, 6);
stem(rxConstellationI, rxConstellationQ);
title('RX Constellation');
axis([-20, 20, -1, 1]);

% Compute bit error rate (BER).
bitErrorCount = 0;

for i = 1 : dataLength
    if txData(i) ~= rxData(i)
        bitErrorCount = bitErrorCount + 1;
    end
end

bitErrorRate = bitErrorCount / dataLength * 100;
finalPhase = rxPhase(length(rxPhase));

disp(['Bit Error Count: ' num2str(bitErrorCount)]);
disp(['Bit Error Rate: ' num2str(bitErrorRate) '%']);
disp(['Costas Loop Final Phase: ' num2str(finalPhase) ' rad']);

% Plot transmit and receive data comparison.
%{
figure;

[~, N] = size(rxNrzData);

T = 1 / carrierFrequency; % Carrier Period: 1 / Carrier Frequency
Ts = 1 / samplingFrequency; % Sampling Period: 1 / Sampling Frequency

samplesPerCycle = T / Ts;
samplesPerSymbol = samplesPerCycle * modulationIndex;

t = 0 : Ts : (N - 1) / samplingFrequency;

plot(t, txNrzData, t, rxNrzData);
xlim([5.0E-3 5.05E-3]);
ylim([-1.1 1.1]);
%}

% Calculate bit error rate.
%{
rxData = zeros(1, dataLength);

for i = 1 : dataLength
    if rxNrzData(samplesPerSymbol * i) == 1
        rxData(i) = 1;
    else
        rxData(i) = 0;
    end
end

BEC = 0;



disp(BEC);
%}

% T / Ts = samples per cycle
% (T / Ts) * M = samples per symbol

%{
input = rxData;

d = fdesign.lowpass('Fp,Fst,Ap,Ast',0.001,0.045,1.60);
Hd = design(d,'equiripple');
fvtool(Hd)

output = filter(Hd,input);

figure;
plot(output);
%}

end
