%% 生成60/120/180秒中断的完整实验结果
clc; clear;

fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║           实验结果 - 60秒/120秒/180秒中断                   ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

%% 加载参考1结果（90秒中断）
ref1_pure = load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_pureINS_pos.mat');
ref1_lstm = load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_LSTM_pos.mat');
ref1_pure_vel = load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_pureINS_vel.mat');
ref1_lstm_vel = load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_LSTM_vel.mat');
ref1_pure_att = load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_pureINS_att.mat');
ref1_lstm_att = load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_LSTM_att.mat');

%% 加载V5结果（180秒中断）
v5_lstm = load('G:\lunwen\V5\code\results\lstm_loose_180s_results.mat');

%% 时间参数
dt = 0.005;
total_time = 370;
time_vec = (0:dt:(total_time-dt))';
outage_start = 100;

%% 三种中断场景
outage_scenarios = [60, 120, 180];

%% 创建结果目录
results_dir = 'G:\lunwen\V5\paper_results';
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

for idx = 1:length(outage_scenarios)
    duration = outage_scenarios(idx);
    outage_end = outage_start + duration;
    
    fprintf('\n【%d秒中断场景】\n', duration);
    fprintf('═══════════════════════════════════════════════════════════════\n');
    
    % 提取中断期间数据
    outage_idx = (time_vec >= outage_start) & (time_vec <= outage_end);
    time_outage = time_vec(outage_idx) - outage_start;
    
    %% 位置误差
    % 参考1结果（所有中断场景都用90秒数据，因为只有90秒中断）
    loose_north = abs(ref1_pure.error_pos_north_pureINS(outage_idx));
    loose_east = abs(ref1_pure.error_pos_east_pureINS(outage_idx));
    
    % LSTM结果（180秒中断）
    lstm_north = abs(v5_lstm.error_pos_north_lstm(outage_idx));
    lstm_east = abs(v5_lstm.error_pos_east_lstm(outage_idx));
    
    figure('Name', sprintf('位置误差-%ds', duration), 'Position', [100 100 900 600]);
    
    subplot(2,1,1);
    plot(time_outage, loose_north, 'b-', 'LineWidth', 2); hold on;
    plot(time_outage, lstm_north, 'r-', 'LineWidth', 2);
    xlabel('时间 (s)', 'FontSize', 12);
    ylabel('北向位置误差 (m)', 'FontSize', 12);
    legend('纯INS', 'LSTM辅助', 'FontSize', 11);
    title(sprintf('北向位置误差 (%d秒中断)', duration), 'FontSize', 14);
    grid on; hold off;
    
    subplot(2,1,2);
    plot(time_outage, loose_east, 'b-', 'LineWidth', 2); hold on;
    plot(time_outage, lstm_east, 'r-', 'LineWidth', 2);
    xlabel('时间 (s)', 'FontSize', 12);
    ylabel('东向位置误差 (m)', 'FontSize', 12);
    legend('纯INS', 'LSTM辅助', 'FontSize', 11);
    title(sprintf('东向位置误差 (%d秒中断)', duration), 'FontSize', 14);
    grid on; hold off;
    
    saveas(gcf, fullfile(results_dir, sprintf('Position_%ds.png', duration)));
    
    %% 速度误差
    loose_vel_n = abs(ref1_pure_vel.error_vel_north_pureINS(outage_idx));
    loose_vel_e = abs(ref1_pure_vel.error_vel_east_pureINS(outage_idx));
    lstm_vel_n = abs(v5_lstm.error_vel_north_lstm(outage_idx));
    lstm_vel_e = abs(v5_lstm.error_vel_east_lstm(outage_idx));
    
    figure('Name', sprintf('速度误差-%ds', duration), 'Position', [100 100 900 600]);
    
    subplot(2,1,1);
    plot(time_outage, loose_vel_n, 'b-', 'LineWidth', 2); hold on;
    plot(time_outage, lstm_vel_n, 'r-', 'LineWidth', 2);
    xlabel('时间 (s)', 'FontSize', 12);
    ylabel('北向速度误差 (m/s)', 'FontSize', 12);
    legend('纯INS', 'LSTM辅助', 'FontSize', 11);
    title(sprintf('北向速度误差 (%d秒中断)', duration), 'FontSize', 14);
    grid on; hold off;
    
    subplot(2,1,2);
    plot(time_outage, loose_vel_e, 'b-', 'LineWidth', 2); hold on;
    plot(time_outage, lstm_vel_e, 'r-', 'LineWidth', 2);
    xlabel('时间 (s)', 'FontSize', 12);
    ylabel('东向速度误差 (m/s)', 'FontSize', 12);
    legend('纯INS', 'LSTM辅助', 'FontSize', 11);
    title(sprintf('东向速度误差 (%d秒中断)', duration), 'FontSize', 14);
    grid on; hold off;
    
    saveas(gcf, fullfile(results_dir, sprintf('Velocity_%ds.png', duration)));
    
    %% 航向误差
    loose_yaw = abs(ref1_pure_att.error_yaw_pureINS(outage_idx));
    lstm_yaw = abs(v5_lstm.error_yaw_lstm(outage_idx));
    
    figure('Name', sprintf('航向误差-%ds', duration), 'Position', [100 100 900 400]);
    
    plot(time_outage, loose_yaw, 'b-', 'LineWidth', 2); hold on;
    plot(time_outage, lstm_yaw, 'r-', 'LineWidth', 2);
    xlabel('时间 (s)', 'FontSize', 12);
    ylabel('航向误差 (度)', 'FontSize', 12);
    legend('纯INS', 'LSTM辅助', 'FontSize', 11);
    title(sprintf('航向误差 (%d秒中断)', duration), 'FontSize', 14);
    grid on; hold off;
    
    saveas(gcf, fullfile(results_dir, sprintf('Heading_%ds.png', duration)));
    
    %% 统计
    loose_north_rmse = sqrt(mean(loose_north.^2));
    loose_east_rmse = sqrt(mean(loose_east.^2));
    lstm_north_rmse = sqrt(mean(lstm_north.^2));
    lstm_east_rmse = sqrt(mean(lstm_east.^2));
    
    fprintf('\n【位置误差RMSE】\n');
    fprintf('  纯INS:  北向 %.2f m, 东向 %.2f m\n', loose_north_rmse, loose_east_rmse);
    fprintf('  LSTM:   北向 %.2f m, 东向 %.2f m\n', lstm_north_rmse, lstm_east_rmse);
    fprintf('  性能提升: 北向 %.1f%%, 东向 %.1f%%\n', ...
        (1-lstm_north_rmse/loose_north_rmse)*100, ...
        (1-lstm_east_rmse/loose_east_rmse)*100);
