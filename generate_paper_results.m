%% 根据论文要求生成60/120/180秒中断的对比结果
clc; clear;

fprintf('========================================\n');
fprintf('  根据论文要求生成实验结果\n');
fprintf('========================================\n\n');

%% 加载结果
load('G:\lunwen\V5\code\results\pure_ins_results.mat');
load('G:\lunwen\V5\code\results\lstm_loose_results.mat');

%% 加载参考1结果
ref1_pure = load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_pureINS_pos.mat');
ref1_lstm = load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_LSTM_pos.mat');
ref1_pure_vel = load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_pureINS_vel.mat');
ref1_lstm_vel = load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_LSTM_vel.mat');
ref1_pure_att = load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_pureINS_att.mat');
ref1_lstm_att = load('G:\lunwen\参考1\test - LSTM - 副本\duibi\error_LSTM_att.mat');

%% 定义中断时间段
dt = 0.005;
total_time = 370;
time_vec = (0:dt:(total_time-dt))';

%% 三种中断场景
outage_scenarios = [60, 120, 180];
outage_start = 100;  % 从100秒开始中断

%% 创建结果目录
results_dir = 'G:\lunwen\V5\paper_results';
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

%% 对每种中断场景生成结果
for idx = 1:length(outage_scenarios)
    duration = outage_scenarios(idx);
    outage_end = outage_start + duration;
    
    fprintf('\n【%d秒中断场景】\n', duration);
    fprintf('========================================\n');
    
    % 提取中断期间数据
    outage_idx = (time_vec >= outage_start) & (time_vec <= outage_end);
    time_outage = time_vec(outage_idx) - outage_start;
    
    % ========== 位置误差 ==========
    % 参考1
    ref1_pure_north = abs(ref1_pure.error_pos_north_pureINS(outage_idx));
    ref1_pure_east = abs(ref1_pure.error_pos_east_pureINS(outage_idx));
    ref1_lstm_north = abs(ref1_lstm.error_pos_north_loose_LSTM(outage_idx));
    ref1_lstm_east = abs(ref1_lstm.error_pos_east_loose_LSTM(outage_idx));
    
    % V5
    v5_pure_north = abs(error_pos_north_pureINS(outage_idx));
    v5_pure_east = abs(error_pos_east_pureINS(outage_idx));
    v5_lstm_north = abs(error_pos_north_loose_LSTM(outage_idx));
    v5_lstm_east = abs(error_pos_east_loose_LSTM(outage_idx));
    
    % 绘制位置误差图
    figure('Name', sprintf('位置误差 - %d秒中断', duration), 'Position', [100 100 800 600]);
    
    subplot(2,1,1);
    plot(time_outage, ref1_pure_north, 'g-', 'LineWidth', 1.5); hold on;
    plot(time_outage, ref1_lstm_north, 'r-', 'LineWidth', 1.5);
    plot(time_outage, v5_pure_north, 'g--', 'LineWidth', 1.5);
    plot(time_outage, v5_lstm_north, 'r--', 'LineWidth', 1.5);
    xlabel('时间 (s)'); ylabel('北向位置误差 (m)');
    legend('参考1-松耦合', '参考1-LSTM', 'V5-松耦合', 'V5-LSTM');
    title(sprintf('北向位置误差 (%d秒中断)', duration));
    grid on; hold off;
    
    subplot(2,1,2);
    plot(time_outage, ref1_pure_east, 'g-', 'LineWidth', 1.5); hold on;
    plot(time_outage, ref1_lstm_east, 'r-', 'LineWidth', 1.5);
    plot(time_outage, v5_pure_east, 'g--', 'LineWidth', 1.5);
    plot(time_outage, v5_lstm_east, 'r--', 'LineWidth', 1.5);
    xlabel('时间 (s)'); ylabel('东向位置误差 (m)');
    legend('参考1-松耦合', '参考1-LSTM', 'V5-松耦合', 'V5-LSTM');
    title(sprintf('东向位置误差 (%d秒中断)', duration));
    grid on; hold off;
    
    saveas(gcf, fullfile(results_dir, sprintf('position_error_%ds.png', duration)));
    
    % ========== 速度误差 ==========
    ref1_pure_vel_north = abs(ref1_pure_vel.error_vel_north_pureINS(outage_idx));
    ref1_pure_vel_east = abs(ref1_pure_vel.error_vel_east_pureINS(outage_idx));
    ref1_lstm_vel_north = abs(ref1_lstm_vel.error_vel_north_loose_LSTM(outage_idx));
    ref1_lstm_vel_east = abs(ref1_lstm_vel.error_vel_east_loose_LSTM(outage_idx));
    
    figure('Name', sprintf('速度误差 - %d秒中断', duration), 'Position', [100 100 800 600]);
    
    subplot(2,1,1);
    plot(time_outage, ref1_pure_vel_north, 'g-', 'LineWidth', 1.5); hold on;
    plot(time_outage, ref1_lstm_vel_north, 'r-', 'LineWidth', 1.5);
    xlabel('时间 (s)'); ylabel('北向速度误差 (m/s)');
    legend('参考1-松耦合', '参考1-LSTM');
    title(sprintf('北向速度误差 (%d秒中断)', duration));
    grid on; hold off;
    
    subplot(2,1,2);
    plot(time_outage, ref1_pure_vel_east, 'g-', 'LineWidth', 1.5); hold on;
    plot(time_outage, ref1_lstm_vel_east, 'r-', 'LineWidth', 1.5);
    xlabel('时间 (s)'); ylabel('东向速度误差 (m/s)');
    legend('参考1-松耦合', '参考1-LSTM');
    title(sprintf('东向速度误差 (%d秒中断)', duration));
    grid on; hold off;
    
    saveas(gcf, fullfile(results_dir, sprintf('velocity_error_%ds.png', duration)));
    
    % ========== 航向误差 ==========
    ref1_pure_yaw = abs(ref1_pure_att.error_yaw_pureINS(outage_idx));
    ref1_lstm_yaw = abs(ref1_lstm_att.error_yaw_loose_LSTM(outage_idx));
    
    figure('Name', sprintf('航向误差 - %d秒中断', duration), 'Position', [100 100 800 400]);
    
    plot(time_outage, ref1_pure_yaw, 'g-', 'LineWidth', 1.5); hold on;
    plot(time_outage, ref1_lstm_yaw, 'r-', 'LineWidth', 1.5);
    xlabel('时间 (s)'); ylabel('航向误差 (度)');
    legend('参考1-松耦合', '参考1-LSTM');
    title(sprintf('航向误差 (%d秒中断)', duration));
    grid on; hold off;
    
    saveas(gcf, fullfile(results_dir, sprintf('heading_error_%ds.png', duration)));
    
    % ========== 统计结果 ==========
    fprintf('\n位置误差统计:\n');
    fprintf('  松耦合: 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
        sqrt(mean(ref1_pure_north.^2)), sqrt(mean(ref1_pure_east.^2)));
    fprintf('  LSTM:   北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
        sqrt(mean(ref1_lstm_north.^2)), sqrt(mean(ref1_lstm_east.^2)));
    fprintf('  性能提升: 北向 %.1f%%, 东向 %.1f%%\n', ...
        (1-sqrt(mean(ref1_lstm_north.^2))/sqrt(mean(ref1_pure_north.^2)))*100, ...
        (1-sqrt(mean(ref1_lstm_east.^2))/sqrt(mean(ref1_pure_east.^2)))*100);
    
    fprintf('\n最大误差:\n');
    fprintf('  松耦合: 北向 %.2f m, 东向 %.2f m\n', ...
        max(ref1_pure_north), max(ref1_pure_east));
    fprintf('  LSTM:   北向 %.2f m, 东向 %.2f m\n', ...
        max(ref1_lstm_north), max(ref1_lstm_east));
end

%% 生成轨迹对比图
fprintf('\n\n【轨迹对比图】\n');
fprintf('========================================\n');

% 加载坐标转换后的轨迹数据
load('G:\lunwen\V5\code\results\pure_ins_results.mat');

% 检查变量名
if exist('East_true', 'var') && exist('North_true', 'var')
    figure('Name', '轨迹对比', 'Position', [100 100 800 600]);
    plot(East_true, North_true, 'r-', 'LineWidth', 2); hold on;
    plot(East_ins, North_ins, 'b-', 'LineWidth', 1.5);
    xlabel('东向 (m)'); ylabel('北向 (m)');
    legend('真实轨迹', '松耦合轨迹');
    title('轨迹对比图');
    grid on; hold off;
    saveas(gcf, fullfile(results_dir, 'trajectory_comparison.png'));
else
    fprintf('警告：轨迹数据变量不存在，跳过轨迹图生成\n');
end

fprintf('\n所有图表已保存至: %s\n', results_dir);
fprintf('========================================\n');
fprintf('  完成！\n');
fprintf('========================================\n');