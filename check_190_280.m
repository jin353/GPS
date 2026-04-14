%% 检查190-280秒期间的GPS观测
clc; clear;

addpath('functions');
addpath('data');
ggpsvars

load('data/obss_shanchu.mat');
t0 = obss(1,1);
findgpsobs(obss);

%% 检查190-280秒的GPS观测
fprintf('190-280秒GPS观测:\n');
fprintf('========================================\n');

for t = [190, 200, 210, 220, 230, 240, 250, 260, 270, 280]
    obsi = findgpsobs(t0 + t);
    fprintf('t = %3d s: 卫星数量 = %d', t, size(obsi,1));
    if size(obsi,1) > 0
        fprintf(', 卫星PRN: ');
        fprintf('%d ', obsi(:,2));
    end
    fprintf('\n');
end