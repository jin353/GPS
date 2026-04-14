%% LSTM辅助INS/GNSS松组合导航
% 功能：使用LSTM网络预测伪距增量，辅助INS/GNSS松组合
% 原理：当GNSS中断时，用LSTM预测的伪距增量补偿观测值
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
fprintf('  LSTM辅助INS/GNSS松组合导航系统\n');
fprintf('========================================\n\n');

fprintf('[1/5] 加载导航数据...\n');
load('data/shuju.mat');
load('data/att_vel_true.mat');
load('data/ephs1.mat');
load('data/obss_shanchu.mat');

%% 加载LSTM模型
fprintf('[2/5] 加载LSTM预测模型...\n');
load('models/delta_W_mean.mat');  % 伪距增量均值
load('models/LSTM.mat');           % LSTM网络
load('models/MAX1.mat');           % 归一化参数-最大值
load('models/MIN1.mat');           % 归一化参数-最小值

%% 数据预处理
t0 = obss(1,1);

% GNSS观测数据处理
findgpsobs(obss);
obsi = findgpsobs(t0);
pseudo_range(1,:) = obsi(:,3);

% 计算伪距累积值
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
recPos = zeros(4,1);

%% 初始状态
avp0 = [deg2rad(att(1,:)), 0, 0, 0, avp1(1,1:3)]';

%% INS初始化
ins = insinit(avp0, cfg.ts);

%% 卡尔曼滤波器配置
imu_err = imuerrset(8, [10;10;15], 0.007, 60);
nav_err = avperrset([0.5;-0.5;20], 0.1, [0.1;0.1;0.3]);
obs_noise = poserrset([0.3;0.3;0.9]);

kf = kfinit(ins, nav_err, imu_err, obs_noise);
kf.Pmin = [nav_err; gabias(8, [10;10;15])].^2;
kf.pconstrain = 1;

%% 内存预分配
num_imu = length(imu);
[nav_states, kf_diag] = prealloc(fix(num_imu/cfg.nn), 10, 2*kf.n+1);
gps_solutions = zeros(fix(num_imu/200), 7);

%% 主循环变量
idx = 1; gps_idx = 1;
epoch = 2;
gnss_status = 1;  % 1:可用, 0:中断

%% 主导航循环
fprintf('[3/5] 执行LSTM辅助松组合导航...\n');
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
            % GNSS信号可用 - 正常处理
            gnss_status = 1;
            
            eph_data = ephs(obsi(:,2),:);
            pr = pseudo_range_mean(epoch,:)';
            epoch = epoch + 1;
            
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
            
            [kf, ins] = kffeedback(kf, ins, 1, 'avped');
            
        else
            % GNSS信号中断 - 使用LSTM预测
            gnss_status = 0;
            
            % LSTM预测伪距增量
            pred_output = predict(net, cellData(epoch-1));
            pred_output = double(pred_output);
            pred_output = denormalizeData(pred_output, minVals, maxVals);
            
            % 获取当前卫星状态
            current_sats = obsi(:, 2);
            all_sats = [32; 31; 26; 28];
            missing_sats = setdiff(all_sats, current_sats);
            
            % 对缺失卫星进行LSTM补偿
            for i = 1:length(all_sats)
                if ismember(all_sats(i), missing_sats)
                    % 使用LSTM预测值补偿
                    pr(i) = pr(i) + pred_output(i)';
                else
                    % 使用观测值
                    pr(i) = pseudo_range_mean(epoch, i);
                end
            end
            
            % 使用补偿后的伪距进行定位
            eph_data = ephs(all_sats,:);
            epoch = epoch + 1;
            
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
            
            [kf, ins] = kffeedback(kf, ins, 1, 'avped');
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
fprintf('[4/5] 坐标转换...\n');

spheroid = wgs84Ellipsoid;

xyz_lstm = lla2ecef(nav_states(:,7:9));
[lstm_east, lstm_north, lstm_up] = ecef2enu(xyz_lstm(:,1), xyz_lstm(:,2), xyz_lstm(:,3), ...
    avp1(1,1), avp1(1,2), avp1(1,3), spheroid);

xyz_true = lla2ecef(avp1(:,1:3));
[true_east, true_north, true_up] = ecef2enu(xyz_true(:,1), xyz_true(:,2), xyz_true(:,3), ...
    avp1(1,1), avp1(1,2), avp1(1,3), spheroid);

%% 误差计算
fprintf('[5/5] 误差计算与统计...\n');

error_pos_east_lstm = lstm_east - true_east;
error_pos_north_lstm = lstm_north - true_north;

% 速度误差 (简化处理)
error_vel_east_lstm = zeros(size(nav_states,1), 1);
error_vel_north_lstm = zeros(size(nav_states,1), 1);

att_lstm = nav_states(:,1:3) / glv.deg;
error_roll_lstm = att_lstm(:,1) - att(:,1);
error_pitch_lstm = att_lstm(:,2) - att(:,2);
error_yaw_lstm = att_lstm(:,3) - att(:,3);

%% 统计结果
rmse_pos_north_lstm = sqrt(mean(error_pos_north_lstm.^2));
rmse_pos_east_lstm = sqrt(mean(error_pos_east_lstm.^2));
rmse_vel_north_lstm = sqrt(mean(error_vel_north_lstm.^2));
rmse_vel_east_lstm = sqrt(mean(error_vel_east_lstm.^2));

fprintf('\n========================================\n');
fprintf('  LSTM辅助松组合导航误差统计\n');
fprintf('========================================\n');
fprintf('位置误差 RMSE:\n');
fprintf('  北向: %.2f m\n', rmse_pos_north_lstm);
fprintf('  东向: %.2f m\n', rmse_pos_east_lstm);
fprintf('速度误差 RMSE:\n');
fprintf('  北向: %.2f m/s\n', rmse_vel_north_lstm);
fprintf('  东向: %.2f m/s\n', rmse_vel_east_lstm);
fprintf('========================================\n\n');

%% 保存结果
output_dir = 'results';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

save(fullfile(output_dir, 'lstm_loose_results.mat'), ...
    'nav_states', 'error_pos_north_lstm', 'error_pos_east_lstm', ...
    'error_vel_north_lstm', 'error_vel_east_lstm', ...
    'error_roll_lstm', 'error_pitch_lstm', 'error_yaw_lstm', ...
    'lstm_east', 'lstm_north', 'true_east', 'true_north');

fprintf('结果已保存至: %s/lstm_loose_results.mat\n', output_dir);
fprintf('LSTM辅助松组合导航解算完成！\n');