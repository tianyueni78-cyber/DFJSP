# 阶段 B 第 11 步：正式搜索配置与结果保存入口

## 本步目标

为阶段 B 加工中故障完全重调度建立单随机种子正式搜索配置和结果保存入口。

本步只实现并检查入口，不运行正式搜索、不创建结果目录。

## 正式配置

```text
种群规模：10
最大代数：100
交叉概率：0.8
变异概率：0.2
锦标赛规模：2
连续无改善停止：10 代
最长运行时间：30 秒
改善容差：1e-9
随机种子：42
```

搜索不要求跑满 `100` 代，满足连续无改善或时间上限时提前停止。

## 输出目录

每次运行创建独立目录：

```text
outputs/stage_b_complete_reschedule_search/YYYYMMDD_HHMMSS/
```

若同一秒目录已存在，则自动增加编号，不覆盖已有输出。

## 保存文件

- `result.mat`：完整场景、配置、搜索种群和 Pareto 候选；
- `pareto_objectives.csv`：最终卸载时间与总能耗；
- `search_history.csv`：每代最小目标和 Pareto 数量；
- `run_summary.txt`：参数、故障信息、停止原因和最小目标摘要。

摘要额外记录中断工序、故障机器、故障与修复时刻，以及两段加工解码标志。

## 研究边界

这是单随机种子正式搜索，用于获得阶段 B 的正式候选。它不是多随机种子
稳健性实验，因此入口标记：

- `is_formal_search = true`
- `is_full_experiment = false`

## 代码入口

- 配置：
  [`stage_b_complete_search_config.m`](../configs/stage_b_complete_search_config.m)
- 正式运行：
  [`run_stage_b_complete_search.m`](../scripts/run_stage_b_complete_search.m)
- 配置测试：
  [`test_stage_b_complete_search_config.m`](../tests/test_stage_b_complete_search_config.m)

## 当前可运行测试

配置测试不会运行搜索或生成输出：

```matlab
run(fullfile(pwd,'tests','test_stage_b_complete_search_config.m'))
```

## 正式运行

正式运行需再次确认后执行：

```matlab
addpath(fullfile(pwd,'scripts'))
scenario = run_stage_b_complete_search();
```
