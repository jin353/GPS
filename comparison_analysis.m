%% 导航算法对比分析
% 功能：对比纯INS、松组合、LSTM辅助松组合的导航精度
% 输出：位置/速度/航向误差对比图
% 日期：2026-03-27

clear; clc; close all;

%% 加载实验结果
fprintf('加载实验数据...\n');

load('results/pure_ins_results.mat');       % 纯INS结果
load('results/loose_coupling_results.mat'); % 松组合结果
load('results/lstm_loose_results.mat');     % LSTM辅助结果

%% 参数配置
gnss_outage_start = 100;  % GNSS中断开始时间 (s)
gnss_outage_end = 190;    % GNSS中断结束时间 (s)
outage_duration = gnss_outage_end - gnss_outage_start;

% 时间向量
dt = 0.005;
total_time = 370;
time_vec = (0:dt:(total_time-dt))';

% 提取GNSS中断时段索引
outage_idx = (time_vec >= gnss_outage_start) & (time_vec <= gnss_outage_end);
time_outage = time_vec(outage_idx) - gnss_outage_start;

%% 提取误差数据
% 纯INS
err_north_pure = abs(error_pos_north(outage_idx));
err_east_pure = abs(error_pos_east(outage_idx));

% 松组合
err_north_loose = abs(error_pos_north(outage_idx));
err_east_loose = abs(error_pos_east(outage_idx));

% LSTM辅助
err_north_lstm = abs(error_pos_north_lstm(outage_idx));
err_east_lstm = abs(error_pos_east_lstm(outage_idx));

%% 计算最大误差和RMSE
fprintf('\n========================================\n');
fprintf('  GNSS中断 %ds 误差统计\n', outage_duration);
fprintf('========================================\n\n');

% 纯INS
max_north_pure = max(err_north_pure);
max_east_pure = max(err_east_pure);
rmse_north_pure = sqrt(mean(err_north_pure.^2));
rmse_east_pure = sqrt(mean(err_east_pure.^2));

fprintf('纯INS:\n');
fprintf('  最大误差 - 北向: %.2f m, 东向: %.2f m\n', max_north_pure, max_east_pure);
fprintf('  RMSE    - 北向: %.2f m, 东向: %.2f m\n', rmse_north_pure, rmse_east_pure);

% 松组合
max_north_loose = max(err_north_loose);
max_east_loose = max(err_east_loose);
rmse_north_loose = sqrt(mean(err_north_loose.^2));
rmse_east_loose = sqrt(mean(err_east_loose.^2));

fprintf('\n松组合:\n');
fprintf('  最大误差 - 北向: %.2f m, 东向: %.2f m\n', max_north_loose, max_east_loose);
fprintf('  RMSE    - 北向: %.2f m, 东向: %.2f m\n', rmse_north_loose, rmse_east_loose);

% LSTM辅助
max_north_lstm = max(err_north_lstm);
max_east_lstm = max(err_east_lstm);
rmse_north_lstm = sqrt(mean(err_north_lstm.^2));
rmse_east_lstm = sqrt(mean(err_east_lstm.^2));

fprintf('\nLSTM辅助松组合:\n');
fprintf('  最大误差 - 北向: %.2f m, 东向: %.2f m\n', max_north_lstm, max_east_lstm);
fprintf('  RMSE    - 北向: %.2f m, 东向: %.2f m\n', rmse_north_lstm, rmse_east_lstm);

%% 计算性能提升
fprintf('\n========================================\n');
fprintf('  性能提升分析\n');
fprintf('========================================\n\n');

% LSTM vs 纯INS
improve_north_pure = (1 - rmse_north_lstm/rmse_north_pure) * 100;
improve_east_pure = (1 - rmse_east_lstm/rmse_east_pure) * 100;
fprintf('LSTM辅助 vs 纯INS:\n');
fprintf('  北向精度提升: %.1f%%\n', improve_north_pure);
fprintf('  东向精度提升: %.1f%%\n', improve_east_pure);

% LSTM vs 松组合
improve_north_loose = (1 - rmse_north_lstm/rmse_north_loose) * 100;
improve_east_loose = (1 - rmse_east_lstm/rmse_east_loose) * 100;
fprintf('\nLSTM辅助 vs 松组合:\n');
fprintf('  北向精度提升: %.1f%%\n', improve_north_loose);
fprintf('  东向精度提升: %.1f%%\n', improve_east_loose);

