%% 纯INS导航解算
% 基于参考1代码重新编写
clear; clc;
addpath('functions');
addpath('data');
ggpsvars
psinstypedef(153);

%% 加载数据
fprintf('Loading data...\n');
load('data/shuju.mat');
load('data/att_vel_true.mat');
load('data/obss_shanchu.mat');  % 添加GNSS观测数据
t0 = obss(1,1);  % 从GNSS观测获取初始时间

%% 数据预处理
avp1(:,1:2) = avp1(:,1:2) * glv.dps;  % 度转弧度

%% 初始化参数
nn = 1; ts = 0.005;
avp0 = [deg2rad(att(1,:)) 0 0 0 avp1(1,1:3)]';
ins = insinit(avp0, ts);

len = length(imu);
avp_pure = zeros(fix(len/nn), 10);  % 9个导航参数 + 1个时间
ki = 1;

%% 主循环
fprintf('Running pure INS...\n');
for k = 1:nn:len
    wvm = imu(k, 1:6);
    tp = t0 + imu(k, end);
    ins = insupdate(ins, wvm);
    avp_pure(ki,:) = [ins.avp', tp];
    ki = ki + 1;
    if mod(k, 10000) == 0
        fprintf('  Progress: %d/%d (%.1f%%)\n', k, len, k/len*100);
    end
end

%% 整理结果
avp_pure(ki:end,:) = [];
avp_pure(:,7:8) = avp_pure(:,7:8) / glv.deg;  % 弧度转度
avp1(:,1:2) = avp1(:,1:2) / glv.deg;

%% 坐标转换 (使用与参考1相同的方法)
fprintf('Converting coordinates...\n');
spheroid = wgs84Ellipsoid;

% INS轨迹
x_ins = lla2ecef(avp_pure(:,7:9));
[East_ins, North_ins, Up_ins] = ecef2enu(x_ins(:,1), x_ins(:,2), x_ins(:,3), ...
    avp1(1,1), avp1(1,2), avp1(1,3), spheroid);

% 真实轨迹
x_true = lla2ecef(avp1(:,1:3));
[East_true, North_true, Up_true] = ecef2enu(x_true(:,1), x_true(:,2), x_true(:,3), ...
    avp1(1,1), avp1(1,2), avp1(1,3), spheroid);

%% 计算误差
error_pos_east_pureINS = East_ins - East_true;
error_pos_north_pureINS = North_ins - North_true;

%% 保存结果
output_dir = 'results';
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

save(fullfile(output_dir, 'pure_ins_results.mat'), ...
    'error_pos_north_pureINS', 'error_pos_east_pureINS', ...
    'East_ins', 'North_ins', 'East_true', 'North_true');

fprintf('Results saved to: %s\n', output_dir);
fprintf('Done!\n');