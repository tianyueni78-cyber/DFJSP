# 阶段 B-R 第 11 步：重调度评价与组合策略选择

## 目标

在同一个正常基线、同一个加工中故障和同一个从头加工承诺下，公平比较：

1. AGV 联动局部右移；
2. 从头加工完全重调度 Pareto 候选。

本步不重新运行正式搜索。正式评价直接复用第 10 步保存的 `result.mat`。

## 评价指标

```text
tD = 候选最终卸载时间 - 正常基线最终卸载时间
SD = 故障时未开工工序中，机器分配变化的工序数量
Y  = 0.9 × tD + 0.1 × SD
```

`Y` 越小越好。若 `Y` 在容差内相同，依次选择 `tD` 更小、`SD` 更小的方案。

中断工序在故障时已经开工并被固定为“损失加工段 + 完整重加工段”，因此
不属于未开工工序，不计入 `SD`。

## 公平比较条件

- 正常基线染色体相同；
- 正常基线最终卸载时间相同；
- 故障机器、故障时刻和维修结束时刻相同；
- 中断工序相同；
- 两类候选都采用 `restart_on_original_machine`；
- 两类候选都满足 `restart_from_zero = true`；
- 损失加工时间和完整重加工完成时间相同。

## 第 10 步正式搜索记录

结果目录：

```text
outputs/stage_br_complete_reschedule_search/20260615_095322/
```

已确认：

- 停止原因：`no_pareto_improvement`；
- 实际完成代数：`47`；
- 运行时间：约 `13.5523` 秒；
- 去重后 Pareto 数量：`1`；
- 最终卸载时间：约 `96.2`；
- 总能耗：约 `1710.4`。

精确目标值保存在 `result.mat`。

## 代码入口

- 权重配置：
  [`stage_br_combination_config.m`](../configs/stage_br_combination_config.m)
- 单方案评价：
  [`evaluate_stage_br_rescheduling_plan.m`](../src/evaluation/evaluate_stage_br_rescheduling_plan.m)
- 组合选择：
  [`select_stage_br_combined_strategy.m`](../src/evaluation/select_stage_br_combined_strategy.m)
- 正式结果复用：
  [`run_stage_br_combination_selection.m`](../scripts/run_stage_br_combination_selection.m)
- 轻量契约：
  [`run_stage_br_combination_contract.m`](../scripts/run_stage_br_combination_contract.m)
- 测试：
  [`test_stage_br_combination_contract.m`](../tests/test_stage_br_combination_contract.m)

## 轻量测试

```matlab
run(fullfile(pwd,'tests','test_stage_br_combination_contract.m'))
```

轻量测试已通过：

```text
test_stage_br_combination_contract passed
```

## 正式组合结果

| 方案 | 最终卸载时间 | tD | SD | Y |
|---|---:|---:|---:|---:|
| AGV 联动局部右移 | 144.2033 | 0 | 0 | 0 |
| 从头加工完全重调度 | 96.1633 | -48.0400 | 36 | -39.6360 |

当前权重 `omega1=0.9、omega2=0.1` 下，最终选择：

```text
complete_rescheduling
```

局部右移保持原机器分配，因此 `SD=0`，但最终卸载时间没有改善。完全重调度
改变 `36` 道未开工工序的机器分配，其完工时间改善足以抵消序列扰动惩罚。

`tD=-48.04` 表示完全重调度候选优于当前正常基线，不表示机器故障产生收益。
该结果同时包含对故障后剩余任务的重新优化效果。

下一步应进行权重敏感性、约束与能耗审计，并使用多个随机种子检查该选择
是否稳定。
