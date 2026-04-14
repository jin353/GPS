%% 训练符合论文设置的LSTM模型
% 论文设置：2层LSTM，64个隐藏单元
clear; clc;
addpath('functions');
addpath('data');
addpath('models');

%% 加载训练数据
load('models/delta_W_mean.mat');
load('models/LSTM.mat');  % 加载原有的cellData
W_1 = delta_W_mean;

%% 准备训练数据
load('data/shuju.mat');
load('data/att_vel_true.mat');

%% 数据预处理
avp1(:,1:2) = avp1(:,1:2) * glv.deg;  % 转换为度

% 提取训练数据（与参考1一致）
inputSize = 6;  % 输入维度
weixi = size(W_1, 2);  % 卫星数量

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

%% 构建训练数据
% 使用原有的cellData
[data, minVals1, maxVals1] = normalizeData(cellData);
[W, minVals, maxVals] = normalizeData(W_1);

% 划分训练集和测试集
NUM = 100;
numObservations = numel(cellData);
dataTrain = cell(numObservations, 1);
dataTest = zeros(numObservations, weixi);

for i = 1:numObservations
    dataTrain{i,1} = cellData{i};
    dataTest(i,:) = W(i,:);
end

XTrain = dataTrain(1:NUM,:);
YTrain = dataTest(1:NUM,:);
XTest = dataTrain(NUM+1:NUM+101,:);
YTest = dataTest(NUM+1:NUM+101,:);

%% 创建符合论文设置的LSTM网络
fprintf('创建LSTM网络...\n');
fprintf('参数设置:\n');
fprintf('  LSTM层数: 2\n');
fprintf('  隐藏单元数: 64\n\n');

numHiddenUnits = 64;  % 隐藏单元数（论文设置）
numResponses = weixi;  % 输出维度

layers = [ ...
    sequenceInputLayer(inputSize)           % 输入层
    lstmLayer(numHiddenUnits, 'OutputMode', 'sequence')  % 第1层LSTM
    lstmLayer(numHiddenUnits, 'OutputMode', 'last')      % 第2层LSTM
    fullyConnectedLayer(numResponses)       % 全连接层
    leakyReluLayer(2)                       % LeakyReLU激活
    regressionLayer];                       % 回归层

%% 训练选项
options = trainingOptions('adam', ...
    'MaxEpochs', 400, ...
    'GradientThreshold', 1, ...
    'InitialLearnRate', 0.01, ...
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropPeriod', 100, ...
    'LearnRateDropFactor', 0.15, ...
    'ValidationData', {XTest, YTest}, ...
    'Verbose', 1, ...
    'Plots', 'training-progress');

%% 训练网络
fprintf('开始训练LSTM网络...\n');
tic;
net = trainNetwork(XTrain, YTrain, layers, options);
elapsedTime = toc;
fprintf('训练完成！耗时: %.2f 秒\n', elapsedTime);

%% 保存模型
save('models/LSTM_paper.mat', 'net', 'cellData', 'maxVals', 'minVals');
fprintf('模型已保存至: models/LSTM_paper.mat\n');

%% 测试模型
YPred = predict(net, XTrain);
YPred = double(YPred);
YPred_test = predict(net, XTest);
YPred_test = double(YPred_test);

YPred = denormalizeData(YPred, minVals, maxVals);
YPred_test = denormalizeData(YPred_test, minVals, maxVals);
YTrain_denorm = denormalizeData(YTrain, minVals, maxVals);
YTest_denorm = denormalizeData(YTest, minVals, maxVals);

%% 计算误差
mseTrain = immse(YTrain_denorm, YPred);
mseTest = immse(YTest_denorm, YPred_test);
maeTrain = mean(abs(YTrain_denorm - YPred));
maeTest = mean(abs(YTest_denorm - YPred_test));
stdTrain = std(YTrain_denorm - YPred);
stdTest = std(YTest_denorm - YPred_test);

fprintf('\n训练结果:\n');
fprintf('  训练MSE: %.6f, 测试MSE: %.6f\n', mseTrain, mseTest);
fprintf('  训练MAE: %.6f, 测试MAE: %.6f\n', maeTrain, maeTest);
fprintf('  训练STD: %.6f, 测试STD: %.6f\n', stdTrain, stdTest);

fprintf('\n完成！\n');