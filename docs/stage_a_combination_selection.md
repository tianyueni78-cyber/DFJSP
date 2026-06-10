# 阶段 A：评价指标与组合选择

## 1. 目标

对同一正常基线和故障状态生成的部分右移方案与完全重调度 Pareto 候选统一计算 `tD`、`SD` 和 `Y`，选择综合评价值最小的最终方案。

## 2. 第一版权重

沿用问题定义中的论文复现建议：

```text
omega1 = 0.9
omega2 = 0.1
Y = 0.9 * tD + 0.1 * SD
```

权重保存在 `configs/stage_a_combination_config.m`，不写死在评价算法内部。

## 3. 指标定义

```text
tD = 候选方案最终卸载最大完工时间 - 正常基线最终卸载最大完工时间

SD = 故障时刻未开工工序中，候选加工机器与正常基线不同的工序数量
```

已完成和已冻结工序不计入 `SD`。

部分右移保持原机器分配，因此其 `SD` 应为 `0`。完全重调度允许重新选择候选机器，因此逐个评价去重后的 Pareto 候选。

## 4. 组合选择

候选集合包括：

1. 一个已完成 AGV 联动验证的部分右移方案；
2. 完全重调度搜索返回的全部去重 Pareto 候选。

首先选择 `Y` 最小者。若 `Y` 在容差内相同，则依次选择：

1. `tD` 更小者；
2. `SD` 更小者。

评价结果同时保留全部分项指标，不只保存最终 `Y`。

## 5. 文件

- `configs/stage_a_combination_config.m`
- `src/evaluation/evaluate_stage_a_rescheduling_plan.m`
- `src/evaluation/select_stage_a_combined_strategy.m`
- `scripts/run_stage_a_combination_contract.m`
- `scripts/run_stage_a_combination_selection.m`
- `tests/test_stage_a_combination_contract.m`

## 6. 当前测试边界

契约测试使用已通过的部分右移方案和 `6` 个体、`2` 代轻量完全重调度搜索，只验证指标和选择逻辑，不代替正式自适应搜索结果。

## 7. MATLAB 测试

```matlab
run(fullfile(pwd, 'tests', ...
    'test_stage_a_combination_contract.m'))
```

预期输出：

```text
test_stage_a_combination_contract passed
```

## 8. 复用已有自适应搜索

如果 MATLAB 工作区里仍保留刚才 94 代搜索得到的 `scenario`，测试通过后可直接执行：

```matlab
combined = run_stage_a_combination_selection(scenario);
combined.combined_selection.selected_strategy
combined.combined_selection.selected_metrics
```

该入口不会重新运行完全重调度搜索，只重新生成确定性的部分右移方案并完成组合评价。
