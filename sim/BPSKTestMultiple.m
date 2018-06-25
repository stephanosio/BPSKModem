% This module performs multiple tests.

numOfTrials = 100;

ber = zeros(1, numOfTrials);
phase = zeros(1, numOfTrials);

for trialNum = 1 : numOfTrials

    disp(['Trial ' num2str(trialNum)]);
    [ber(trialNum), phase(trialNum)] = BPSKTest();
    disp('-');

    close all;

end

avgBer = sum(ber) / numOfTrials;

disp(['Average Bit Error Rate: ' num2str(avgBer) '%']);
