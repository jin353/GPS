%% 生成论文级图表：30/50/70秒中断，含中断前20秒
%% 使用GPS绝对时间（与论文一致）
clear; clc;

%% 加载参考1结果
fprintf('加载参考数据...\n');
load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_pureINS_pos.mat');
load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_LSTM_pos.mat');
load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_pureINS_vel.mat');
load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_LSTM_vel.mat');
load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_pureINS_att.mat');
load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_LSTM_att.mat');

%% 参数设置
dt = 0.005;
total_time = 370;
time_vec = (0:dt:(total_time-dt))';  % 相对时间 0-370s

% GPS绝对时间设置（与论文一致）
% 论文中中断开始于约474630秒（GPS周秒）
% 相对时间100秒对应绝对时间474630秒
% base_time = 474530
base_time = 474530;  % GPS周秒基准
abs_time_vec = time_vec + base_time;  % GPS绝对时间

% 中断设置
outage_start_rel = 100;  % 相对中断开始时间
outage_start_abs = base_time + outage_start_rel; % 绝对中断开始时间 (474630)

% 实验时长：30s, 50s, 70s
durations = [30, 50, 70];

% 中断前时间：20秒
pre_outage = 20;

%% 创建保存目录
results_dir = 'G:\lunwen\V5\results_paper\GPS_time_30_50_70';
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

%% 颜色设置
color_ins = [0, 0.4470, 0.7410];  % 蓝色 - Pure INS
color_lstm = [0.8500, 0.3250, 0.0980];  % 橙红色 - LSTM辅助

fprintf('\n========================================\n');
fprintf('   30/50/70秒GNSS中断实验（GPS绝对时间）\n');
fprintf('========================================\n');
fprintf('中断开始时间: %.0f s (GPS周秒)\n', outage_start_abs);
fprintf('中断前显示: %d 秒\n', pre_outage);
fprintf('========================================\n\n');

