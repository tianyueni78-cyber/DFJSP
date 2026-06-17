# C-SEQ2 第 12 步：正式搜索运行结果

## 运行入口

- `scripts/run_stage_cseq2_complete_search.m`

## 输出目录

- `outputs/stage_cseq2_complete_reschedule_search/20260617_165951`

## 搜索配置

- 种群规模：10
- 最大迭代：100
- 连续无改善停止：10 代
- 时间上限：30 秒
- 随机种子：42

## 运行结果

- 停止原因：`time_limit`
- 实际完成代数：74
- 运行时间：30.1582 秒
- 去重后 Pareto 解数量：1

Pareto 目标：

| final_unload_makespan | total_energy |
| ---: | ---: |
| 112.8 | 1779.5 |

## 当前结论

C-SEQ2 维修区间重叠连续故障场景下，正式完全重调度搜索可以正常运行并生成
可用结果。本次运行由 30 秒时间上限停止，而不是由最大代数或无改善停止触发。

下一步需要进行组合选择：将 C-SEQ2 局部右移方案与正式完全重调度 Pareto 方案
计算 `tD`、`SD`、`Y`，并选择最终策略。
