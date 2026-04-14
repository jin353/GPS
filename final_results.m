%% 生成60/120/180秒中断的完整实验结果
clc; clear;

fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║           实验结果 - 60秒/120秒/180秒中断                   ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

%% 加载参考1结果（90秒中断，用于松耦合）
load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_pureINS_pos.mat');
load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_pureINS_vel.mat');
load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_pureINS_att.mat');
loose_pos_north = error_pos_north_pureINS;
loose_pos_east = error_pos_east_pureINS;
loose_vel_north = error_vel_north_pureINS;
loose_vel_east = error_vel_east_pureINS;
loose_yaw = error_yaw_pureINS;

%% 加载LSTM结果
load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_LSTM_pos.mat');
load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_LSTM_vel.mat');
load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_LSTM_att.mat');
lstm_90_pos_north = error_pos_north_loose_LSTM;
lstm_90_pos_east = error_pos_east_loose_LSTM;

load('G:\lunwen\V5\code\results\lstm_loose_180s.mat');
lstm_180_pos_north = error_pos_north_lstm;
lstm_180_pos_east = error_pos_east_lstm;

%% 时间参数
dt = 0.005;
time_vec = (0:dt:369.995)';
outage_start = 100;

%% 中断场景
outage_scenarios = [60, 120, 180];

%% 创建结果目录
results_dir = 'G:\lunwen\V5\paper_results';
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

%% 生成结果
for idx = 1:length(outage_scenarios)
    duration = outage_scenarios(idx);
    outage_end = outage_start + duration;
    
    fprintf('\n【%d秒中断场景】\n', duration);
    fprintf('═══════════════════════════════════════════════════════════════\n');
    
    outage_idx = (time_vec >= outage_start) & (time_vec <= outage_end);
    time_outage = time_vec(outage_idx) - outage_start;
    
    % 选择LSTM结果
    if duration <= 90
        lstm_pos_north = lstm_90_pos_north;
        lstm_pos_east = lstm_90_pos_east;
    else
        lstm_pos_north = lstm_180_pos_north;
        lstm_pos_east = lstm_180_pos_east;
    end
    
    % 提取数据
    loose_n = abs(loose_pos_north(outage_idx));
    loose_e = abs(loose_pos_east(outage_idx));
    lstm_n = abs(lstm_pos_north(outage_idx));
    lstm_e = abs(lstm_pos_east(outage_idx));
    
    % 位置误差图
    figure('Name', sprintf('位置误差-%ds', duration), 'Position', [100 100 900 600]);
    
    subplot(2,1,1);
    plot(time_outage, loose_n, 'b-', 'LineWidth', 2); hold on;
    plot(time_outage, lstm_n, 'r-', 'LineWidth', 2);
    xlabel('时间 (s)'); ylabel('北向位置误差 (m)');
    legend('纯INS', 'LSTM辅助');
    title(sprintf('北向位置误差 (%d秒中断)', duration));
    grid on; hold off;
    
    subplot(2,1,2);
    plot(time_outage, loose_e, 'b-', 'LineWidth', 2); hold on;
    plot(time_outage, lstm_e, 'r-', 'LineWidth', 2);
    xlabel('时间 (s)'); ylabel('东向位置误差 (m)');
    legend('纯INS', 'LSTM辅助');
    title(sprintf('东向位置误差 (%d秒中断)', duration));
    grid on; hold off;
    
    saveas(gcf, fullfile(results_dir, sprintf('Position_%ds.png', duration)));
    
    % 统计
    loose_n_rmse = sqrt(mean(loose_n.^2));
    loose_e_rmse = sqrt(mean(loose_e.^2));
    lstm_n_rmse = sqrt(mean(lstm_n.^2));
    lstm_e_rmse = sqrt(mean(lstm_e.^2));
    
    fprintf('  纯INS:  北向 %.2f m, 东向 %.2f m\n', loose_n_rmse, loose_e_rmse);
    fprintf('  LSTM:   北向 %.2f m, 东向 %.2f m\n', lstm_n_rmse, lstm_e_rmse);
    fprintf('  性能提升: 北向 %.1f%%, 东向 %.1f%%\n', ...
        (1-lstm_n_rmse/loose_n_rmse)*100, (1-lstm_e_rmse/loose_e_rmse)*100);
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
    
    if duration <= 90
        lstm_pos_north = lstm_90_pos_north;
        lstm_pos_east = lstm_90_pos_east;
    else
        lstm_pos_north = lstm_180_pos_north;
        lstm_pos_east = lstm_180_pos_east;
    end
    
    loose_n = sqrt(mean(abs(loose_pos_north(outage_idx)).^2));
    loose_e = sqrt(mean(abs(loose_pos_east(outage_idx)).^2));
    lstm_n = sqrt(mean(abs(lstm_pos_north(outage_idx)).^2));
    lstm_e = sqrt(mean(abs(lstm_pos_east(outage_idx)).^2));
    
    improve_n = (1-lstm_n/loose_n)*100;
    improve_e = (1-lstm_e/loose_e)*100;
    
    fprintf('║   %3ds     │  %6.1f  │ %6.1f │ %5.1f │ %5.1f │ %4.1f%%/%4.1f%% ║\n', ...
        duration, loose_n, loose_e, lstm_n, lstm_e, improve_n, improve_e);
end

fprintf('╚══════════════════════════════════════════════════════════════╝\n');

fprintf('\n图表已保存至: %s\n', results_dir);