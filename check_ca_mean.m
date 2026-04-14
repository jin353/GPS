%% 检查CA_mean数组大小
clc; clear;

addpath('functions');
addpath('data');
addpath('models');
ggpsvars

load('data/obss_shanchu.mat');
t0 = obss(1,1);
findgpsobs(obss);

load('models/delta_W_mean.mat');

%% 计算CA_mean大小
CA(1,:) = [1;2;3;4]';  % 假设4颗卫星
CA_mean = CA;
for i = 2:length(W_1)+1
    CA_mean(i,:) = CA_mean(i-1,:) + W_1(i-1,:);
end

fprintf('CA_mean维度: %d x %d\n', size(CA_mean));
fprintf('W_1维度: %d x %d\n', size(W_1));

%% 计算GPS历元数量
gps_epochs = 0;
for t = 0:1:370
    obsi = findgpsobs(t0 + t);
    gps_epochs = gps_epochs + 1;
end

fprintf('\nGPS历元数量: %d\n', gps_epochs);
fprintf('CA_mean行数: %d\n', size(CA_mean, 1));

if gps_epochs > size(CA_mean, 1)
    fprintf('警告：GPS历元数量超过CA_mean行数！\n');
end