%% 最终论文结果 - 只对比纯INS、松耦合、LSTM辅助
clc; clear;

fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║           论文实验结果 - 60/120/180秒中断                   ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

%% 加载参考1结果
ref1_pure = load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_pureINS_pos.mat');
ref1_lstm = load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_LSTM_pos.mat');
ref1_pure_vel = load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_pureINS_vel.mat');
ref1_lstm_vel = load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_LSTM_vel.mat');
ref1_pure_att = load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_pureINS_att.mat');
ref1_lstm_att = load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_LSTM_att.mat');

%% 定义时间参数
dt = 0.005;
total_time = 370;
time_vec = (0:dt:(total_time-dt))';
outage_start = 100;

%% 创建结果目录
results_dir = 'G:\lunwen\V5\paper_results';
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

%% 三种中断场景
outage_scenarios = [60, 120, 180];

for idx = 1:length(outage_scenarios)
    duration = outage_scenarios(idx);
    outage_end = outage_start + duration;
    
    fprintf('\n【%d秒中断场景】\n', duration);
    fprintf('═══════════════════════════════════════════════════════════════\n');
    
    % 提取中断期间数据
    outage_idx = (time_vec >= outage_start) & (time_vec <= outage_end);
    time_outage = time_vec(outage_idx) - outage_start;
    
    %% ========== 位置误差 ==========
    % 参考1结果
    ref_loose_north = abs(ref1_pure.error_pos_north_pureINS(outage_idx));
    ref_loose_east = abs(ref1_pure.error_pos_east_pureINS(outage_idx));
    ref_lstm_north = abs(ref1_lstm.error_pos_north_loose_LSTM(outage_idx));
    ref_lstm_east = abs(ref1_lstm.error_pos_east_loose_LSTM(outage_idx));
    
    % 统计
    loose_north_rmse = sqrt(mean(ref_loose_north.^2));
    loose_east_rmse = sqrt(mean(ref_loose_east.^2));
    lstm_north_rmse = sqrt(mean(ref_lstm_north.^2));
    lstm_east_rmse = sqrt(mean(ref_lstm_east.^2));
    
    loose_north_max = max(ref_loose_north);
    loose_east_max = max(ref_loose_east);
    lstm_north_max = max(ref_lstm_north);
    lstm_east_max = max(ref_lstm_east);
    
    % 绘制位置误差图
    figure('Name', sprintf('位置误差-%ds', duration), 'Position', [100 100 900 600]);
    
    subplot(2,1,1);
    plot(time_outage, ref_loose_north, 'b-', 'LineWidth', 2); hold on;
    plot(time_outage, ref_lstm_north, 'r-', 'LineWidth', 2);
    xlabel('时间 (s)', 'FontSize', 12);
    ylabel('北向位置误差 (m)', 'FontSize', 12);
    legend('纯INS/松耦合', 'LSTM辅助', 'FontSize', 11);
    title(sprintf('北向位置误差 (%d秒中断)', duration), 'FontSize', 14);
    grid on; hold off;
    
    subplot(2,1,2);
    plot(time_outage, ref_loose_east, 'b-', 'LineWidth', 2); hold on;
    plot(time_outage, ref_lstm_east, 'r-', 'LineWidth', 2);
    xlabel('时间 (s)', 'FontSize', 12);
    ylabel('东向位置误差 (m)', 'FontSize', 12);
    legend('纯INS/松耦合', 'LSTM辅助', 'FontSize', 11);
    title(sprintf('东向位置误差 (%d秒中断)', duration), 'FontSize', 14);
    grid on; hold off;
    
    saveas(gcf, fullfile(results_dir, sprintf('Fig_Position_%ds.png', duration)));
    
    %% ========== 速度误差 ==========
    ref_loose_vel_n = abs(ref1_pure_vel.error_vel_north_pureINS(outage_idx));
    ref_loose_vel_e = abs(ref1_pure_vel.error_vel_east_pureINS(outage_idx));
    ref_lstm_vel_n = abs(ref1_lstm_vel.error_vel_north_loose_LSTM(outage_idx));
    ref_lstm_vel_e = abs(ref1_lstm_vel.error_vel_east_loose_LSTM(outage_idx));
    
    figure('Name', sprintf('速度误差-%ds', duration), 'Position', [100 100 900 600]);
    
    subplot(2,1,1);
    plot(time_outage, ref_loose_vel_n, 'b-', 'LineWidth', 2); hold on;
    plot(time_outage, ref_lstm_vel_n, 'r-', 'LineWidth', 2);
    xlabel('时间 (s)', 'FontSize', 12);
    ylabel('北向速度误差 (m/s)', 'FontSize', 12);
    legend('纯INS/松耦合', 'LSTM辅助', 'FontSize', 11);
    title(sprintf('北向速度误差 (%d秒中断)', duration), 'FontSize', 14);
    grid on; hold off;
    
    subplot(2,1,2);
    plot(time_outage, ref_loose_vel_e, 'b-', 'LineWidth', 2); hold on;
    plot(time_outage, ref_lstm_vel_e, 'r-', 'LineWidth', 2);
    xlabel('时间 (s)', 'FontSize', 12);
    ylabel('东向速度误差 (m/s)', 'FontSize', 12);
    legend('纯INS/松耦合', 'LSTM辅助', 'FontSize', 11);
    title(sprintf('东向速度误差 (%d秒中断)', duration), 'FontSize', 14);
    grid on; hold off;
    
    saveas(gcf, fullfile(results_dir, sprintf('Fig_Velocity_%ds.png', duration)));
    
    %% ========== 航向误差 ==========
    ref_loose_yaw = abs(ref1_pure_att.error_yaw_pureINS(outage_idx));
    ref_lstm_yaw = abs(ref1_lstm_att.error_yaw_loose_LSTM(outage_idx));
    
    figure('Name', sprintf('航向误差-%ds', duration), 'Position', [100 100 900 400]);
    
    plot(time_outage, ref_loose_yaw, 'b-', 'LineWidth', 2); hold on;
    plot(time_outage, ref_lstm_yaw, 'r-', 'LineWidth', 2);
    xlabel('时间 (s)', 'FontSize', 12);
    ylabel('航向误差 (度)', 'FontSize', 12);
    legend('纯INS/松耦合', 'LSTM辅助', 'FontSize', 11);
    title(sprintf('航向误差 (%d秒中断)', duration), 'FontSize', 14);
    grid on; hold off;
    
    saveas(gcf, fullfile(results_dir, sprintf('Fig_Heading_%ds.png', duration)));
    
    %% ========== 统计表格 ==========
    fprintf('\n【位置误差】\n');
    fprintf('┌────────────────────────────────────────────────────────────┐\n');
    fprintf('│          │   北向RMSE  │   东向RMSE  │   北向最大  │   东向最大  │\n');
    fprintf('├──────────┼─────────────┼─────────────┼─────────────┼─────────────┤\n');
    fprintf('│ 纯INS    │  %6.2f m   │  %6.2f m   │  %6.2f m   │  %6.2f m   │\n', ...
        loose_north_rmse, loose_east_rmse, loose_north_max, loose_east_max);
    fprintf('│ LSTM辅助 │  %6.2f m   │  %6.2f m   │  %6.2f m   │  %6.2f m   │\n', ...
        lstm_north_rmse, lstm_east_rmse, lstm_north_max, lstm_east_max);
    fprintf('└────────────────────────────────────────────────────────────┘\n');
    
    fprintf('\n【性能提升】\n');
    fprintf('  北向: %.1f%%\n', (1-lstm_north_rmse/loose_north_rmse)*100);
    fprintf('  东向: %.1f%%\n', (1-lstm_east_rmse/loose_east_rmse)*100);
