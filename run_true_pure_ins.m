%% 真正的纯INS导航 (无任何GPS辅助)
clear; clc;
addpath('functions');
addpath('data');
ggpsvars
psinstypedef(153);

%% 加载数据
load('data/shuju.mat');
load('data/att_vel_true.mat');
load('data/obss_shanchu.mat');
t0 = obss(1,1);

%% 数据预处理
avp1(:,1:2) = avp1(:,1:2) * glv.dps;

%% 初始化
nn = 1; ts = 0.005;
avp0 = [deg2rad(att(1,:)) 0 0 0 avp1(1,1:3)]';
ins = insinit(avp0, ts);

len = length(imu);
avp_pure = zeros(fix(len/nn), 10);
ki = 1;

%% 主循环 (纯INS，无GPS)
fprintf('Running pure INS (no GPS)...\n');
for k = 1:nn:len
    wvm = imu(k,1:6); tp = t0 + imu(k,end);
    ins = insupdate(ins, wvm);
    avp_pure(ki,:) = [ins.avp', tp];
    ki = ki + 1;
    
    if mod(k, 10000) == 0
        fprintf('  Progress: %d/%d (%.1f%%)\n', k, len, k/len*100);
    end
end

%% 整理结果
avp_pure(ki:end,:) = [];
avp_pure(:,7:8) = avp_pure(:,7:8) / glv.deg;
avp1(:,1:2) = avp1(:,1:2) / glv.deg;

%% 坐标转换
spheroid = wgs84Ellipsoid;
x = lla2ecef(avp_pure(:,7:9));
[East_est, North_est, Up_est] = ecef2enu(x(:,1), x(:,2), x(:,3), ...
    avp1(1,1), avp1(1,2), avp1(1,3), spheroid);
x1 = lla2ecef(avp1(:,1:3));
[East, North, Up] = ecef2enu(x1(:,1), x1(:,2), x1(:,3), ...
    avp1(1,1), avp1(1,2), avp1(1,3), spheroid);

%% 计算误差
error_pos_east_pureINS = East_est - East;
error_pos_north_pureINS = North_est - North;

%% 保存
save('results/true_pure_ins_results.mat', ...
    'error_pos_north_pureINS', 'error_pos_east_pureINS');
fprintf('Done!\n');