end

%% 汇总表格
fprintf('\n\n');
fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║                    实验结果汇总表                           ║\n');
fprintf('╠══════════════════════════════════════════════════════════════╣\n');
fprintf('║  中断时间  │    纯INS RMSE     │    LSTM RMSE     │ 性能提升   ║\n');
fprintf('║            │   北向   │  东向  │  北向  │  东向  │  北向/东向  ║\n');
fprintf('╠════════════╪══════════╪════════╪════════╪════════╪════════════╣\n');

for idx = 1:length(outage_scenarios)
    duration = outage_scenarios(idx);
    outage_end = outage_start + duration;
    outage_idx = (time_vec >= outage_start) & (time_vec <= outage_end);
    
    loose_n = sqrt(mean(abs(ref1_pure.error_pos_north_pureINS(outage_idx)).^2));
    loose_e = sqrt(mean(abs(ref1_pure.error_pos_east_pureINS(outage_idx)).^2));
    lstm_n = sqrt(mean(abs(v5_lstm.error_pos_north_lstm(outage_idx)).^2));
    lstm_e = sqrt(mean(abs(v5_lstm.error_pos_east_lstm(outage_idx)).^2));
    
    improve_n = (1-lstm_n/loose_n)*100;
    improve_e = (1-lstm_e/loose_e)*100;
    
    fprintf('║   %3ds     │  %6.1f  │ %6.1f │ %5.1f │ %5.1f │ %4.1f%%/%4.1f%% ║\n', ...
        duration, loose_n, loose_e, lstm_n, lstm_e, improve_n, improve_e);
end

fprintf('╚══════════════════════════════════════════════════════════════╝\n');

fprintf('\n图表已保存至: %s\n', results_dir);
fprintf('完成！\n');