end

%% ========== 生成汇总表格 ==========
fprintf('\n\n');
fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║                    实验结果汇总表                           ║\n');
fprintf('╠══════════════════════════════════════════════════════════════╣\n');
fprintf('║  中断时间  │     纯INS RMSE     │    LSTM RMSE     │  性能提升  ║\n');
fprintf('║            │    北向  │  东向   │   北向  │  东向  │   北向/东向 ║\n');
fprintf('╠════════════╪═════════╪═════════╪════════╪════════╪════════════╣\n');

for idx = 1:length(outage_scenarios)
    duration = outage_scenarios(idx);
    outage_end = outage_start + duration;
    outage_idx = (time_vec >= outage_start) & (time_vec <= outage_end);
    
    ref_loose_n = sqrt(mean(abs(ref1_pure.error_pos_north_pureINS(outage_idx)).^2));
    ref_loose_e = sqrt(mean(abs(ref1_pure.error_pos_east_pureINS(outage_idx)).^2));
    ref_lstm_n = sqrt(mean(abs(ref1_lstm.error_pos_north_loose_LSTM(outage_idx)).^2));
    ref_lstm_e = sqrt(mean(abs(ref1_lstm.error_pos_east_loose_LSTM(outage_idx)).^2));
    
    improve_n = (1-ref_lstm_n/ref_loose_n)*100;
    improve_e = (1-ref_lstm_e/ref_loose_e)*100;
    
    fprintf('║   %3ds     │ %6.1f  │ %6.1f  │ %5.1f  │ %5.1f  │ %4.1f%%/%4.1f%% ║\n', ...
        duration, ref_loose_n, ref_loose_e, ref_lstm_n, ref_lstm_e, improve_n, improve_e);
end

fprintf('╚══════════════════════════════════════════════════════════════╝\n');

%% ========== 轨迹对比图 ==========
fprintf('\n【生成轨迹对比图】\n');

% 180秒中断的轨迹
duration = 180;
outage_idx = (time_vec >= outage_start) & (time_vec <= outage_start+duration);

% 加载参考1轨迹
load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_pureINS_pos.mat');
load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_LSTM_pos.mat');

figure('Name', '轨迹对比', 'Position', [100 100 900 700]);

% 全轨迹
subplot(2,1,1);
plot(ref1_pure.error_pos_east_pureINS, ref1_pure.error_pos_north_pureINS, 'b-', 'LineWidth', 1.5); hold on;
plot(ref1_lstm.error_pos_east_loose_LSTM, ref1_lstm.error_pos_north_loose_LSTM, 'r-', 'LineWidth', 1.5);
xlabel('东向 (m)', 'FontSize', 12);
ylabel('北向 (m)', 'FontSize', 12);
legend('纯INS', 'LSTM辅助', 'FontSize', 11);
title('导航轨迹对比', 'FontSize', 14);
grid on; hold off;

% 中断期间轨迹
subplot(2,1,2);
time_outage_idx = time_vec(outage_idx);
plot(time_outage_idx-outage_start, ref1_pure.error_pos_north_pureINS(outage_idx), 'b-', 'LineWidth', 2); hold on;
plot(time_outage_idx-outage_start, ref1_lstm.error_pos_north_loose_LSTM(outage_idx), 'r-', 'LineWidth', 2);
xlabel('时间 (s)', 'FontSize', 12);
ylabel('北向位置误差 (m)', 'FontSize', 12);
legend('纯INS', 'LSTM辅助', 'FontSize', 11);
title(sprintf('180秒中断期间位置误差'), 'FontSize', 14);
grid on; hold off;

saveas(gcf, fullfile(results_dir, 'Fig_Trajectory_Comparison.png'));

fprintf('\n所有图表已保存至: %s\n', results_dir);
fprintf('完成！\n');