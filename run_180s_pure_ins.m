%% 180秒中断纯INS（无LSTM辅助）
clear; clc;
addpath('functions');
addpath('data');
ggpsvars

%% 加载数据
load('data/shuju.mat');
load('data/att_vel_true.mat');
load('data/obss_shanchu.mat');
t0 = obss(1,1);

%% 数据预处理
avp1(:,1:2) = avp1(:,1:2) * glv.dps;
psinstypedef(153);

%% 初始化
nn = 1; ts = 0.005;
avp0 = [deg2rad(att(1,:)) 0 0 0 avp1(1,1:3)]';
ins = insinit(avp0, ts);

len = length(imu);
avp = zeros(fix(len/nn), 10);
ki = 1;

%% 主循环（纯INS，无GPS）
fprintf('Running pure INS (180s outage)...\n');
for k = 1:nn:len
    wvm = imu(k,1:6); tp = t0 + imu(k,end);
    ins = insupdate(ins, wvm);
    avp(ki,:) = [ins.avp', tp];
    ki = ki + 1;
    
    if mod(k, 10000) == 0
        fprintf('  Progress: %d/%d (%.1f%%)\n', k, len, k/len*100);
    end
end

%% 整理结果
avp(ki:end,:) = [];
avp(:,7:8) = avp(:,7:8) / glv.deg;
avp1(:,1:2) = avp1(:,1:2) / glv.deg;

%% 坐标转换
spheroid = wgs84Ellipsoid;
x = lla2ecef(avp(:,7:9));
[East_est, North_est, Up_est] = ecef2enu(x(:,1), x(:,2), x(:,3), ...
    avp1(1,1), avp1(1,2), avp1(1,3), spheroid);
x1 = lla2ecef(avp1(:,1:3));
[East, North, Up] = ecef2enu(x1(:,1), x1(:,2), x1(:,3), ...
    avp1(1,1), avp1(1,2), avp1(1,3), spheroid);

%% 计算误差
error_pos_east = East_est - East;
error_pos_north = North_est - North;

%% 统计
dt = 0.005;
time_vec = (0:dt:369.995)';

fprintf('\n纯INS结果:\n');
fprintf('非中断(0-100s): 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north(time_vec<100).^2)), ...
    sqrt(mean(error_pos_east(time_vec<100).^2)));
fprintf('中断(100-280s): 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north(time_vec>=100 & time_vec<280).^2)), ...
    sqrt(mean(error_pos_east(time_vec>=100 & time_vec<280).^2)));
fprintf('中断后(280-370s): 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north(time_vec>=280).^2)), ...
    sqrt(mean(error_pos_east(time_vec>=280).^2)));

%% 保存
save('results/pure_ins_180s.mat', 'error_pos_north', 'error_pos_east');
fprintf('Done!\n');