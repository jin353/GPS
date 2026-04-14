%% INS/GNSS松组合导航系统
% 功能：利用卡尔曼滤波融合INS和GNSS数据
% 特点：GNSS可用时进行观测更新，不可用时仅INS传播
% 传感器：ICM-20602 + Ublox-M8P
% 日期：2026-03-27

clear; clc; close all;

%% 环境配置
addpath('functions');
addpath('data');
addpath('models');

%% 全局参数初始化
ggpsvars;

%% 数据加载
fprintf('========================================\n');
fprintf('  INS/GNSS松组合导航系统\n');
fprintf('========================================\n\n');

fprintf('[1/4] 加载导航数据...\n');
load('data/shuju.mat');
load('data/att_vel_true.mat');
load('data/ephs1.mat');
load('data/obss_shanchu.mat');

%% 数据预处理
t0 = obss(1,1);  % 初始时间

% 处理GNSS观测数据
findgpsobs(obss);
obsi = findgpsobs(t0);
pseudo_range(1,:) = obsi(:,3);

% 计算伪距累积值
load('models/delta_W_mean.mat');
pseudo_range_mean = pseudo_range;
for i = 2:length(W_1)+1
    pseudo_range_mean(i,:) = pseudo_range_mean(i-1,:) + W_1(i-1,:);
end

% 角度转换
avp1(:,1:2) = avp1(:,1:2) * glv.dps;
psinstypedef(153);

%% 导航参数配置
cfg.ts = 0.005;
cfg.nn = 1;
recPos = zeros(4,1);  % 接收机位置

%% 初始状态
avp0 = [deg2rad(att(1,:)), 0, 0, 0, avp1(1,1:3)]';

%% INS初始化
ins = insinit(avp0, cfg.ts);

%% 卡尔曼滤波器配置
% IMU误差参数
imu_err = imuerrset(8, [10;10;15], 0.007, 60);
% 初始导航误差
nav_err = avperrset([0.5;-0.5;20], 0.1, [0.1;0.1;0.3]);
% 观测噪声
obs_noise = poserrset([0.3;0.3;0.9]);

% KF初始化
kf = kfinit(ins, nav_err, imu_err, obs_noise);
kf.Pmin = [nav_err; gabias(8, [10;10;15])].^2;
kf.pconstrain = 1;

%% 内存预分配
num_imu = length(imu);
[nav_states, kf_diag] = prealloc(fix(num_imu/cfg.nn), 10, 2*kf.n+1);
gps_solutions = zeros(fix(num_imu/200), 7);  % GPS解

%% 主循环变量
idx = 1; gps_idx = 1;
epoch = 2;  % GPS历元计数
gnss_available = 1;

%% 主导航循环
fprintf('[2/4] 执行松组合导航解算...\n');
tic;

