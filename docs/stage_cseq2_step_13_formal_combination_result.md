# C-SEQ2 第 13 步：正式组合选择结果

## 输入

- 正式搜索输出：`outputs/stage_cseq2_complete_reschedule_search/20260617_165951/result.mat`
- 组合选择入口：`scripts/run_stage_cseq2_combination_selection.m`

## 权重

- `completion_time_weight = 0.9`
- `sequence_deviation_weight = 0.1`
- `Y = 0.9 * tD + 0.1 * SD`

## 正式结果

| strategy | baseline_makespan | candidate_makespan | tD | SD | Y |
| --- | ---: | ---: | ---: | ---: | ---: |
| partial_right_shift | 141.2033 | 144.2033 | 3.0000 | 0 | 2.7000 |
| complete_rescheduling | 141.2033 | 112.8367 | -28.3667 | 17 | -23.8300 |

## 最终选择

- 选中策略：`complete_rescheduling`
- 约束审计：`all_constraint_audits_validated = 1`
- 能耗审计：`all_energy_audits_complete = 1`

## 结论

在 C-SEQ2 维修区间重叠连续故障场景下，正式组合选择结果支持完全重调度。
虽然完全重调度带来 17 个机器分配变化，但最终卸载完工时间比当前计划降低
28.3667，使综合指标 `Y` 从局部右移的 `2.7000` 降至 `-23.8300`。

下一步可以进入 C-SEQ2 第 14 步：权重敏感性、最终审计和可选多随机种子
稳健性验证。
