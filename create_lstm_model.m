%% 创建符合论文设置的LSTM模型
% 论文设置：2层LSTM，64个隐藏单元
clc; clear;

fprintf('创建LSTM模型...\n');
fprintf('参数设置:\n');
fprintf('  LSTM层数: 2\n');
fprintf('  隐藏单元数: 64\n');
fprintf('  时间步长: 4\n\n');

%% 定义网络结构
layers = [
    sequenceInputLayer(12, 'Name', 'input')  % 输入12维特征
    
    lstmLayer(64, 'OutputMode', 'sequence', 'Name', 'lstm1')  % 第1层LSTM
    
    lstmLayer(64, 'OutputMode', 'last', 'Name', 'lstm2')  % 第2层LSTM
    
    fullyConnectedLayer(4, 'Name', 'fc')  % 输出4维（3颗卫星伪距增量）
    
    leakyReluLayer('Name', 'leaky_relu')  % LeakyReLU激活
    
    regressionLayer('Name', 'output')  % 回归输出
];

%% 显示网络结构
fprintf('网络结构:\n');
analyzeNetwork(layers);

%% 保存模型
save('models/LSTM_layers.mat', 'layers');
fprintf('\n网络结构已保存至: models/LSTM_layers.mat\n');

fprintf('\n注意：这只是网络结构定义，需要使用训练数据进行训练。\n');
fprintf('由于没有训练数据，我们将使用原始LSTM模型进行实验。\n');