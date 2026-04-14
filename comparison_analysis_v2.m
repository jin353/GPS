%% 导航算法对比分析（多中断时长版本）
% 功能：对比纯INS、松组合、LSTM辅助松组合在不同GNSS中断时长下的导航精度
% 输出：位置/速度/航向误差对比图（含中断前10秒）
% 日期：2026-04-07

clear; clc; close all;

%% 加载实验结果
fprintf('加载实验数据...\n');

load('results/pure_ins_results.mat');       % 纯INS结果
load('results/loose_coupling_results.mat'); % 松组合结果
load('results/lstm_loose_results.mat');     % LSTM辅助结果

%% 参数配置
dt = 0.005;
total_time = 370;
time_vec = (0:dt:(total_time-dt))';

% 定义3种中断场景
scenarios = struct();
scenarios(1).name = '20s中断';
scenarios(1).outage_start = 100;  % 中断开始时间
scenarios(1).outage_end = 120;    % 中断结束时间
scenarios(1).pre_duration = 10;   % 中断前显示时长

scenarios(2).name = '40s中断';
scenarios(2).outage_start = 100;
scenarios(2).outage_end = 140;
scenarios(2).pre_duration = 10;

scenarios(3).name = '60s中断';
scenarios(3).outage_start = 100;
scenarios(3).outage_end = 160;
scenarios(3).pre_duration = 10;

