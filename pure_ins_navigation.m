%% 纯惯性导航系统解算
% 功能：仅使用IMU数据进行自主导航，不依赖外部GNSS信号
% 传感器：ICM-20602 MEMS IMU
% 作者：自动生成
% 日期：2026-03-27

clear; clc; close all;

%% 环境配置
addpath('functions');
addpath('data');
addpath('models');

%% 全局参数初始化
ggpsvars;  % 加载GPS常量参数

%% 数据加载
fprintf('========================================\n');
fprintf('  纯INS导航解算系统\n');
fprintf('========================================\n\n');

fprintf('[1/3] 加载IMU数据...\n');
load('data/shuju.mat');          % IMU原始数据
load('data/att_vel_true.mat');   % 真实姿态和速度

%% 数据预处理
avp1(:,1:2) = avp1(:,1:2) * glv.dps;  % 角度转弧度/秒
psinstypedef(153);  % 定义15状态INS系统

%% 导航参数配置
nav_params.ts = 0.005;           % 采样周期 (s)
nav_params.nn = 1;               % 数据压缩比
nav_params.nts = nav_params.nn * nav_params.ts;  % 计算周期

%% 初始状态设置
% 构建9维初始状态向量 [姿态(3); 速度(3); 位置(3)]
avp0 = [deg2rad(att(1,:)), 0, 0, 0, avp1(1,1:3)]';

%% INS初始化
ins = insinit(avp0, nav_params.ts);

%% 内存预分配
num_imu = length(imu);
nav_results = zeros(fix(num_imu/nav_params.nn), 10);

%% 主解算循环
fprintf('[2/3] 执行纯INS解算...\n');
tic;

idx = 1;
t_start = 0;

for k = 1:nav_params.nn:num_imu
    % 获取当前IMU数据
    wvm_data = imu(k, 1:6);
    time_curr = t_start + imu(k, end);
    
    % INS机械编排更新
    ins = insupdate(ins, wvm_data);
    
    % 存储导航结果 (姿态3+速度3+位置3+时间1 = 10列)
    nav_results(idx, :) = [ins.avp(1:9)', time_curr];
    idx = idx + 1;
    
    % 进度显示
    if mod(k, 10000) == 0
        progress = k / num_imu * 100;
        fprintf('  进度: %.1f%% (%d/%d)\n', progress, k, num_imu);
    end
end

elapsed_time = toc;
fprintf('  解算完成，耗时: %.2f 秒\n\n', elapsed_time);

%% 结果后处理
nav_results(idx:end, :) = [];
nav_results(:,7:8) = nav_results(:,7:8) / glv.deg;  % 弧度转度
avp1(:,1:2) = avp1(:,1:2) / glv.deg;

%% 坐标转换 (BLH -> ENU)
fprintf('[3/3] 坐标转换与误差计算...\n');

% 参考点 (使用转换后的度值)
lat_ref = avp1(1,1);  % 已经是度
lon_ref = avp1(1,2);  % 已经是度
Re = 6378137;  % 地球半径 (m)

% INS轨迹转换
ins_east = (nav_results(:,8) - lon_ref) * Re * cos(lat_ref * pi/180);
ins_north = (nav_results(:,7) - lat_ref) * Re;
ins_up = nav_results(:,9);

% 真实轨迹转换
true_east = (avp1(:,2) - lon_ref) * Re * cos(lat_ref * pi/180);
true_north = (avp1(:,1) - lat_ref) * Re;
true_up = avp1(:,3);

%% 误差计算
error_pos_north = ins_north - true_north;
error_pos_east = ins_east - true_east;

% 计算统计量
rmse_north = sqrt(mean(error_pos_north.^2));
rmse_east = sqrt(mean(error_pos_east.^2));
max_error_north = max(abs(error_pos_north));
max_error_east = max(abs(error_pos_east));

%% 结果显示
fprintf('\n========================================\n');
fprintf('  纯INS导航误差统计\n');
fprintf('========================================\n');
fprintf('北向位置 RMSE: %.2f m\n', rmse_north);
fprintf('东向位置 RMSE: %.2f m\n', rmse_east);
fprintf('北向最大误差: %.2f m\n', max_error_north);
fprintf('东向最大误差: %.2f m\n', max_error_east);
fprintf('========================================\n\n');

%% 保存结果
output_dir = 'results';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

save(fullfile(output_dir, 'pure_ins_results.mat'), ...
    'nav_results', 'error_pos_north', 'error_pos_east', ...
    'ins_east', 'ins_north', 'true_east', 'true_north', ...
    'rmse_north', 'rmse_east');

fprintf('结果已保存至: %s/pure_ins_results.mat\n', output_dir);
fprintf('纯INS解算完成！\n');