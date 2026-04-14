clear ;clc;
ggpsvars
%% 加载LSTM数据
load 'C:\Users\a2582\Desktop\test - LSTM\shuji\delta_W_mean.mat'
load 'C:\Users\a2582\Desktop\test - LSTM\shuji\NET1.mat'
load 'C:\Users\a2582\Desktop\test - LSTM\shuji\MAX1.mat'
load 'C:\Users\a2582\Desktop\test - LSTM\shuji\MIN1.mat'
load 'C:\Users\a2582\Desktop\test - LSTM\shuji\cellData1.mat'
%% 加载IMU和GNSS数据
load shuju.mat;  load att_vel_true.mat       
load ephs1.mat;  load obss_shanchu.mat; t0=obss(1,1);
%%
findgpsobs(obss);
obsi = findgpsobs(t0);
CA(1,:) = obsi(:,3); % CA:伪距 
CA_mean=CA;
for i=2:length(W_1)+1
    CA_mean(i,:)=CA_mean(i-1,:)+W_1(i-1,:);
end
avp1(:,1:2)= avp1(:,1:2) * glv.dps;
psinstypedef(153);  
psinstypedef_tight('test_SINS_GPS_tightly_def');
%% initial settings
nn=1;ts=0.005;nts=nn*ts; recPos = zeros(4,1);
avp0=[deg2rad(att(1,:)) 0 0 0 avp1(1,1:3)]';  
% 松耦合_参数
imuerr = imuerrset(8, [10;10;15], 0.007, 60);  
davp0 = avperrset([0.5;-0.5;20], 0.1, [0.1;0.1;0.3]);  
ins = insinit(avp0, ts); 
% 紧耦合_参数
imuerr_tight = imuerrset(8, [10;10;15], 0.007, 60);
davp_tight = avperrset([0.5;-0.5;20], 0.1, [0.1;0.1;0.3]);
ins_tight = insinit(avp0, ts);
ins_tight.recPos = zeros(4,1);

%% KF filter
rk_tight = poserrset([0.3;0.3;0.9]);
kf_tight = kfinit_tight(ins, davp_tight, imuerr_tight, rk_tight);
kf_tight.Pmin = [davp_tight;  gabias(8, [10;10;15]); ones(1,1);zeros(1,1)].^2;  kf_tight.pconstrain=1;

