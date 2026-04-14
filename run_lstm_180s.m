%% LSTM辅助松耦合 - 180秒中断
% 沿用参考1逻辑，使用修改后的obss_shanchu_180s.mat
clear; clc;
addpath('functions');
addpath('data');
addpath('models');
ggpsvars

%% 加载数据
load('data/shuju.mat');
load('data/att_vel_true.mat');
load('data/ephs1.mat');
load('data/obss_shanchu_180s.mat');  % 使用180秒中断数据
obss = obss_new;
t0 = obss(1,1);

%% 数据预处理
findgpsobs(obss);
obsi = findgpsobs(t0);
CA(1,:) = obsi(:,3);
CA_mean = CA;
load('models/delta_W_mean.mat');
for i = 2:length(W_1)+1
    CA_mean(i,:) = CA_mean(i-1,:) + W_1(i-1,:);
end
avp1(:,1:2) = avp1(:,1:2) * glv.dps;
psinstypedef(153);

%% 加载LSTM模型
load('models/LSTM.mat');
load('models/MAX1.mat');
load('models/MIN1.mat');

%% 初始化
nn = 1; ts = 0.005; nts = nn*ts; recPos = zeros(4,1);
avp0 = [deg2rad(att(1,:)) 0 0 0 avp1(1,1:3)]';
imuerr = imuerrset(8, [10;10;15], 0.007, 60);
davp0 = avperrset([0.5;-0.5;20], 0.1, [0.1;0.1;0.3]);
ins = insinit(avp0, ts);

rk = poserrset([0.3;0.3;0.9]);
kf = kfinit(ins, davp0, imuerr, rk);
kf.Pmin = [davp0; gabias(8, [10;10;15])].^2;
kf.pconstrain = 1;

len = length(imu);
[avp, xkpk] = prealloc(fix(len/nn), 10, 2*kf.n+1);
ki = 1; song = 1; M = 2; kk = 1; z = 1; l = 1;

%% 主循环（完全沿用参考1逻辑）
fprintf('Running LSTM loose coupling (180s outage)...\n');
for k = 1:nn:len
    wvm = imu(k,1:6); tp = t0 + imu(k,end);
    ins = insupdate(ins, wvm);
    kf.Phikk_1 = kffk(ins);
    kf = kfupdate(kf);
    
    if mod(tp,1) == 0
        obsi = findgpsobs(tp);
        
        % 判断GPS可用性（沿用参考1）
        if size(obsi,1) < 4
            song = 0;
        else
            song = 1;
        end
        
        if song == 1
            % GPS可用：正常处理
            ephi = ephs(obsi(:,2),:);
            CA = CA_mean(M,:)'; M = M + 1;
            [satpv, clkerr] = satPosVelBatch(obsi(1,1), ephi);
            [pvti, vp, res] = lspvt(recPos, satpv, CA + clkerr(:,2)*ggps.c);
            recPos = pvti(1:4);
            mygps(kk,:) = [vp;tp]'; kk = kk + 1; l = 1;
        else
            % GPS不可用：使用LSTM预测（沿用参考1）
            YPred_test = predict(net, cellData(M-1));
            YPred_test = double(YPred_test);
            YPred_test = denormalizeData(YPred_test, minVals, maxVals);
            
            current_satellites = obsi(:, 2);
            all_satellites = [32; 31; 26; 28];
            missing_satellites = setdiff(all_satellites, current_satellites);
            
            for i = 1:length(all_satellites)
                if ismember(all_satellites(i), missing_satellites)
                    CA(i) = CA(i) + YPred_test(i)';
                else
                    CA(i) = CA_mean(M, i);
                end
            end
            ephi = ephs(all_satellites,:); M = M + 1;
            [satpv, clkerr] = satPosVelBatch(obsi(1,1), ephi);
            [pvti, vp, res] = lspvt(recPos, satpv, CA + clkerr(:,2)*ggps.c);
            recPos = pvti(1:4);
            mygps(kk,:) = [vp;tp]'; kk = kk + 1;
            l = 0;
        end
        
        % 松耦合更新
        posGPS = mygps(kk-1,4:6)';
        kf = kfupdate(kf, ins.pos - posGPS, 'M');
        if size(kf.xk, 2) ~= 1
            kf.xk = kf.xk(:,1);
        end
        [kf, ins] = kffeedback(kf, ins, 1, 'avped');
    end
    
    avp(ki,:) = [ins.avp', tp];
    ki = ki + 1;
    
    if mod(k, 10000) == 0
        fprintf('  Progress: %d/%d (%.1f%%)\n', k, len, k/len*100);
    end
end

%% 整理结果
avp(ki:end,:) = [];
avp(:,7:8) = avp(:,7:8) / glv.deg;
avp1(:,1:2) = avp1(:,1:2) / glv.deg;
mygps(:,4:5) = mygps(:,4:5) / glv.deg;

%% 坐标转换
spheroid = wgs84Ellipsoid;
x = lla2ecef(avp(:,7:9));
[East_est, North_est, Up_est] = ecef2enu(x(:,1), x(:,2), x(:,3), ...
    avp1(1,1), avp1(1,2), avp1(1,3), spheroid);
x1 = lla2ecef(avp1(:,1:3));
[East, North, Up] = ecef2enu(x1(:,1), x1(:,2), x1(:,3), ...
    avp1(1,1), avp1(1,2), avp1(1,3), spheroid);

%% 计算误差
error_pos_east_lstm = East_est - East;
error_pos_north_lstm = North_est - North;

vel_lstm = avp(:,4:5);
error_vel_east_lstm = vel_lstm(:,1) - vel(:,1);
error_vel_north_lstm = vel_lstm(:,2) - vel(:,2);

att_lstm_deg = avp(:,1:3) / glv.deg;
error_yaw_lstm = att_lstm_deg(:,3) - att(:,3);

%% 统计
dt = 0.005;
time_vec = (0:dt:369.995)';

fprintf('\n========================================\n');
fprintf('LSTM辅助松耦合(180s中断)结果:\n');
fprintf('========================================\n');
fprintf('非中断(0-100s): 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north_lstm(time_vec<100).^2)), ...
    sqrt(mean(error_pos_east_lstm(time_vec<100).^2)));
fprintf('中断(100-280s): 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north_lstm(time_vec>=100 & time_vec<280).^2)), ...
    sqrt(mean(error_pos_east_lstm(time_vec>=100 & time_vec<280).^2)));
fprintf('中断后(280-370s): 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north_lstm(time_vec>=280).^2)), ...
    sqrt(mean(error_pos_east_lstm(time_vec>=280).^2)));

%% 保存
save('results/lstm_loose_180s.mat', ...
    'error_pos_north_lstm', 'error_pos_east_lstm', ...
    'error_vel_north_lstm', 'error_vel_east_lstm', ...
    'error_yaw_lstm');
fprintf('\nDone!\n');