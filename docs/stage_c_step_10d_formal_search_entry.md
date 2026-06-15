# 阶段 C 第 10.4 步：正式搜索配置与结果保存入口

## 本步目标

为同时故障完全重调度建立单随机种子正式搜索配置和结果保存入口。本步只
实现入口及配置契约，不运行搜索、不创建输出目录。

## 正式配置

| 参数 | 数值 |
|---|---:|
| 种群规模 | 10 |
| 最大代数 | 100 |
| 交叉概率 | 0.8 |
| 变异概率 | 0.2 |
| 锦标赛规模 | 2 |
| 连续无改善停止 | 10 代 |
| 时间上限 | 30 秒 |
| 随机种子 | 42 |

程序达到最大代数、连续无改善阈值或时间上限中的任一条件即停止。

## 代码入口

- 配置：
  [`stage_c_simultaneous_complete_search_config.m`](../configs/stage_c_simultaneous_complete_search_config.m)
- 正式运行：
  [`run_stage_c_simultaneous_complete_search.m`](../scripts/run_stage_c_simultaneous_complete_search.m)
- 配置测试：
  [`test_stage_c_simultaneous_complete_search_config.m`](../tests/test_stage_c_simultaneous_complete_search_config.m)

## 输出规则

正式入口每次创建新的时间戳目录，不覆盖旧结果。目录位于：

```text
outputs/stage_c_simultaneous_complete_reschedule_search/<timestamp>/
```

每次保存：

- `result.mat`：完整场景、搜索结果和配置；
- `pareto_objectives.csv`：去重后的 Pareto 目标；
- `search_history.csv`：逐代最优目标和 Pareto 数量；
- `run_summary.txt`：配置、全部中断承诺、维修区间和停止原因。

正式入口会生成输出，运行前必须单独确认。
