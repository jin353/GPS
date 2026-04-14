%% 生成60/120/180秒中断的完整实验结果（按论文方式计算）
clc; clear;

fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║           实验结果 - 60秒/120秒/180秒中断                   ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

%% 加载结果
load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_pureINS_pos.mat');
load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_LSTM_pos.mat');
loose_pos_north = error_pos_north_pureINS;
loose_pos_east = error_pos_east_pureINS;
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

fprintf('中断时间 │ 纯INS结束误差 │ LSTM结束误差 │ 性能提升\n');
fprintf('─────────┼───────────────┼──────────────┼──────────\n');

for idx = 1:length(outage_scenarios)
    duration = outage_scenarios(idx);
    outage_end = outage_start + duration;
    
    % 选择LSTM结果
    if duration <= 90
        lstm_pos_north = lstm_90_pos_north;
        lstm_pos_east = lstm_90_pos_east;
    else
        lstm_pos_north = lstm_180_pos_north;
        lstm_pos_east = lstm_180_pos_east;
    end
    
    % 提取中断结束时的误差（最后1秒的平均值）
    end_idx = (time_vec >= outage_end - 1) & (time_vec <= outage_end);
    
    loose_end = sqrt(mean(loose_pos_north(end_idx).^2 + loose_pos_east(end_idx).^2));
    lstm_end = sqrt(mean(lstm_pos_north(end_idx).^2 + lstm_pos_east(end_idx).^2));
    
    improve = (1 - lstm_end / loose_end) * 100;
    
    fprintf('  %3ds    │   %6.1f m     │   %5.1f m    │  %5.1f%%\n', ...
        duration, loose_end, lstm_end, improve);
    
    % 生成位置误差图
    outage_idx = (time_vec >= outage_start) & (time_vec <= outage_end);
    time_outage = time_vec(outage_idx) - outage_start;
    
    loose_n = abs(loose_pos_north(outage_idx));
    loose_e = abs(loose_pos_east(outage_idx));
    lstm_n = abs(lstm_pos_north(outage_idx));
    lstm_e = abs(lstm_pos_east(outage_idx));
    
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
end

fprintf('\n注意：性能提升按论文方式计算（中断结束时的误差）\n');