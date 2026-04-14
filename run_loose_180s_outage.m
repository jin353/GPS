%% 松耦合 - 180秒中断（280秒后才恢复）
clear; clc;
addpath('functions');
addpath('data');
addpath('models');
ggpsvars

%% 加载数据
load('data/shuju.mat');
load('data/att_vel_true.mat');
load('data/ephs1.mat');
load('data/obss_shanchu.mat');
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
ki = 1; song = 1; M = 2; kk = 1; z = 1;

%% 主循环
fprintf('Running loose coupling (180s outage, no recovery)...\n');
for k = 1:nn:len
    wvm = imu(k,1:6); tp = t0 + imu(k,end);
    ins = insupdate(ins, wvm);
    kf.Phikk_1 = kffk(ins);
    kf = kfupdate(kf);
    
    if mod(tp,1) == 0
        t_rel = tp - t0;
        
        % 100-280秒：GPS不可用
        if t_rel >= 100 && t_rel < 280
            song = 0;
        else
            obsi = findgpsobs(tp);
            if size(obsi,1) >= 4
                song = 1;
            else
                song = 0;
            end
        end
        
        if song == 1
            % GPS可用
            obsi = findgpsobs(tp);
            ephi = ephs(obsi(:,2),:);
            CA = CA_mean(M,:)'; M = M + 1;
            [satpv, clkerr] = satPosVelBatch(obsi(1,1), ephi);
            [pvti, vp, res] = lspvt(recPos, satpv, CA + clkerr(:,2)*ggps.c);
            recPos = pvti(1:4);
            mygps(kk,:) = [vp;tp]'; kk = kk + 1;
            
            % 松耦合更新
            posGPS = mygps(kk-1,4:6)';
            kf = kfupdate(kf, ins.pos - posGPS, 'M');
            if size(kf.xk, 2) ~= 1
                kf.xk = kf.xk(:,1);
            end
            [kf, ins] = kffeedback(kf, ins, 1, 'avped');
        else
            % GPS不可用
            M = M + 1;
            mygps(kk,:) = [0, 0, 0, ins.pos(1), ins.pos(2), ins.pos(3), tp];
            kk = kk + 1;
        end
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
error_pos_east_loose = East_est - East;
error_pos_north_loose = North_est - North;

vel_loose = avp(:,4:5);
error_vel_east_loose = vel_loose(:,1) - vel(:,1);
error_vel_north_loose = vel_loose(:,2) - vel(:,2);

att_loose_deg = avp(:,1:3) / glv.deg;
error_yaw_loose = att_loose_deg(:,3) - att(:,3);

%% 统计
dt = 0.005;
time_vec = (0:dt:369.995)';

fprintf('\n========================================\n');
fprintf('松耦合(180s中断，280s后恢复)结果:\n');
fprintf('========================================\n');
fprintf('0-100s: 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north_loose(time_vec<100).^2)), ...
    sqrt(mean(error_pos_east_loose(time_vec<100).^2)));
fprintf('100-280s: 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north_loose(time_vec>=100 & time_vec<280).^2)), ...
    sqrt(mean(error_pos_east_loose(time_vec>=100 & time_vec<280).^2)));
fprintf('280-370s: 北向RMSE %.2f m, 东向RMSE %.2f m\n', ...
    sqrt(mean(error_pos_north_loose(time_vec>=280).^2)), ...
    sqrt(mean(error_pos_east_loose(time_vec>=280).^2)));

%% 保存
save('results/loose_180s_outage_no_recovery.mat', ...
    'error_pos_north_loose', 'error_pos_east_loose', ...
    'error_vel_north_loose', 'error_vel_east_loose', ...
    'error_yaw_loose');
fprintf('\nDone!\n');