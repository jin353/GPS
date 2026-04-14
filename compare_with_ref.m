%% 对比V5和参考1结果
clc; clear;

fprintf('========================================\n');
fprintf('  V5 vs 参考1 结果对比\n');
fprintf('========================================\n\n');

%% 加载参考1的90秒中断结果
load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_pureINS_pos.mat');
load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_LSTM_pos.mat');

%% 加载V5的180秒中断结果
load('G:\lunwen\V5\code\results\lstm_loose_180s.mat');

%% 时间参数
dt = 0.005;
time_vec = (0:dt:369.995)';
outage_start = 100;

%% 检查不同时间段
fprintf('【参考1结果（90秒中断数据）】\n');
fprintf('========================================\n');

% 100-160秒（60秒中断）
idx_60 = (time_vec >= 100) & (time_vec <= 160);
ref_60_n = sqrt(mean(error_pos_north_pureINS(idx_60).^2));
ref_60_e = sqrt(mean(error_pos_east_pureINS(idx_60).^2));
lstm_60_n = sqrt(mean(error_pos_north_loose_LSTM(idx_60).^2));
lstm_60_e = sqrt(mean(error_pos_east_loose_LSTM(idx_60).^2));

fprintf('\n60秒中断(100-160s):\n');
fprintf('  纯INS: 北向 %.2f m, 东向 %.2f m\n', ref_60_n, ref_60_e);
fprintf('  LSTM:  北向 %.2f m, 东向 %.2f m\n', lstm_60_n, lstm_60_e);
fprintf('  提升:   北向 %.1f%%, 东向 %.1f%%\n', (1-lstm_60_n/ref_60_n)*100, (1-lstm_60_e/ref_60_e)*100);

% 100-190秒（90秒中断）
idx_90 = (time_vec >= 100) & (time_vec <= 190);
ref_90_n = sqrt(mean(error_pos_north_pureINS(idx_90).^2));
ref_90_e = sqrt(mean(error_pos_east_pureINS(idx_90).^2));
lstm_90_n = sqrt(mean(error_pos_north_loose_LSTM(idx_90).^2));
lstm_90_e = sqrt(mean(error_pos_east_loose_LSTM(idx_90).^2));

fprintf('\n90秒中断(100-190s):\n');
fprintf('  纯INS: 北向 %.2f m, 东向 %.2f m\n', ref_90_n, ref_90_e);
fprintf('  LSTM:  北向 %.2f m, 东向 %.2f m\n', lstm_90_n, lstm_90_e);
fprintf('  提升:   北向 %.1f%%, 东向 %.1f%%\n', (1-lstm_90_n/ref_90_n)*100, (1-lstm_90_e/ref_90_e)*100);

%% 检查V5的180秒中断结果
fprintf('\n【V5结果（180秒中断数据）】\n');
fprintf('========================================\n');

% 100-160秒（60秒中断）
idx_60 = (time_vec >= 100) & (time_vec <= 160);
v5_60_n = sqrt(mean(error_pos_north_lstm(idx_60).^2));
v5_60_e = sqrt(mean(error_pos_east_lstm(idx_60).^2));

fprintf('\n60秒中断(100-160s):\n');
fprintf('  LSTM:  北向 %.2f m, 东向 %.2f m\n', v5_60_n, v5_60_e);

% 100-220秒（120秒中断）
idx_120 = (time_vec >= 100) & (time_vec <= 220);
v5_120_n = sqrt(mean(error_pos_north_lstm(idx_120).^2));
v5_120_e = sqrt(mean(error_pos_east_lstm(idx_120).^2));

fprintf('\n120秒中断(100-220s):\n');
fprintf('  LSTM:  北向 %.2f m, 东向 %.2f m\n', v5_120_n, v5_120_e);

% 100-280秒（180秒中断）
idx_180 = (time_vec >= 100) & (time_vec <= 280);
v5_180_n = sqrt(mean(error_pos_north_lstm(idx_180).^2));
v5_180_e = sqrt(mean(error_pos_east_lstm(idx_180).^2));

fprintf('\n180秒中断(100-280s):\n');
fprintf('  LSTM:  北向 %.2f m, 东向 %.2f m\n', v5_180_n, v5_180_e);

%% 对比表
fprintf('\n\n【对比表】\n');
fprintf('========================================\n');
fprintf('中断时间 │ 参考1 LSTM │  V5 LSTM   │ 差异\n');
fprintf('─────────┼────────────┼────────────┼────────\n');
fprintf('  60s    │ %5.1f/%5.1f │ %5.1f/%5.1f │ %5.1f%%/%5.1f%%\n', ...
    lstm_60_n, lstm_60_e, v5_60_n, v5_60_e, ...
    abs(v5_60_n-lstm_60_n)/lstm_60_n*100, abs(v5_60_e-lstm_60_e)/lstm_60_e*100);
fprintf('  90s    │ %5.1f/%5.1f │     -      │   -\n', lstm_90_n, lstm_90_e);
fprintf(' 120s    │     -      │ %5.1f/%5.1f │   -\n', v5_120_n, v5_120_e);
fprintf(' 180s    │     -      │ %5.1f/%5.1f │   -\n', v5_180_n, v5_180_e);

fprintf('\n========================================\n');
fprintf('结论：V5的60秒中断LSTM结果与参考1基本一致\n');
fprintf('========================================\n');