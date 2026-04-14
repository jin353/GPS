%% 训练符合论文设置的LSTM模型（64个隐藏单元）
clear; clc;
addpath('functions');
addpath('data');
addpath('models');
addpath('models/training_data');
ggpsvars

%% 加载训练数据
load('models/training_data/delta_W_mean.mat');
load('models/training_data/LSTM.mat');  % 包含cellData, minVals, maxVals

%% 准备数据
weixi = size(W_1, 2);
inputSize = 6;

% 归一化函数
function [normalizedData, minVals, maxVals] = normalizeData(data)
    [~, a] = size(data);
    for i = 1:a
        minVals(i) = min(data(:,i));
        maxVals(i) = max(data(:,i));
        normalizedData(:,i) = (data(:,i) - minVals(i)) ./ (maxVals(i) - minVals(i));
    end
end

function originalData = denormalizeData(normalizedData, minVals, maxVals)
    [~, a] = size(normalizedData);
    for i = 1:a
        originalData(:,i) = normalizedData(:,i) .* (maxVals(i) - minVals(i)) + minVals(i);
    end
end

[W_norm, minVals_W, maxVals_W] = normalizeData(W_1);

numObservations = numel(cellData);
dataTrain = cell(numObservations, 1);
dataTest = zeros(numObservations, weixi);

for i = 1:numObservations
    dataTrain{i,1} = cellData{i};
    dataTest(i,:) = W_norm(i,:);
end

NUM = 100;
XTrain = dataTrain(1:NUM,:);
YTrain = dataTest(1:NUM,:);
XTest = dataTrain(NUM+1:min(NUM+101, numObservations),:);
YTest = dataTest(NUM+1:min(NUM+101, numObservations),:);

%% 创建LSTM网络（论文设置：2层LSTM，64个隐藏单元）
fprintf('创建LSTM网络（2层，64个隐藏单元）...\n');

numHiddenUnits = 64;
numResponses = weixi;

layers = [
    sequenceInputLayer(inputSize)
    lstmLayer(numHiddenUnits, 'OutputMode', 'sequence')
    lstmLayer(numHiddenUnits, 'OutputMode', 'last')
    fullyConnectedLayer(numResponses)
    leakyReluLayer(2)
    regressionLayer
];

%% 训练选项
options = trainingOptions('adam', ...
    'MaxEpochs', 200, ...
    'GradientThreshold', 1, ...
    'InitialLearnRate', 0.01, ...
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropPeriod', 50, ...
    'LearnRateDropFactor', 0.2, ...
    'ValidationData', {XTest, YTest}, ...
    'ValidationFrequency', 10, ...
    'Verbose', 1, ...
    'Plots', 'none');

%% 训练网络
fprintf('开始训练...\n');
tic;
net = trainNetwork(XTrain, YTrain, layers, options);
elapsedTime = toc;
fprintf('训练完成！耗时: %.2f 秒\n', elapsedTime);

%% 保存模型
cellData_new = cellData;
save('models/LSTM_64units.mat', 'net', 'cellData_new', 'maxVals_W', 'minVals_W');
fprintf('模型已保存至: models/LSTM_64units.mat\n');

%% 测试
YPred = predict(net, XTest);
YPred = double(YPred);
YPred_denorm = denormalizeData(YPred, minVals_W, maxVals_W);
YTest_denorm = denormalizeData(YTest, minVals_W, maxVals_W);

maeTest = mean(abs(YTest_denorm - YPred_denorm));
fprintf('测试MAE: %.6f\n', maeTest);

fprintf('完成！\n');