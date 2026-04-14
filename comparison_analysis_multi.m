%% 导航算法对比分析 - 多时段中断分析
% 功能：对比纯INS、松组合、LSTM辅助松组合在不同中断时段的导航精度
% 输出：20s/40s/60s中断误差对比图（含中断前10s）
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

% 时间向量
dt = 0.005;
total_time = 370;
time_vec = (0:dt:(total_time-dt))';

% 定义三个中断时段：20s, 40s, 60s
outage_durations = [20, 40, 60];
pre_outage_time = 10;  % 中断前显示时间

%% 提取完整误差数据
% 纯INS
err_north_pure_full = abs(error_pos_north);
err_east_pure_full = abs(error_pos_east);
err_vel_north_pure_full = abs(error_vel_north);
err_vel_east_pure_full = abs(error_vel_east);
err_yaw_pure_full = abs(error_yaw);

% 松组合
err_north_loose_full = abs(error_pos_north);
err_east_loose_full = abs(error_pos_east);
err_vel_north_loose_full = abs(error_vel_north);
err_vel_east_loose_full = abs(error_vel_east);
err_yaw_loose_full = abs(error_yaw);

% LSTM辅助
err_north_lstm_full = abs(error_pos_north_lstm);
err_east_lstm_full = abs(error_pos_east_lstm);
err_vel_north_lstm_full = abs(error_vel_north_lstm);
err_vel_east_lstm_full = abs(error_vel_east_lstm);
err_yaw_lstm_full = abs(error_yaw_lstm);

%% 绘制不同中断时段的误差对比图
fprintf('\n生成对比图表...\n');

