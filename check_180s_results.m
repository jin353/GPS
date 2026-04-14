%% 检查180秒中断结果
clc; clear;

load('G:\lunwen\V5\code\results\lstm_loose_180s_results.mat');

fprintf('180秒中断LSTM结果检查:\n');
fprintf('========================================\n');
fprintf('error_pos_north_lstm维度: %d x %d\n', size(error_pos_north_lstm));
fprintf('error_pos_east_lstm维度: %d x %d\n', size(error_pos_east_lstm));

% 检查数据范围
fprintf('\n数据范围:\n');
fprintf('北向误差: [%.2f, %.2f] m\n', min(error_pos_north_lstm), max(error_pos_north_lstm));
fprintf('东向误差: [%.2f, %.2f] m\n', min(error_pos_east_lstm), max(error_pos_east_lstm));

% 检查不同时间段
dt = 0.005;
time_vec = (0:dt:369.995)';

fprintf('\n分时间段检查:\n');
fprintf('非中断(0-100s): 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north_lstm(time_vec<100).^2)), ...
    sqrt(mean(error_pos_east_lstm(time_vec<100).^2)));

fprintf('中断前半段(100-190s): 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north_lstm(time_vec>=100 & time_vec<190).^2)), ...
    sqrt(mean(error_pos_east_lstm(time_vec>=100 & time_vec<190).^2)));

fprintf('中断后半段(190-280s): 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north_lstm(time_vec>=190 & time_vec<280).^2)), ...
    sqrt(mean(error_pos_east_lstm(time_vec>=190 & time_vec<280).^2)));

fprintf('中断后(280-370s): 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north_lstm(time_vec>=280).^2)), ...
    sqrt(mean(error_pos_east_lstm(time_vec>=280).^2)));