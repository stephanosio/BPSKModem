%++
%
% RELEASED FOR ACADEMIC AND NON-COMMERCIAL USE ONLY
%
% Module Name:
%
%    BPSKDemodulator.m
%
% Abstract:
%
%    This module implements BPSK demodulator model.
%
% Author:
%
%    Stephanos Ioannidis (root@stephanos.io)  25-Aug-2016
%
% Revision History:
%
%--

% This function demodulates data from a BPSK modulated sine carrier.
%
% Input:
%   f = Frequency of the carrier (in Hz)
%   M = Modulation index
%   mSig = BPSK modulated carrier discrete waveform data array
%
% Output:
%   carrier = Recovered carrier discrete waveform data array
%   dmData = Array of demodulated binary data

function [nco_i, dmData, lpf1, phase] = BPSKDemodulator(fs, f, M, mSig)

    % ==
    % Demodulation Parameters
    % ==
    
    ncoFrequency = f;
    ncoInitPhase = -pi / 2; %pi / 3;
    ncoStep = 5E-5;
    lpfDepth = 20;

    % ==
    % Data Normalization
    % ==
    
    [~, N] = size(mSig);
    
    T = 1 / f; % Carrier Period: 1 / Carrier Frequency
    Ts = 1 / fs; % Sampling Period: 1 / Sampling Frequency
    
    t = 0 : Ts : (N - 1) / fs;
    
    % ==
    % Costas Loop Carrier Recovery and Demodulation
    % ==
    
    % Initialise processing array.
    carrier = zeros(1, N);
    nco_i = zeros(1, N);
    nco_q = zeros(1, N);
    mix1 = zeros(1, N);
    mix2 = zeros(1, N);
    mix3 = zeros(1, N);
    lpf1 = zeros(1, N);
    lpf2 = zeros(1, N);
    phase = zeros(1, N);
    phase(1) = ncoInitPhase;
    
    % Process data.
    for i = 1 : N
        %
        % NCO Phase Feedback
        %
        
        if i > 1
            % Adjust the NCO frequency based on the feedback.
            phase(i) = ...
                phase(i - 1) - (ncoStep * pi * sign(mix3(i - 1)));
        end
        
        %
        % NCO
        %
        
        nco_i(i) = cos(2 * pi * ncoFrequency * t(i) + phase(i));
        nco_q(i) = sin(2 * pi * ncoFrequency * t(i) + phase(i));
        
        %
        % Input Mixer
        %
        
        mix1(i) = mSig(i) * nco_i(i);
        mix2(i) = mSig(i) * nco_q(i);
        
        %
        % Low-pass Filter
        %
        
        if i <= lpfDepth
            for j = 1 : i
                lpf1(i) = lpf1(i) + mix1(j);
                lpf2(i) = lpf2(i) + mix2(j);
            end
        else
            for j = i - lpfDepth + 1 : i
                lpf1(i) = lpf1(i) + mix1(j);
                lpf2(i) = lpf2(i) + mix2(j);
            end
        end
        
        %
        % Feedback Mixer
        %
        
        mix3(i) = lpf1(i) * lpf2(i);
    end
    
    % ==
    % Bit Decoder
    % ==
    
    saPerCycl = T / Ts; % Samples per Cycle
    saPerSym = saPerCycl * M; % Samples per Symbol
    BN = round(N / saPerSym); % Number of Bits
    
    dmData = zeros(1, BN);
    
    for i = 1 : BN
        if lpf1(i * saPerSym) >= 0
            dmData(i) = 1;
        else
            dmData(i) = 0;
        end
    end
    
end
