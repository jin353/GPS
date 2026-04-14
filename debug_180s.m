%% 调试180秒中断问题
clc; clear;

addpath('functions');
addpath('data');
addpath('models');
ggpsvars

%% 加载原始数据和修改后的数据
load('data/obss_shanchu.mat');
obss_original = obss;

load('data/obss_shanchu_180s.mat');
obss_modified = obss_new;

%% 检查数据
fprintf('原始obss: %d行\n', size(obss_original, 1));
fprintf('修改后obss: %d行\n', size(obss_modified, 1));

%% 检查非中断期间的数据是否完整
t0 = obss_original(1,1);

fprintf('\n非中断期间GPS观测检查:\n');
for t = [0, 50, 90, 95]
    % 原始数据
    findgpsobs(obss_original);
    obsi_orig = findgpsobs(t0 + t);
    
    % 修改后数据
    findgpsobs(obss_modified);
    obsi_mod = findgpsobs(t0 + t);
    
    fprintf('t = %3d s: 原始 %d 颗卫星, 修改后 %d 颗卫星\n', ...
        t, size(obsi_orig, 1), size(obsi_mod, 1));
end