%% 绘制对比图
fprintf('\n生成对比图表...\n');

% 位置误差对比图
figure('Name', '位置误差对比', 'Position', [100 100 800 600]);

subplot(2,1,1);
plot(time_outage, err_north_pure, 'g-', 'LineWidth', 1.5); hold on;
plot(time_outage, err_north_loose, 'b-', 'LineWidth', 1.5);
plot(time_outage, err_north_lstm, 'r-', 'LineWidth', 1.5);
xlabel('时间 (s)');
ylabel('北向位置误差 (m)');
legend('纯INS', '松组合', 'LSTM辅助松组合');
title('北向位置误差对比');
grid on;

subplot(2,1,2);
plot(time_outage, err_east_pure, 'g-', 'LineWidth', 1.5); hold on;
plot(time_outage, err_east_loose, 'b-', 'LineWidth', 1.5);
plot(time_outage, err_east_lstm, 'r-', 'LineWidth', 1.5);
xlabel('时间 (s)');
ylabel('东向位置误差 (m)');
legend('纯INS', '松组合', 'LSTM辅助松组合');
title('东向位置误差对比');
grid on;

% 保存位置误差图
saveas(gcf, 'results/position_error_comparison.png');

% 速度误差对比图
figure('Name', '速度误差对比', 'Position', [100 100 800 600]);

subplot(2,1,1);
plot(time_outage, abs(error_vel_north(outage_idx)), 'g-', 'LineWidth', 1.5); hold on;
plot(time_outage, abs(error_vel_north(outage_idx)), 'b-', 'LineWidth', 1.5);
plot(time_outage, abs(error_vel_north_lstm(outage_idx)), 'r-', 'LineWidth', 1.5);
xlabel('时间 (s)');
ylabel('北向速度误差 (m/s)');
legend('纯INS', '松组合', 'LSTM辅助松组合');
title('北向速度误差对比');
grid on;

subplot(2,1,2);
plot(time_outage, abs(error_vel_east(outage_idx)), 'g-', 'LineWidth', 1.5); hold on;
plot(time_outage, abs(error_vel_east(outage_idx)), 'b-', 'LineWidth', 1.5);
plot(time_outage, abs(error_vel_east_lstm(outage_idx)), 'r-', 'LineWidth', 1.5);
xlabel('时间 (s)');
ylabel('东向速度误差 (m/s)');
legend('纯INS', '松组合', 'LSTM辅助松组合');
title('东向速度误差对比');
grid on;

% 保存速度误差图
saveas(gcf, 'results/velocity_error_comparison.png');

% 航向误差对比图
figure('Name', '航向误差对比', 'Position', [100 100 800 400]);

plot(time_outage, abs(error_yaw(outage_idx)), 'g-', 'LineWidth', 1.5); hold on;
plot(time_outage, abs(error_yaw(outage_idx)), 'b-', 'LineWidth', 1.5);
plot(time_outage, abs(error_yaw_lstm(outage_idx)), 'r-', 'LineWidth', 1.5);
xlabel('时间 (s)');
ylabel('航向误差 (°)');
legend('纯INS', '松组合', 'LSTM辅助松组合');
title('航向误差对比');
grid on;

% 保存航向误差图
saveas(gcf, 'results/heading_error_comparison.png');

%% 保存对比结果
comparison_results.duration = outage_duration;
comparison_results.pure_ins.max_north = max_north_pure;
comparison_results.pure_ins.max_east = max_east_pure;
comparison_results.pure_ins.rmse_north = rmse_north_pure;
comparison_results.pure_ins.rmse_east = rmse_east_pure;
comparison_results.loose.max_north = max_north_loose;
comparison_results.loose.max_east = max_east_loose;
comparison_results.loose.rmse_north = rmse_north_loose;
comparison_results.loose.rmse_east = rmse_east_loose;
comparison_results.lstm.max_north = max_north_lstm;
comparison_results.lstm.max_east = max_east_lstm;
comparison_results.lstm.rmse_north = rmse_north_lstm;
comparison_results.lstm.rmse_east = rmse_east_lstm;

save('results/comparison_results.mat', 'comparison_results');

fprintf('\n========================================\n');
fprintf('  对比分析完成！\n');
fprintf('========================================\n');
fprintf('图表已保存至 results/ 文件夹\n');
fprintf('结果数据已保存至 comparison_results.mat\n');