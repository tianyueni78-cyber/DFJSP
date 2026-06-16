# C-S2 第 10 步：正式搜索配置与结果保存入口

## 目标

为“同时故障 + 从头加工规则”建立正式完全重调度搜索入口。第 10 步只定义
配置、入口和结果保存格式，不自动运行正式实验。

## 输入

- C-S2 第 6 步冻结问题；
- C-S2 第 9 步受限搜索函数；
- 原项目正常基线与原数据。

## 正式搜索配置

`configs/stage_cs2_complete_search_config.m` 定义：

- 种群规模：`10`；
- 最大代数：`100`；
- 交叉概率：`0.8`；
- 变异概率：`0.2`；
- 锦标赛规模：`2`；
- 连续 `10` 代 Pareto 无改善停止；
- 最长运行 `30` 秒；
- 随机种子：`42`；
- 输出目录：`outputs/stage_cs2_complete_reschedule_search/`。

## 输出文件

正式入口 `scripts/run_stage_cs2_complete_search.m` 每次运行会新建时间戳目录，
并保存：

- `result.mat`：完整 `scenario` 与配置；
- `pareto_objectives.csv`：去重后的 Pareto 解目标值；
- `search_history.csv`：每代最小最终卸载时间、最小总能耗和 Pareto 数量；
- `run_summary.txt`：故障、中断、维修区间、停止原因和最优目标摘要。

## 验证命令

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_cs2_complete_search_config.m'))
```

## 正式运行命令

正式运行会生成输出，运行前需要单独确认：

```matlab
cd('D:\CODEX\机器故障')
addpath(fullfile(pwd,'scripts'))
scenario = run_stage_cs2_complete_search();
```

## 完成标准

- 配置参数与阶段 B、B-R、C-S1 的正式搜索预算一致；
- 输出目录使用相对项目根路径；
- 正式入口存在但测试不启动正式搜索；
- 结果摘要包含从头加工承诺、损失加工时间、维修区间、Pareto 数和停止原因。