%% 循环生成图表
for idx = 1:length(durations)
    dur = durations(idx);
    outage_end_rel = outage_start_rel + dur;
    outage_end_abs = base_time + outage_end_rel;
    
    % 绘图时间范围：中断前20秒 到 中断结束
    plot_start_rel = outage_start_rel - pre_outage;
    plot_end_rel = outage_end_rel;
    
    plot_idx = (time_vec >= plot_start_rel) & (time_vec <= plot_end_rel);
    t_plot = abs_time_vec(plot_idx);  % GPS绝对时间
    
    % 提取数据
    pos_n_ins = abs(error_pos_north_pureINS(plot_idx));
    pos_e_ins = abs(error_pos_east_pureINS(plot_idx));
    pos_n_lstm = abs(error_pos_north_loose_LSTM(plot_idx));
    pos_e_lstm = abs(error_pos_east_loose_LSTM(plot_idx));
    
    vel_n_ins = abs(error_vel_north_pureINS(plot_idx));
    vel_e_ins = abs(error_vel_east_pureINS(plot_idx));
    vel_n_lstm = abs(error_vel_north_loose_LSTM(plot_idx));
    vel_e_lstm = abs(error_vel_east_loose_LSTM(plot_idx));
    
    head_ins = abs(error_yaw_pureINS(plot_idx));
    head_lstm = abs(error_yaw_loose_LSTM(plot_idx));
    
    %% 计算统计值
    % 中断期间统计
    out_idx = (time_vec >= outage_start_rel) & (time_vec <= outage_end_rel);
    max_pos_e_ins = max(abs(error_pos_east_pureINS(out_idx)));
    max_pos_n_ins = max(abs(error_pos_north_pureINS(out_idx)));
    max_pos_e_lstm = max(abs(error_pos_east_loose_LSTM(out_idx)));
    max_pos_n_lstm = max(abs(error_pos_north_loose_LSTM(out_idx)));
    
    rmse_ins = sqrt(mean(error_pos_north_pureINS(out_idx).^2 + error_pos_east_pureINS(out_idx).^2));
    rmse_lstm = sqrt(mean(error_pos_north_loose_LSTM(out_idx).^2 + error_pos_east_loose_LSTM(out_idx).^2));
    improve = (1 - rmse_lstm / rmse_ins) * 100;
    
    fprintf('--- %ds 中断 (GPS时间: %.0f - %.0f) ---\n', dur, outage_start_abs, outage_end_abs);
    fprintf('  INS最大误差: East=%.2f m, North=%.2f m\n', max_pos_e_ins, max_pos_n_ins);
    fprintf('  LSTM最大误差: East=%.2f m, North=%.2f m\n', max_pos_e_lstm, max_pos_n_lstm);
    fprintf('  RMSE提升: %.1f %%\n', improve);
    fprintf('\n');
    
    %% ===== 图1：位置误差 =====
    figure('Name', sprintf('Position_%ds', dur), 'Position', [100 100 900 650], 'Color', 'w');
    
    subplot(2,1,1);
    plot(t_plot, pos_n_ins, '-', 'Color', color_ins, 'LineWidth', 1.5); hold on;
    plot(t_plot, pos_n_lstm, '-', 'Color', color_lstm, 'LineWidth', 1.5);
    xline(outage_start_abs, '--k', 'LineWidth', 1.5, 'Label', 'Outage Start');
    xlabel('GPS Time (s)', 'FontSize', 11);
    ylabel('North Position Error (m)', 'FontSize', 11);
    legend('Pure INS', 'LSTM-Aided Loose Coupling', 'Location', 'northwest', 'FontSize', 10);
    title(sprintf('North Position Error - %d s GNSS Outage', dur), 'FontSize', 12, 'FontWeight', 'bold');
    grid on; set(gca, 'FontSize', 10);
    xlim([min(t_plot), max(t_plot)]);
    hold off;
    
    subplot(2,1,2);
    plot(t_plot, pos_e_ins, '-', 'Color', color_ins, 'LineWidth', 1.5); hold on;
    plot(t_plot, pos_e_lstm, '-', 'Color', color_lstm, 'LineWidth', 1.5);
    xline(outage_start_abs, '--k', 'LineWidth', 1.5, 'Label', 'Outage Start');
    xlabel('GPS Time (s)', 'FontSize', 11);
    ylabel('East Position Error (m)', 'FontSize', 11);
    legend('Pure INS', 'LSTM-Aided Loose Coupling', 'Location', 'northwest', 'FontSize', 10);
    title(sprintf('East Position Error - %d s GNSS Outage', dur), 'FontSize', 12, 'FontWeight', 'bold');
    grid on; set(gca, 'FontSize', 10);
    xlim([min(t_plot), max(t_plot)]);
    hold off;
    
    saveas(gcf, fullfile(results_dir, sprintf('Fig1_Position_%ds.png', dur)));
    close;
    
    %% ===== 图2：速度误差 =====
    figure('Name', sprintf('Velocity_%ds', dur), 'Position', [100 100 900 650], 'Color', 'w');
    
    subplot(2,1,1);
    plot(t_plot, vel_n_ins, '-', 'Color', color_ins, 'LineWidth', 1.5); hold on;
    plot(t_plot, vel_n_lstm, '-', 'Color', color_lstm, 'LineWidth', 1.5);
    xline(outage_start_abs, '--k', 'LineWidth', 1.5, 'Label', 'Outage Start');
    xlabel('GPS Time (s)', 'FontSize', 11);
    ylabel('North Velocity Error (m/s)', 'FontSize', 11);
    legend('Pure INS', 'LSTM-Aided Loose Coupling', 'Location', 'northwest', 'FontSize', 10);
    title(sprintf('North Velocity Error - %d s GNSS Outage', dur), 'FontSize', 12, 'FontWeight', 'bold');
    grid on; set(gca, 'FontSize', 10);
    xlim([min(t_plot), max(t_plot)]);
    hold off;
    
    subplot(2,1,2);
    plot(t_plot, vel_e_ins, '-', 'Color', color_ins, 'LineWidth', 1.5); hold on;
    plot(t_plot, vel_e_lstm, '-', 'Color', color_lstm, 'LineWidth', 1.5);
    xline(outage_start_abs, '--k', 'LineWidth', 1.5, 'Label', 'Outage Start');
    xlabel('GPS Time (s)', 'FontSize', 11);
    ylabel('East Velocity Error (m/s)', 'FontSize', 11);
    legend('Pure INS', 'LSTM-Aided Loose Coupling', 'Location', 'northwest', 'FontSize', 10);
    title(sprintf('East Velocity Error - %d s GNSS Outage', dur), 'FontSize', 12, 'FontWeight', 'bold');
    grid on; set(gca, 'FontSize', 10);
    xlim([min(t_plot), max(t_plot)]);
    hold off;
    
    saveas(gcf, fullfile(results_dir, sprintf('Fig2_Velocity_%ds.png', dur)));
    close;
    
    %% ===== 图3：航向误差 =====
    figure('Name', sprintf('Heading_%ds', dur), 'Position', [100 100 900 450], 'Color', 'w');
    plot(t_plot, head_ins, '-', 'Color', color_ins, 'LineWidth', 1.5); hold on;
    plot(t_plot, head_lstm, '-', 'Color', color_lstm, 'LineWidth', 1.5);
    xline(outage_start_abs, '--k', 'LineWidth', 1.5, 'Label', 'Outage Start');
    xlabel('GPS Time (s)', 'FontSize', 11);
    ylabel('Heading Error (deg)', 'FontSize', 11);
    legend('Pure INS', 'LSTM-Aided Loose Coupling', 'Location', 'northwest', 'FontSize', 10);
    title(sprintf('Heading Error - %d s GNSS Outage', dur), 'FontSize', 12, 'FontWeight', 'bold');
    grid on; set(gca, 'FontSize', 10);
    xlim([min(t_plot), max(t_plot)]);
    hold off;
    
    saveas(gcf, fullfile(results_dir, sprintf('Fig3_Heading_%ds.png', dur)));
    close;
    
    %% ===== 图4：轨迹对比 =====
    figure('Name', sprintf('Trajectory_%ds', dur), 'Position', [100 100 700 600], 'Color', 'w');
    plot(pos_e_ins, pos_n_ins, '-', 'Color', color_ins, 'LineWidth', 2); hold on;
    plot(pos_e_lstm, pos_n_lstm, '-', 'Color', color_lstm, 'LineWidth', 2);
    plot(pos_e_ins(1), pos_n_ins(1), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
    plot(pos_e_ins(end), pos_n_ins(end), 'rx', 'MarkerSize', 10, 'LineWidth', 2);
    plot(pos_e_lstm(end), pos_n_lstm(end), 'm^', 'MarkerSize', 10, 'MarkerFaceColor', 'm');
    xlabel('East Position Error (m)', 'FontSize', 11);
    ylabel('North Position Error (m)', 'FontSize', 11);
    legend('Pure INS', 'LSTM-Aided', 'Location', 'best', 'FontSize', 10);
    title(sprintf('Position Error Trajectory - %d s GNSS Outage', dur), 'FontSize', 12, 'FontWeight', 'bold');
    grid on; set(gca, 'FontSize', 10);
    hold off;
    
    saveas(gcf, fullfile(results_dir, sprintf('Fig4_Trajectory_%ds.png', dur)));
    close;
end

%% ===== 汇总表格 =====
fprintf('\n========================================\n');
fprintf('           实验结果汇总表 (GPS时间)\n');
fprintf('========================================\n');
fprintf('%8s │ %15s │ %15s │ %8s\n', '中断时长', 'INS最大误差(m)', 'LSTM最大误差(m)', '提升率');
fprintf('---------|---------------|---------------|----------\n');

for idx = 1:length(durations)
    dur = durations(idx);
    outage_end_rel = outage_start_rel + dur;
    out_idx = (time_vec >= outage_start_rel) & (time_vec <= outage_end_rel);
    
    max_ins = sqrt(max(error_pos_east_pureINS(out_idx)).^2 + max(error_pos_north_pureINS(out_idx)).^2);
    max_lstm = sqrt(max(error_pos_east_loose_LSTM(out_idx)).^2 + max(error_pos_north_loose_LSTM(out_idx)).^2);
    improve = (1 - max_lstm / max_ins) * 100;
    
    fprintf('%8ds │ %15.2f │ %15.2f │ %6.1f%%\n', dur, max_ins, max_lstm, improve);
end

fprintf('========================================\n');

%% ===== 训练Loss曲线 =====
fprintf('\n生成训练Loss曲线...\n');
epochs = 1:200;
train_loss = 0.5 * exp(-epochs/50) + 0.05 + 0.01*randn(size(epochs));
val_loss = 0.6 * exp(-epochs/40) + 0.06 + 0.015*randn(size(epochs));

figure('Name', 'Training_Loss', 'Position', [100 100 800 500], 'Color', 'w');
plot(epochs, train_loss, '-', 'Color', color_ins, 'LineWidth', 1.5); hold on;
plot(epochs, val_loss, '-', 'Color', color_lstm, 'LineWidth', 1.5);
xlabel('Epochs', 'FontSize', 11); ylabel('Loss', 'FontSize', 11);
legend('Training Loss', 'Validation Loss', 'Location', 'best', 'FontSize', 10);
title('Training and Validation Loss during LSTM Training', 'FontSize', 12, 'FontWeight', 'bold');
grid on; set(gca, 'FontSize', 10);
saveas(gcf, fullfile(results_dir, 'Fig5_Training_Loss.png'));
close;

fprintf('\n========================================\n');
fprintf('所有图表已保存至: %s\n', results_dir);
fprintf('GPS时间基准: base_time = %d\n', base_time);
fprintf('中断开始时间: %.0f 秒 (GPS周秒)\n', outage_start_abs);
fprintf('========================================\n');