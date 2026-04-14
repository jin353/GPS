%% 检查原始90秒中断期间的GPS观测
clc; clear;

addpath('functions');
addpath('data');
ggpsvars

load('data/obss_shanchu.mat');
t0 = obss(1,1);
findgpsobs(obss);

%% 检查100-190秒（原始中断期间）的GPS观测
fprintf('原始中断期间(100-190秒)GPS观测:\n');
fprintf('========================================\n');

for t = [100, 110, 120, 130, 140, 150, 160, 170, 180, 190]
    obsi = findgpsobs(t0 + t);
    fprintf('t = %3d s: 卫星数量 = %d', t, size(obsi,1));
    if size(obsi,1) > 0
        fprintf(', 卫星PRN: ');
        fprintf('%d ', obsi(:,2));
    end
    fprintf('\n');
end

%% 检查参考1代码中LSTM预测的逻辑
fprintf('\n参考1 LSTM预测逻辑:\n');
fprintf('========================================\n');
fprintf('1. GPS不可用时(size(obsi,1)<4)，song=0\n');
fprintf('2. song==0时，使用LSTM预测\n');
fprintf('3. current_satellites = obsi(:,2) - 获取当前可见卫星\n');
fprintf('4. all_satellites = [32;31;26;28] - 所有卫星\n');
fprintf('5. missing_satellites = setdiff(all_satellites, current_satellites)\n');
fprintf('6. 对缺失卫星使用LSTM预测值补偿\n');