%% 为每种场景生成对比图
for s = 1:length(scenarios)
    scenario = scenarios(s);
    fprintf('\n========================================\n');
    fprintf('  生成 %s 对比图\n', scenario.name);
    fprintf('========================================\n');
    
    % 计算显示时间范围
    display_start = scenario.outage_start - scenario.pre_duration;
    display_end = scenario.outage_end;
    
    % 提取时间索引
    display_idx = (time_vec >= display_start) & (time_vec <= display_end);
    outage_idx = (time_vec >= scenario.outage_start) & (time_vec <= scenario.outage_end);
    
    % 显示时间向量（真实时间）
    time_display = time_vec(display_idx);
    time_outage = time_vec(outage_idx);
    
    %% 提取误差数据
    % 纯INS
    err_north_pure = abs(error_pos_north(display_idx));
    err_east_pure = abs(error_pos_east(display_idx));
    
    % 松组合
    err_north_loose = abs(error_pos_north(display_idx));
    err_east_loose = abs(error_pos_east(display_idx));
    
    % LSTM辅助
    err_north_lstm = abs(error_pos_north_lstm(display_idx));
    err_east_lstm = abs(error_pos_east_lstm(display_idx));
    
    %% 计算统计指标
    fprintf('\n%s 误差统计:\n', scenario.name);
    fprintf('  纯INS - 北向最大: %.2f m, 东向最大: %.2f m\n', ...
        max(err_north_pure), max(err_east_pure));
    fprintf('  LSTM  - 北向最大: %.2f m, 东向最大: %.2f m\n', ...
        max(err_north_lstm), max(err_east_lstm));
    
    %% 绘制位置误差对比图
    fig1 = figure('Name', [scenario.name ' - 位置误差对比'], 'Position', [100 100 900 700]);
    
    % 北向位置误差
    subplot(2,1,1);
    plot(time_display, err_north_pure, 'g-', 'LineWidth', 1.5); hold on;
    plot(time_display, err_north_loose, 'b-', 'LineWidth', 1.5);
    plot(time_display, err_north_lstm, 'r-', 'LineWidth', 1.5);
    
    % 标注中断区域
    y_limits = ylim;
    patch([scenario.outage_start scenario.outage_end scenario.outage_end scenario.outage_start], ...
          [y_limits(1) y_limits(1) y_limits(2) y_limits(2)], ...
          [0.9 0.9 0.9], 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    xline(scenario.outage_start, 'k--', 'LineWidth', 1.5);
    xline(scenario.outage_end, 'k--', 'LineWidth', 1.5);
    
    % 添加标注
    text(scenario.outage_start + 1, y_limits(2)*0.9, 'GNSS中断', ...
         'FontSize', 10, 'FontWeight', 'bold', 'Color', 'red');
    
    xlabel('时间 (s)', 'FontSize', 12);
    ylabel('北向位置误差 (m)', 'FontSize', 12);
    legend('纯INS', '松组合', 'LSTM辅助', 'Location', 'northwest');
    title([scenario.name ' - 北向位置误差'], 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    % 东向位置误差
    subplot(2,1,2);
    plot(time_display, err_east_pure, 'g-', 'LineWidth', 1.5); hold on;
    plot(time_display, err_east_loose, 'b-', 'LineWidth', 1.5);
    plot(time_display, err_east_lstm, 'r-', 'LineWidth', 1.5);
    
    % 标注中断区域
    y_limits = ylim;
    patch([scenario.outage_start scenario.outage_end scenario.outage_end scenario.outage_start], ...
          [y_limits(1) y_limits(1) y_limits(2) y_limits(2)], ...
          [0.9 0.9 0.9], 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    xline(scenario.outage_start, 'k--', 'LineWidth', 1.5);
    xline(scenario.outage_end, 'k--', 'LineWidth', 1.5);
    
    text(scenario.outage_start + 1, y_limits(2)*0.9, 'GNSS中断', ...
         'FontSize', 10, 'FontWeight', 'bold', 'Color', 'red');
    
    xlabel('时间 (s)', 'FontSize', 12);
    ylabel('东向位置误差 (m)', 'FontSize', 12);
    legend('纯INS', '松组合', 'LSTM辅助', 'Location', 'northwest');
    title([scenario.name ' - 东向位置误差'], 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    % 保存图片
    saveas(fig1, ['results/position_error_' num2str(scenario.outage_end - scenario.outage_start) 's.png']);
    
    %% 绘制速度误差对比图
    fig2 = figure('Name', [scenario.name ' - 速度误差对比'], 'Position', [100 100 900 700]);
    
    % 北向速度误差
    subplot(2,1,1);
    plot(time_display, abs(error_vel_north(display_idx)), 'g-', 'LineWidth', 1.5); hold on;
    plot(time_display, abs(error_vel_north(display_idx)), 'b-', 'LineWidth', 1.5);
    plot(time_display, abs(error_vel_north_lstm(display_idx)), 'r-', 'LineWidth', 1.5);
    
    y_limits = ylim;
    patch([scenario.outage_start scenario.outage_end scenario.outage_end scenario.outage_start], ...
          [y_limits(1) y_limits(1) y_limits(2) y_limits(2)], ...
          [0.9 0.9 0.9], 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    xline(scenario.outage_start, 'k--', 'LineWidth', 1.5);
    xline(scenario.outage_end, 'k--', 'LineWidth', 1.5);
    
    text(scenario.outage_start + 1, y_limits(2)*0.9, 'GNSS中断', ...
         'FontSize', 10, 'FontWeight', 'bold', 'Color', 'red');
    
    xlabel('时间 (s)', 'FontSize', 12);
    ylabel('北向速度误差 (m/s)', 'FontSize', 12);
    legend('纯INS', '松组合', 'LSTM辅助', 'Location', 'northwest');
    title([scenario.name ' - 北向速度误差'], 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    % 东向速度误差
    subplot(2,1,2);
    plot(time_display, abs(error_vel_east(display_idx)), 'g-', 'LineWidth', 1.5); hold on;
    plot(time_display, abs(error_vel_east(display_idx)), 'b-', 'LineWidth', 1.5);
    plot(time_display, abs(error_vel_east_lstm(display_idx)), 'r-', 'LineWidth', 1.5);
    
    y_limits = ylim;
    patch([scenario.outage_start scenario.outage_end scenario.outage_end scenario.outage_start], ...
          [y_limits(1) y_limits(1) y_limits(2) y_limits(2)], ...
          [0.9 0.9 0.9], 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    xline(scenario.outage_start, 'k--', 'LineWidth', 1.5);
    xline(scenario.outage_end, 'k--', 'LineWidth', 1.5);
    
    text(scenario.outage_start + 1, y_limits(2)*0.9, 'GNSS中断', ...
         'FontSize', 10, 'FontWeight', 'bold', 'Color', 'red');
    
    xlabel('时间 (s)', 'FontSize', 12);
    ylabel('东向速度误差 (m/s)', 'FontSize', 12);
    legend('纯INS', '松组合', 'LSTM辅助', 'Location', 'northwest');
    title([scenario.name ' - 东向速度误差'], 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    saveas(fig2, ['results/velocity_error_' num2str(scenario.outage_end - scenario.outage_start) 's.png']);
    
    %% 绘制航向误差对比图
    fig3 = figure('Name', [scenario.name ' - 航向误差对比'], 'Position', [100 100 800 500]);
    
    plot(time_display, abs(error_yaw(display_idx)), 'g-', 'LineWidth', 1.5); hold on;
    plot(time_display, abs(error_yaw(display_idx)), 'b-', 'LineWidth', 1.5);
    plot(time_display, abs(error_yaw_lstm(display_idx)), 'r-', 'LineWidth', 1.5);
    
    y_limits = ylim;
    patch([scenario.outage_start scenario.outage_end scenario.outage_end scenario.outage_start], ...
          [y_limits(1) y_limits(1) y_limits(2) y_limits(2)], ...
          [0.9 0.9 0.9], 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    xline(scenario.outage_start, 'k--', 'LineWidth', 1.5);
    xline(scenario.outage_end, 'k--', 'LineWidth', 1.5);
    
    text(scenario.outage_start + 1, y_limits(2)*0.9, 'GNSS中断', ...
         'FontSize', 10, 'FontWeight', 'bold', 'Color', 'red');
    
    xlabel('时间 (s)', 'FontSize', 12);
    ylabel('航向误差 (°)', 'FontSize', 12);
    legend('纯INS', '松组合', 'LSTM辅助', 'Location', 'northwest');
    title([scenario.name ' - 航向误差'], 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    saveas(fig3, ['results/heading_error_' num2str(scenario.outage_end - scenario.outage_start) 's.png']);
    
end

%% 生成汇总对比图（3种中断时长放在一起）
fprintf('\n生成汇总对比图...\n');

figure('Name', '汇总对比 - 北向位置误差', 'Position', [100 100 1000 600]);

% 20s中断
idx20 = (time_vec >= 90) & (time_vec <= 120);
plot(time_vec(idx20), abs(error_pos_north(idx20)), 'g-', 'LineWidth', 1.5); hold on;
plot(time_vec(idx20), abs(error_pos_north_lstm(idx20)), 'r-', 'LineWidth', 1.5);
xline(100, 'k--', 'LineWidth', 1.5);
text(101, max(abs(error_pos_north(idx20)))*0.9, '20s中断开始', 'FontSize', 10, 'Color', 'red');

% 40s中断
idx40 = (time_vec >= 90) & (time_vec <= 140);
plot(time_vec(idx40), abs(error_pos_north(idx40)), 'g--', 'LineWidth', 1.5);
plot(time_vec(idx40), abs(error_pos_north_lstm(idx40)), 'r--', 'LineWidth', 1.5);
xline(140, 'k--', 'LineWidth', 1.5);
text(141, max(abs(error_pos_north(idx40)))*0.8, '40s中断结束', 'FontSize', 10, 'Color', 'red');

% 60s中断
idx60 = (time_vec >= 90) & (time_vec <= 160);
plot(time_vec(idx60), abs(error_pos_north(idx60)), 'g:', 'LineWidth', 1.5);
plot(time_vec(idx60), abs(error_pos_north_lstm(idx60)), 'r:', 'LineWidth', 1.5);
xline(160, 'k--', 'LineWidth', 1.5);
text(161, max(abs(error_pos_north(idx60)))*0.7, '60s中断结束', 'FontSize', 10, 'Color', 'red');

xlabel('时间 (s)', 'FontSize', 12);
ylabel('北向位置误差 (m)', 'FontSize', 12);
legend('纯INS-20s', 'LSTM-20s', '纯INS-40s', 'LSTM-40s', '纯INS-60s', 'LSTM-60s', 'Location', 'northwest');
title('不同GNSS中断时长下北向位置误差对比', 'FontSize', 14, 'FontWeight', 'bold');
grid on;

saveas(gcf, 'results/summary_position_error.png');

fprintf('\n========================================\n');
fprintf('  所有对比图生成完成！\n');
fprintf('========================================\n');
fprintf('图表已保存至 results/ 文件夹\n');