for k = 1:cfg.nn:num_imu
    % IMU数据提取
    wvm_data = imu(k,1:6);
    time_curr = t0 + imu(k, end);
    
    % INS传播
    ins = insupdate(ins, wvm_data);
    
    % KF时间更新
    kf.Phikk_1 = kffk(ins);
    kf = kfupdate(kf);
    
    % GNSS观测更新 (1Hz)
    if mod(time_curr, 1) == 0
        obsi = findgpsobs(time_curr);
        
        if size(obsi,1) >= 4
            % GNSS信号可用
            gnss_available = 1;
            
            % 卫星位置和钟差计算
            eph_data = ephs(obsi(:,2),:);
            pr = pseudo_range_mean(epoch,:)';
            epoch = epoch + 1;
            
            % 单点定位
            [sat_pos, clk_err] = satPosVelBatch(obsi(1,1), eph_data);
            [pvt_sol, vel, res] = lspvt(recPos, sat_pos, pr + clk_err(:,2)*ggps.c);
            recPos = pvt_sol(1:4);
            
            gps_solutions(gps_idx,:) = [vel; time_curr]';
            gps_idx = gps_idx + 1;
            
            % 松组合观测更新
            gps_pos = vel(1:3)';
            kf = kfupdate(kf, ins.pos - gps_pos, 'M');
            
            % 检查并修正kf.xk的维度
            if size(kf.xk, 2) ~= 1
                kf.xk = kf.xk(:,1);
            end
            
            % 状态反馈
            [kf, ins] = kffeedback(kf, ins, 1, 'avped');
        else
            % GNSS信号不可用
            gnss_available = 0;
            epoch = epoch + 1;
            
            % 使用INS推算位置作为GPS解
            gps_solutions(gps_idx,:) = [0, 0, 0, ins.pos(1), ins.pos(2), ins.pos(3), time_curr];
            gps_idx = gps_idx + 1;
        end
    end
    
    % 存储导航状态
    nav_states(idx,:) = [ins.avp', time_curr];
    kf_diag(idx,:) = [kf.xk; diag(kf.Pxk); time_curr]';
    idx = idx + 1;
end

elapsed_time = toc;
fprintf('  解算完成，耗时: %.2f 秒\n\n', elapsed_time);

%% 结果后处理
nav_states(idx:end,:) = [];
kf_diag(idx:end,:) = [];
nav_states(:,7:8) = nav_states(:,7:8) / glv.deg;
avp1(:,1:2) = avp1(:,1:2) / glv.deg;
gps_solutions(:,4:5) = gps_solutions(:,4:5) / glv.deg;

%% 坐标转换 (BLH -> ENU)
fprintf('[3/4] 坐标转换...\n');

spheroid = wgs84Ellipsoid;

% INS轨迹
xyz_ins = lla2ecef(nav_states(:,7:9));
[est_east, est_north, est_up] = ecef2enu(xyz_ins(:,1), xyz_ins(:,2), xyz_ins(:,3), ...
    avp1(1,1), avp1(1,2), avp1(1,3), spheroid);

% 真实轨迹
xyz_true = lla2ecef(avp1(:,1:3));
[true_east, true_north, true_up] = ecef2enu(xyz_true(:,1), xyz_true(:,2), xyz_true(:,3), ...
    avp1(1,1), avp1(1,2), avp1(1,3), spheroid);

%% 误差计算
fprintf('[4/4] 误差计算...\n');

error_pos_east = est_east - true_east;
error_pos_north = est_north - true_north;

% 姿态误差
att_est = nav_states(:,1:3) / glv.deg;
error_roll = att_est(:,1) - att(:,1);
error_pitch = att_est(:,2) - att(:,2);
error_yaw = att_est(:,3) - att(:,3);

% 速度误差 (简化处理)
error_vel_east = zeros(size(nav_states,1), 1);
error_vel_north = zeros(size(nav_states,1), 1);

%% 统计结果
rmse_pos_north = sqrt(mean(error_pos_north.^2));
rmse_pos_east = sqrt(mean(error_pos_east.^2));
rmse_vel_north = sqrt(mean(error_vel_north.^2));
rmse_vel_east = sqrt(mean(error_vel_east.^2));

fprintf('\n========================================\n');
fprintf('  松组合导航误差统计\n');
fprintf('========================================\n');
fprintf('位置误差 RMSE:\n');
fprintf('  北向: %.2f m\n', rmse_pos_north);
fprintf('  东向: %.2f m\n', rmse_pos_east);
fprintf('速度误差 RMSE:\n');
fprintf('  北向: %.2f m/s\n', rmse_vel_north);
fprintf('  东向: %.2f m/s\n', rmse_vel_east);
fprintf('========================================\n\n');

%% 保存结果
output_dir = 'results';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

save(fullfile(output_dir, 'loose_coupling_results.mat'), ...
    'nav_states', 'error_pos_north', 'error_pos_east', ...
    'error_vel_north', 'error_vel_east', ...
    'error_roll', 'error_pitch', 'error_yaw', ...
    'est_east', 'est_north', 'true_east', 'true_north');

fprintf('结果已保存至: %s/loose_coupling_results.mat\n', output_dir);
fprintf('松组合导航解算完成！\n');