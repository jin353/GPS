%% 创建180秒中断数据
% 将190-280秒的GPS观测中删除31号卫星，使其变为3颗卫星
clc; clear;

addpath('functions');
addpath('data');
ggpsvars

%% 加载原始数据
load('data/obss_shanchu.mat');
t0 = obss(1,1);

%% 检查原始数据
fprintf('原始数据:\n');
fprintf('obss维度: %d x %d\n', size(obss));

%% 修改obss，将190-280秒的31号卫星观测删除
obss_new = obss;

% 找到190-280秒且卫星PRN=31的行，删除
rows_to_delete = [];
for i = 1:size(obss,1)
    t = obss(i,1) - t0;
    prn = obss(i,2);
    
    if t >= 190 && t <= 280 && prn == 31
        rows_to_delete = [rows_to_delete; i];
    end
end

fprintf('删除 %d 行 (190-280秒的31号卫星)\n', length(rows_to_delete));

% 删除这些行
obss_new(rows_to_delete, :) = [];

%% 验证修改后的数据
findgpsobs(obss_new);

fprintf('\n修改后数据:\n');
fprintf('obss维度: %d x %d\n', size(obss_new));

%% 检查GPS可用性
fprintf('\nGPS可用性检查:\n');
for t = [0, 50, 100, 150, 190, 200, 250, 280, 300]
    obsi = findgpsobs(t0 + t);
    fprintf('t = %3d s: 卫星数量 = %d', t, size(obsi,1));
    if size(obsi,1) > 0
        fprintf(', PRN: ');
        fprintf('%d ', obsi(:,2));
    end
    fprintf('\n');
end

%% 保存
save('data/obss_shanchu_180s.mat', 'obss_new');
fprintf('\n已保存: data/obss_shanchu_180s.mat\n');