rk = poserrset([0.3;0.3;0.9]);
kf = kfinit(ins, davp0, imuerr, rk);         
kf.Pmin = [davp0;  gabias(8, [10;10;15])].^2;  kf.pconstrain=1;   
len = length(imu); [avp, xkpk] = prealloc(fix(len/nn), 10, 2*kf.n+1);              
[avp_tight, xkpk_tight] = prealloc(fix(len/nn), 10, 2*kf_tight.n+1);
ki = 1; i = 1; m = 1; song = 1;  M = 2; z = 1;
kk = 1; l = 1; g = 1;
for k=1:nn:len

    wvm = imu(k,1:6);  tp =t0+imu(k,end);
    ins = insupdate(ins, wvm);  
    kf_tight.Gammak = 1;
    kf.Phikk_1 = kffk(ins);      
    kf = kfupdate(kf);           

    ins_tight = insupdate(ins_tight, wvm); 
    kf_tight.Phikk_1 = kffk_tight(ins_tight);  
    kf_tight = kfupdate(kf_tight);  
    if mod(tp,1)==0          
        %%
        obsi = findgpsobs(tp);
        if size(obsi,1)<4
            song=0;
           % continue;
        else
            song=1;
        end
       if song==1
            ephi = ephs(obsi(:,2),:);  CA = CA_mean(M ,:)'; M = M + 1; % CA:伪距
            [satpv, clkerr] = satPosVelBatch(obsi(1,1), ephi);      % SPP
            [pvti, vp, res] = lspvt(recPos, satpv, CA+ clkerr(:,2)*ggps.c); recPos = pvti(1:4);   % 需要改进
            mygps(kk,:) = [vp;tp]'; kk = kk + 1; l = 1;
        else
            YPred_test = predict(net,cellData(M-1)); YPred_test = double(YPred_test); 
            YPred_test = denormalizeData(YPred_test, minVals, maxVals);       
            %% 判断是哪个卫星缺失进行相应的补偿
            % 定义当前时刻的卫星编号
            current_satellites = obsi(:, 2);
            % 定义全部卫星编号
            all_satellites = [32; 31; 26; 28];
            % 找到未观测到的卫星编号
            missing_satellites = setdiff(all_satellites, current_satellites);
            % 遍历缺失的卫星编号并补偿伪距
            for i = 1:length(all_satellites)
                if ismember(all_satellites(i), missing_satellites)
                    % 如果卫星缺失，使用 YPred_test 进行补偿
                    CA(i) = CA(i) + YPred_test(i)';
                else
                    % 如果卫星未缺失，使用 CA_mean 的值
                    CA(i) = CA_mean(M, i);
                end
            end
            ephi = ephs(all_satellites,:);  M = M + 1; % CA:伪距
            [satpv, clkerr] = satPosVelBatch(obsi(1,1), ephi);      % SPP
            [pvti, vp, res] = lspvt(recPos, satpv, CA+ clkerr(:,2)*ggps.c); recPos = pvti(1:4);   % 需要改进
            l = 0;
        end
        
        if l==1
            ins_tight.recPos(4) = pvti(4);   % 需要改进
        end

        %% 紧耦合
        [satPos, clkCorr] = satPosVelBatch(obsi(1,1), ephi);%satPosBatch(obsi(1,1), ephi);
        
        [posxyz, Cen] = blh2xyz(ins_tight.pos);  % 惯导解算的接收机位置
        [rho, LOS, AzEl] = rhoSatRec(satPos, posxyz,  CA);
        el = AzEl(:,2); el(el<15*pi/180) = 1*pi/180;  P = diag(sin(el.^2));  % P = eye(size(P));

       % delta_rho = CA + clkerr(:,2)*ggps.c - ins_tight.recPos(4) - rho;  % 现已加入接收机钟差
       delta_rho = CA + clkerr(:,2)*ggps.c - recPos(4) - rho;  % 现已加入接收机钟差
        jun(g,:)=delta_rho;g=g+1;
        m = size(LOS,1);
        LT = LOS*Dblh2Dxyz(ins_tight.pos);
        kf_tight.Hk = [zeros(m,6),  LT, zeros(m,6), ones(m,1), zeros(m,1)];
        kf_tight.Rk = P^1*1;
        kf_tight = kfupdate(kf_tight, delta_rho);
        [kf_tight, ins_tight] = kffeedback(kf_tight, ins_tight, 1, 'avpeduf');

        %% 松耦合
        if song==1
        posGPS =mygps(z,4:6)';z=z+1;%
        kf = kfupdate(kf, ins.pos-posGPS, 'M');  
        [kf, ins] = kffeedback(kf, ins, 1, 'avped');     

        end   
    end
    avp_tight(ki,:) = [ins_tight.avp; tp]';
    xkpk_tight(ki,:) = [kf_tight.xk; diag(kf_tight.Pxk); tp]';
    avp(ki,:) = [ins.avp', tp];
    xkpk(ki,:) = [kf.xk; diag(kf.Pxk); tp]';  ki = ki+1;

end
avp(ki:end,:) = [];  xkpk(ki:end,:) = [];avp_tight(ki:end,:) = [];
avp_tight(:,10)=avp_tight(:,10)-t0;

avp_tight(:,7:8)=avp_tight(:,7:8)/glv.deg;
avp(:,7:8)=avp(:,7:8)/glv.deg;
avp1(:,1:2)=avp1(:,1:2)/glv.deg;
mygps(:,4:5)=mygps(:,4:5)/glv.deg;

spheroid = wgs84Ellipsoid;
x_tight=lla2ecef(avp_tight(:,7:9));  % 紧耦合轨迹
[East_tight, North_tight, Up_tight] = ecef2enu(x_tight(:,1),x_tight(:,2),x_tight(:,3), avp1(1,1), avp1(1,2), avp1(1,3), spheroid);jin_guiji=[East_tight, North_tight, Up_tight];
x=lla2ecef(avp(:,7:9));              % 松耦合轨迹
[East_est, North_est, Up_est] = ecef2enu(x(:,1),x(:,2),x(:,3), avp1(1,1), avp1(1,2), avp1(1,3), spheroid);song_guiji=[East_est, North_est, Up_est];
x1=lla2ecef(avp1(:,1:3));            % 真实轨迹
[East, North, Up] = ecef2enu(x1(:,1), x1(:,2), x1(:,3), avp1(1,1), avp1(1,2), avp1(1,3), spheroid); avp1_guiji=[East, North, Up];
x2=lla2ecef(mygps(:,4:6));           % GPS轨迹
[East_gps, North_gps, Up_gps] = ecef2enu(x2(:,1), x2(:,2), x2(:,3), avp1(1,1), avp1(1,2), avp1(1,3), spheroid);gps_guiji=[East_gps, North_gps, Up_gps];
% 调用平滑函数
pinghua = 1;
if pinghua==1
window_size = 4001;  % 设置滑动窗口大小
jin_guiji = smooth_array(jin_guiji, window_size);
song_guiji = smooth_array(song_guiji, window_size);
avp1_guiji = smooth_array(avp1_guiji, window_size);
window_size1 = 1; 
gps_guiji = smooth_array(gps_guiji, window_size1);
end
j=0;
if j==0
    figure
    plot3(song_guiji(:,1),song_guiji(:,2), song_guiji(:,3),'b-')
    hold on
    plot3(jin_guiji(:,1),jin_guiji(:,2), jin_guiji(:,3),'k')
    plot3(avp1_guiji(:,1),avp1_guiji(:,2), avp1_guiji(:,3),'r')
    scatter3(gps_guiji(:,1),gps_guiji(:,2), gps_guiji(:,3),10, 'g', 'filled')
    xlabel('North(m)')
    ylabel('East(m)')
    legend('松耦合','紧耦合','真实值','GPS')
else
    figure
    plot3(jin_guiji(:,1),jin_guiji(:,2), jin_guiji(:,3),'k')
    hold on
    plot3(avp1_guiji(:,1),avp1_guiji(:,2), avp1_guiji(:,3),'r')
    scatter3(gps_guiji(:,1),gps_guiji(:,2), gps_guiji(:,3),10, 'g', 'filled')
    xlabel('North(m)')
    ylabel('East(m)')
    legend('紧耦合','真实值','GPS')
end
if 0
%% 绘制紧耦合轨迹与真实轨迹的北向和东向位置误差图
% 计算纯INS轨迹与真实轨迹的误差
error_pos_east_pureINS  = song_guiji(:,1) - avp1_guiji(:,1);   % 东向误差
error_pos_north_pureINS = song_guiji(:,2) - avp1_guiji(:,2);    % 北向误差
%% 计算pureINS与真实值的速度误差（东方向和北方向）
% 松耦合估计速度（转换为 ENU）
vel_loose_est = [avp(:, 4:5)];               
% 计算速度误差（估计速度 - 真实速度）
error_vel_east_pureINS = vel_loose_est(:,1) - vel(:,1);
error_vel_north_pureINS = vel_loose_est(:,2) - vel(:,2);
%% 角度误差
att_loose_deg = avp(:,1:3) / glv.deg;          % 松耦合估计角度
% 计算角度误差（估计值 - 真实值）
error_roll_pureINS  = att_loose_deg(:,1) - att(:,1);
error_pitch_pureINS = att_loose_deg(:,2) - att(:,2);
error_yaw_pureINS   = att_loose_deg(:,3) - att(:,3);

choice = input('请输入 1 继续执行，或 0 结束程序: ');
if choice == 1
    disp('执行后续语句...');
    % 保存位置误差数据
    save('C:\Users\a2582\Desktop\test - LSTM\duibi\error_pureINS_pos', ...
        "error_pos_north_pureINS","error_pos_east_pureINS")
    % 保存速度误差数据
    save('C:\Users\a2582\Desktop\test - LSTM\duibi\error_pureINS_vel', ...
        "error_vel_east_pureINS", "error_vel_north_pureINS")
    % 保存角度误差数据
    save('C:\Users\a2582\Desktop\test - LSTM\duibi\error_pureINS_att', ...
        "error_roll_pureINS", "error_pitch_pureINS", "error_yaw_pureINS")

    disp('执行完成。');
else
    disp('程序结束。');
end
end