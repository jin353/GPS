# V5 - INS/GNSS组合导航实验

## 项目简介

本项目实现了三种导航算法的对比实验：
1. **纯INS导航** - 仅使用IMU数据进行自主导航
2. **松组合导航** - INS/GNSS卡尔曼滤波融合
3. **LSTM辅助松组合** - 使用LSTM预测伪距增量辅助导航

## 目录结构

```
V5/
├── code/                          # 源代码目录
│   ├── pure_ins_navigation.m      # 纯INS导航算法
│   ├── loose_coupling_navigation.m # 松组合导航算法
│   ├── lstm_aided_navigation.m    # LSTM辅助松组合算法
│   ├── comparison_analysis.m      # 对比分析脚本
│   ├── functions/                 # 辅助函数库
│   ├── data/                      # 实验数据
│   └── models/                    # LSTM模型文件
│
├── results/                       # 实验结果
│   ├── pure_ins_results.mat       # 纯INS结果
│   ├── loose_coupling_results.mat # 松组合结果
│   ├── lstm_loose_results.mat     # LSTM辅助结果
│   ├── comparison_results.mat     # 对比分析结果
│   └── *.png                      # 对比图表
│
└── README.md                      # 本说明文件
```

## 环境要求

- MATLAB R2020a 或更高版本
- Mapping Toolbox (用于坐标转换)
- Deep Learning Toolbox (用于LSTM预测)

## 使用方法

### 1. 设置MATLAB路径

```matlab
cd('G:\lunwen\V5\code')
addpath('functions')
addpath('data')
addpath('models')
```

### 2. 运行实验

**运行纯INS导航：**
```matlab
run('pure_ins_navigation.m')
```

**运行松组合导航：**
```matlab
run('loose_coupling_navigation.m')
```

**运行LSTM辅助松组合：**
```matlab
run('lstm_aided_navigation.m')
```

**生成对比分析：**
```matlab
run('comparison_analysis.m')
```

## 实验配置

### 传感器参数

| 传感器 | 型号 | 采样率 |
|--------|------|--------|
| IMU | ICM-20602 | 50 Hz |
| GNSS | Ublox-M8P | 1 Hz |

### GNSS中断设置

- 中断开始时间：100秒
- 中断结束时间：190秒
- 中断持续时间：90秒

## 算法说明

### 1. 纯INS导航

使用IMU数据进行机械编排解算，包括：
- 姿态更新（四元数法）
- 速度更新
- 位置更新

### 2. 松组合导航

INS/GNSS卡尔曼滤波融合：
- 状态向量：15维（姿态误差3+速度误差3+位置误差3+陀螺偏置3+加速度计偏置3）
- 观测量：GNSS位置与INS位置之差
- GNSS可用时进行观测更新，不可用时仅时间更新

### 3. LSTM辅助松组合

在松组合基础上增加LSTM预测：
- LSTM输入：IMU比力、角速率、速度、航向
- LSTM输出：伪距增量预测
- GNSS中断时使用LSTM预测值补偿缺失观测

## 结果说明

### 误差指标

- **RMSE** - 均方根误差
- **最大误差** - 误差绝对值的最大值

### 对比图表

- `position_error_comparison.png` - 位置误差对比
- `velocity_error_comparison.png` - 速度误差对比
- `heading_error_comparison.png` - 航向误差对比

## 参考文献

[1] Fang, W., Jiang, J., Lu, S., et al. A LSTM Algorithm Estimating Pseudo Measurements for Aiding INS during GNSS Signal Outages. Remote Sensing, 2020, 12(2): 256.

## 作者

本项目为毕业设计实验代码，基于上述论文方法实现。