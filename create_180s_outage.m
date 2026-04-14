%% 创建180秒GPS中断的数据集
% 将原来的91秒中断(100-191秒)延长到180秒(100-280秒)
clc; clear;

addpath('functions');
addpath('data');
ggpsvars

%% 加载原始数据
load('data/obss_shanchu.mat');
t0 = obss(1,1);

%% 数据预处理
findgpsobs(obss);

%% 检查原始数据结构
fprintf('原始数据结构:\n');
fprintf('========================================\n');
fprintf('obss维度: %d x %d\n', size(obss));
fprintf('时间范围: %.1f - %.1f s\n', obss(1,1), obss(end,1));
fprintf('总时长: %.1f s\n', obss(end,1) - obss(1,1));

%% 修改GPS观测数据，延长中断到180秒
% 原始：100-191秒中断（91秒）
% 修改：100-280秒中断（180秒）

% 创建新的obss矩阵
obss_new = obss;

% 找到100-280秒之间的GPS观测，将卫星数量改为3（模拟中断）
for i = 1:size(obss,1)
    t = obss(i,1) - t0;
    if t >= 100 && t <= 280
        % 将这一行的某些观测设为无效（通过修改时间戳使其无法被findgpsobs找到）
        % 或者直接删除这些行
        obss_new(i,1) = -1;  % 标记为无效
    end
end

% 删除无效行
obss_new(obss_new(:,1) == -1, :) = [];

%% 验证修改后的数据
findgpsobs(obss_new);

fprintf('\n修改后数据结构:\n');
fprintf('========================================\n');
fprintf('obss维度: %d x %d\n', size(obss_new));
fprintf('时间范围: %.1f - %.1f s\n', obss_new(1,1), obss_new(end,1));

%% 检查GPS可用性
fprintf('\nGPS可用性检查:\n');
fprintf('========================================\n');

time_check = [0, 60, 100, 150, 200, 250, 280, 281, 300, 350];
for t = time_check
    obsi = findgpsobs(t0 + t);
    sat_count = size(obsi,1);
    if sat_count >= 4
        status = '可用';
    else
        status = '不可用';
    end
    fprintf('t = %3d s: 卫星数量 = %d (%s)\n', t, sat_count, status);
end

%% 保存修改后的数据
save('data/obss_shanchu_180s.mat', 'obss_new');
fprintf('\n已保存修改后的数据: data/obss_shanchu_180s.mat\n');

%% 找到GPS恢复时间
for t = 100:1:400
    obsi = findgpsobs(t0 + t);
    if size(obsi,1) >= 4
        fprintf('GPS恢复时间: t = %d s\n', t);
        fprintf('中断时长: %d s\n', t - 100);
        break;
    end
end