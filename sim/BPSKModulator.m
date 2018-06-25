%++
%
% RELEASED FOR ACADEMIC AND NON-COMMERCIAL USE ONLY
%
% Module Name:
%
%    BPSKModulator.m
%
% Abstract:
%
%    This module implements BPSK modulator model.
%
% Author:
%
%    Stephanos Ioannidis (root@stephanos.io)  12-Aug-2016
%
% Revision History:
%
%    Stephanos Ioannidis (root@stephanos.io)  24-Aug-2016
%       Refactored the modulator implementation to be modular so that it
%       can be referenced from the top level module and used in conjunction
%       with the demodulator.
%
%--

% This function modulates input data onto a sine carrier.
%
% Input:
%   f = Frequency of the carrier (in Hz)
%   M = Modulation index
%   data = Array of binary data used to modulate the carrier
%
% Output:
%   carrier = Carrier discrete waveform data array
%   nrzData = NRZ encoded data
%   mSig = Modulated carrier discrete waveform data array

function [carrier, nrzData, mSig] = BPSKModulator(fs, f, M, data)

    % ==
    % Carrier Parameter Definition
    % ==

    % [ Control Parameters ]
    T = 1 / f; % Carrier Period: 1 / Carrier Frequency
    Ts = 1 / fs; % Sampling Period: 1 / Sampling Frequency
    n = M * length(data); % Total number of cycles

    % [ Carrier Wave Equation ]
    t = 0 : Ts : n * T;
    carrier = sin(2 * pi * f * t);

    % ==
    % Polar NRZ Encoder
    % ==

    % Generate polar (-1, 1) data.
    polarData = data * 2 - 1;

    % Map data points to pulse array.
    tp = 0 : Ts : M * T;
    nrzData = [ ];

    for (i = 1 : length(polarData))
        for (j = 1 : length(tp) - 1)
            nrzData = [ nrzData polarData(i) ];
        end
    end

    nrzData = [ nrzData 0 ];

    % ==
    % Modulation
    % ==

    % Mix
    mSig = nrzData .* carrier;

    % Display FFT.
    fftResult = fft(mSig);
    fftWindow = hamming(length(fftResult))';
    fftResultWindowed = fftResult .* fftWindow;
    fftAmpResult = abs(fftResultWindowed);
    fftAmpResultHalf = fftAmpResult(1 : int32(length(fftAmpResult) / 2));
    fftFreqAxis = 0 : (fs / 2) / length(fftAmpResultHalf) : ...
                      (fs / 2) - (fs / 2) / length(fftAmpResultHalf);
    
    figure;
    plot(fftFreqAxis, fftAmpResultHalf);
    title('Modulated Signal Spectrum');
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (unitless)');

end