for idx = 1:length(outage_durations)
    duration = outage_durations(idx);
    outage_end = gnss_outage_start + duration;
    
    % 时间窗口：中断前10s + 中断期间
    window_start = gnss_outage_start - pre_outage_time;
    window_end = outage_end;
    
    % 索引
    window_idx = (time_vec >= window_start) & (time_vec <= window_end);
    time_window = time_vec(window_idx) - gnss_outage_start;  % 相对于中断开始时间
    
    % 提取数据
    err_north_pure = err_north_pure_full(window_idx);
    err_east_pure = err_east_pure_full(window_idx);
    err_north_loose = err_north_loose_full(window_idx);
    err_east_loose = err_east_loose_full(window_idx);
    err_north_lstm = err_north_lstm_full(window_idx);
    err_east_lstm = err_east_lstm_full(window_idx);
    
    err_vel_north_pure = err_vel_north_pure_full(window_idx);
    err_vel_east_pure = err_vel_east_pure_full(window_idx);
    err_vel_north_loose = err_vel_north_loose_full(window_idx);
    err_vel_east_loose = err_vel_east_loose_full(window_idx);
    err_vel_north_lstm = err_vel_north_lstm_full(window_idx);
    err_vel_east_lstm = err_vel_east_lstm_full(window_idx);
    
    err_yaw_pure = err_yaw_pure_full(window_idx);
    err_yaw_loose = err_yaw_loose_full(window_idx);
    err_yaw_lstm = err_yaw_lstm_full(window_idx);
    
    %% 计算统计指标
    fprintf('\n========================================\n');
    fprintf('  GNSS中断 %ds 误差统计\n', duration);
    fprintf('========================================\n\n');
    
    % 中断时段索引
    outage_idx = time_window >= 0;
    
    % 纯INS
    max_north_pure = max(err_north_pure(outage_idx));
    max_east_pure = max(err_east_pure(outage_idx));
    rmse_north_pure = sqrt(mean(err_north_pure(outage_idx).^2));
    rmse_east_pure = sqrt(mean(err_east_pure(outage_idx).^2));
    
    fprintf('纯INS:\n');
    fprintf('  最大误差 - 北向: %.2f m, 东向: %.2f m\n', max_north_pure, max_east_pure);
    fprintf('  RMSE    - 北向: %.2f m, 东向: %.2f m\n', rmse_north_pure, rmse_east_pure);
    
    % 松组合
    max_north_loose = max(err_north_loose(outage_idx));
    max_east_loose = max(err_east_loose(outage_idx));
    rmse_north_loose = sqrt(mean(err_north_loose(outage_idx).^2));
    rmse_east_loose = sqrt(mean(err_east_loose(outage_idx).^2));
    
    fprintf('\n松组合:\n');
    fprintf('  最大误差 - 北向: %.2f m, 东向: %.2f m\n', max_north_loose, max_east_loose);
    fprintf('  RMSE    - 北向: %.2f m, 东向: %.2f m\n', rmse_north_loose, rmse_east_loose);
    
    % LSTM辅助
    max_north_lstm = max(err_north_lstm(outage_idx));
    max_east_lstm = max(err_east_lstm(outage_idx));
    rmse_north_lstm = sqrt(mean(err_north_lstm(outage_idx).^2));
    rmse_east_lstm = sqrt(mean(err_east_lstm(outage_idx).^2));
    
    fprintf('\nLSTM辅助松组合:\n');
    fprintf('  最大误差 - 北向: %.2f m, 东向: %.2f m\n', max_north_lstm, max_east_lstm);
    fprintf('  RMSE    - 北向: %.2f m, 东向: %.2f m\n', rmse_north_lstm, rmse_east_lstm);
    
    %% 绘图
    fprintf('\n生成 %ds 中断对比图...\n', duration);
    
    % 创建大图：位置误差 + 速度误差 + 航向误差
    fig = figure('Name', sprintf('%ds中断误差对比', duration), 'Position', [100 100 1200 800]);
    
    % 位置误差 - 北向
    subplot(3,2,1);
    plot(time_window, err_north_pure, 'g-', 'LineWidth', 1.5); hold on;
    plot(time_window, err_north_loose, 'b-', 'LineWidth', 1.5);
    plot(time_window, err_north_lstm, 'r-', 'LineWidth', 1.5);
    
    % 添加中断开始标记线
    xline(0, 'k--', 'LineWidth', 1.5);
    % 添加中断结束标记线
    xline(duration, 'k--', 'LineWidth', 1.5);
    
    % 添加区域标注
    xlim([-pre_outage_time, duration]);
    ylim([0, max([err_north_pure; err_north_loose; err_north_lstm]) * 1.1]);
    
    % 标注中断前区域
    annotation('textbox', [0.15, 0.85, 0.15, 0.05], ...
        'String', 'GNSS正常', 'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'k');
    
    % 标注中断区域
    annotation('textbox', [0.45, 0.85, 0.2, 0.05], ...
        'String', sprintf('%ds中断', duration), 'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'r', 'FontWeight', 'bold');
    
    xlabel('时间 (s)', 'FontSize', 10);
    ylabel('北向位置误差 (m)', 'FontSize', 10);
    legend('纯INS', '松组合', 'LSTM辅助松组合', 'Location', 'best');
    title(sprintf('北向位置误差对比 (%ds中断)', duration), 'FontSize', 11);
    grid on;
    set(gca, 'FontSize', 9);
    
    % 位置误差 - 东向
    subplot(3,2,2);
    plot(time_window, err_east_pure, 'g-', 'LineWidth', 1.5); hold on;
    plot(time_window, err_east_loose, 'b-', 'LineWidth', 1.5);
    plot(time_window, err_east_lstm, 'r-', 'LineWidth', 1.5);
    
    xline(0, 'k--', 'LineWidth', 1.5);
    xline(duration, 'k--', 'LineWidth', 1.5);
    
    xlim([-pre_outage_time, duration]);
    ylim([0, max([err_east_pure; err_east_loose; err_east_lstm]) * 1.1]);
    
    annotation('textbox', [0.15, 0.85, 0.15, 0.05], ...
        'String', 'GNSS正常', 'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'k');
    
    annotation('textbox', [0.45, 0.85, 0.2, 0.05], ...
        'String', sprintf('%ds中断', duration), 'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'r', 'FontWeight', 'bold');
    
    xlabel('时间 (s)', 'FontSize', 10);
    ylabel('东向位置误差 (m)', 'FontSize', 10);
    legend('纯INS', '松组合', 'LSTM辅助松组合', 'Location', 'best');
    title(sprintf('东向位置误差对比 (%ds中断)', duration), 'FontSize', 11);
    grid on;
    set(gca, 'FontSize', 9);
    
    % 速度误差 - 北向
    subplot(3,2,3);
    plot(time_window, err_vel_north_pure, 'g-', 'LineWidth', 1.5); hold on;
    plot(time_window, err_vel_north_loose, 'b-', 'LineWidth', 1.5);
    plot(time_window, err_vel_north_lstm, 'r-', 'LineWidth', 1.5);
    
    xline(0, 'k--', 'LineWidth', 1.5);
    xline(duration, 'k--', 'LineWidth', 1.5);
    
    xlim([-pre_outage_time, duration]);
    ylim([0, max([err_vel_north_pure; err_vel_north_loose; err_vel_north_lstm]) * 1.1]);
    
    xlabel('时间 (s)', 'FontSize', 10);
    ylabel('北向速度误差 (m/s)', 'FontSize', 10);
    legend('纯INS', '松组合', 'LSTM辅助松组合', 'Location', 'best');
    title(sprintf('北向速度误差对比 (%ds中断)', duration), 'FontSize', 11);
    grid on;
    set(gca, 'FontSize', 9);
    
    % 速度误差 - 东向
    subplot(3,2,4);
    plot(time_window, err_vel_east_pure, 'g-', 'LineWidth', 1.5); hold on;
    plot(time_window, err_vel_east_loose, 'b-', 'LineWidth', 1.5);
    plot(time_window, err_vel_east_lstm, 'r-', 'LineWidth', 1.5);
    
    xline(0, 'k--', 'LineWidth', 1.5);
    xline(duration, 'k--', 'LineWidth', 1.5);
    
    xlim([-pre_outage_time, duration]);
    ylim([0, max([err_vel_east_pure; err_vel_east_loose; err_vel_east_lstm]) * 1.1]);
    
    xlabel('时间 (s)', 'FontSize', 10);
    ylabel('东向速度误差 (m/s)', 'FontSize', 10);
    legend('纯INS', '松组合', 'LSTM辅助松组合', 'Location', 'best');
    title(sprintf('东向速度误差对比 (%ds中断)', duration), 'FontSize', 11);
    grid on;
    set(gca, 'FontSize', 9);
    
    % 航向误差
    subplot(3,2,[5,6]);
    plot(time_window, err_yaw_pure, 'g-', 'LineWidth', 1.5); hold on;
    plot(time_window, err_yaw_loose, 'b-', 'LineWidth', 1.5);
    plot(time_window, err_yaw_lstm, 'r-', 'LineWidth', 1.5);
    
    xline(0, 'k--', 'LineWidth', 1.5);
    xline(duration, 'k--', 'LineWidth', 1.5);
    
    xlim([-pre_outage_time, duration]);
    ylim([0, max([err_yaw_pure; err_yaw_loose; err_yaw_lstm]) * 1.1]);
    
    xlabel('时间 (s)', 'FontSize', 10);
    ylabel('航向误差 (°)', 'FontSize', 10);
    legend('纯INS', '松组合', 'LSTM辅助松组合', 'Location', 'best');
    title(sprintf('航向误差对比 (%ds中断)', duration), 'FontSize', 11);
    grid on;
    set(gca, 'FontSize', 9);
    
    % 保存图表
    saveas(fig, sprintf('results/position_velocity_heading_comparison_%ds.png', duration));
    fprintf('图表已保存至 results/position_velocity_heading_comparison_%ds.png\n', duration);
end

%% 保存对比结果
fprintf('\n========================================\n');
fprintf('  对比分析完成！\n');
fprintf('========================================\n');
fprintf('图表已保存至 results/ 文件夹\n');
