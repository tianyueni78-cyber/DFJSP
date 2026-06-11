# 阶段 B 第 12 步：重调度评价与组合策略选择

## 本步目标

在同一个加工中故障场景和同一正常基线上，对以下两类候选进行公平比较：

1. AGV 联动局部右移；
2. 支持中断工序两段加工的完全重调度 Pareto 候选。

本步不重新运行正式搜索，只复用第 11 步保存的 `result.mat`。

## 评价指标

完工时间偏差：

```text
tD = 重调度后最终卸载时间 - 正常基线最终卸载时间
```

序列偏差：

```text
SD = 故障时未开工工序中，加工机器发生变化的工序数量
```

组合指标：

```text
Y = 0.9 × tD + 0.1 × SD
```

`Y` 越小越好。若 `Y` 在容差内相同，依次选择 `tD` 更小、`SD` 更小的方案。

中断工序已经在故障前开始加工，属于冻结的两段加工承诺，不计入 `SD`。

## 第 11 步正式结果

正式结果目录：

```text
outputs/stage_b_complete_reschedule_search/20260611_100355/
```

已确认结果：

- 停止原因：`no_pareto_improvement`
- 实际完成代数：`47`
- 运行时间：约 `11.4701` 秒
- 去重后 Pareto 数量：`1`
- Pareto 目标：最终卸载时间约 `96.2`，总能耗约 `1702.6`

上述目标值来自 MATLAB 短格式显示，精确值保存在 `result.mat`。

## 代码入口

- 权重配置：
  [`stage_b_combination_config.m`](../configs/stage_b_combination_config.m)
- 单方案评价：
  [`evaluate_stage_b_rescheduling_plan.m`](../src/evaluation/evaluate_stage_b_rescheduling_plan.m)
- 组合选择：
  [`select_stage_b_combined_strategy.m`](../src/evaluation/select_stage_b_combined_strategy.m)
- 复用正式搜索：
  [`run_stage_b_combination_selection.m`](../scripts/run_stage_b_combination_selection.m)
- 轻量契约：
  [`run_stage_b_combination_contract.m`](../scripts/run_stage_b_combination_contract.m)
- 测试：
  [`test_stage_b_combination_contract.m`](../tests/test_stage_b_combination_contract.m)

## 轻量测试

该测试使用既有 `6×2` 契约搜索，不保存输出：

```matlab
run(fullfile(pwd,'tests','test_stage_b_combination_contract.m'))
```

## 正式组合结果

轻量契约测试已通过：

```text
test_stage_b_combination_contract passed
```

使用第 11 步正式 `result.mat` 得到：

| 方案 | 最终卸载时间 | tD | SD | Y |
|---|---:|---:|---:|---:|
| AGV 联动局部右移 | 144.2033 | 0 | 0 | 0 |
| 完全重调度 | 96.1633 | -48.0400 | 36 | -39.6360 |

当前权重 `omega1=0.9、omega2=0.1` 下，最终选择：

```text
complete_rescheduling
```

局部右移保持原机器分配，因此 `SD=0`；其最终卸载时间没有超过正常基线，
说明本场景的维修延迟被原计划余量吸收。完全重调度改变了 `36` 道未开工
工序的机器分配，但完工时间改善足以抵消序列扰动惩罚。

`tD=-48.04` 表示完全重调度候选优于当前正常基线，不表示机器故障本身产生
收益。该结果同时包含对剩余任务的重新优化效果，后续仍需通过多随机种子和
权重敏感性分析检查结论稳定性。

## 复现命令

```matlab
data = load(fullfile(pwd,'outputs', ...
    'stage_b_complete_reschedule_search', ...
    '20260611_100355','result.mat'));

stage12 = run_stage_b_combination_selection(data.scenario);

stage12.combined_selection.selected_strategy
stage12.combined_selection.selected_metrics
stage12.combined_selection.right_shift_metrics
stage12.combined_selection.complete_reschedule_metrics
```
