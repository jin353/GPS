%% 检查180秒中断的详细结果
clc; clear;

load('G:\lunwen\V5\code\results\lstm_loose_180s.mat');

dt = 0.005;
time_vec = (0:dt:369.995)';

%% 检查不同时间段
fprintf('V5 180秒中断LSTM详细结果:\n');
fprintf('========================================\n');

% 非中断期间
idx_0_100 = (time_vec >= 0) & (time_vec < 100);
fprintf('非中断(0-100s): 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north_lstm(idx_0_100).^2)), ...
    sqrt(mean(error_pos_east_lstm(idx_0_100).^2)));

% 100-160秒
idx_100_160 = (time_vec >= 100) & (time_vec <= 160);
fprintf('中断前60s(100-160s): 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north_lstm(idx_100_160).^2)), ...
    sqrt(mean(error_pos_east_lstm(idx_100_160).^2)));

% 160-220秒
idx_160_220 = (time_vec >= 160) & (time_vec <= 220);
fprintf('中断中60s(160-220s): 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north_lstm(idx_160_220).^2)), ...
    sqrt(mean(error_pos_east_lstm(idx_160_220).^2)));

% 220-280秒
idx_220_280 = (time_vec >= 220) & (time_vec <= 280);
fprintf('中断后60s(220-280s): 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north_lstm(idx_220_280).^2)), ...
    sqrt(mean(error_pos_east_lstm(idx_220_280).^2)));

% 280秒后
idx_280_end = (time_vec >= 280);
fprintf('中断后(280-370s): 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north_lstm(idx_280_end).^2)), ...
    sqrt(mean(error_pos_east_lstm(idx_280_end).^2)));

%% 检查参考1的90秒中断结果
fprintf('\n参考1 90秒中断LSTM详细结果:\n');
fprintf('========================================\n');

load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_LSTM_pos.mat');

% 非中断期间
fprintf('非中断(0-100s): 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north_loose_LSTM(idx_0_100).^2)), ...
    sqrt(mean(error_pos_east_loose_LSTM(idx_0_100).^2)));

% 100-160秒
fprintf('中断前60s(100-160s): 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north_loose_LSTM(idx_100_160).^2)), ...
    sqrt(mean(error_pos_east_loose_LSTM(idx_100_160).^2)));

% 160-190秒
idx_160_190 = (time_vec >= 160) & (time_vec <= 190);
fprintf('中断后30s(160-190s): 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north_loose_LSTM(idx_160_190).^2)), ...
    sqrt(mean(error_pos_east_loose_LSTM(idx_160_190).^2)));

% 190秒后
idx_190_end = (time_vec >= 190);
fprintf('中断后(190-370s): 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north_loose_LSTM(idx_190_end).^2)), ...
    sqrt(mean(error_pos_east_loose_LSTM(idx_190_end).^2)));