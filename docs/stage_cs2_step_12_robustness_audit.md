# C-S2 第 12 步：权重敏感性、多随机种子与最终审计

## 目标

在 C-S2 正式组合选择之后，检查结论是否稳定：

- 固定第 11 步候选集，扫描 `omega1=0:0.1:1`；
- 对局部右移和完全重调度 Pareto 候选重新做 C-S2 专用审计；
- 建立五随机种子正式实验入口，但不在契约测试中运行。

## 配置

`configs/stage_cs2_step_12_config.m` 定义：

- 种群 `10`；
- 最大 `100` 代；
- 连续 `10` 代无改善停止；
- 最长 `30` 秒；
- 随机种子 `[11,22,33,42,55]`；
- 权重扫描 `0:0.1:1`；
- 输出目录 `outputs/stage_cs2_step_12_robustness/`。

## 代码入口

- `src/evaluation/analyze_stage_cs2_weight_sensitivity.m`
- `scripts/run_stage_cs2_step_12_analysis.m`
- `scripts/run_stage_cs2_step_12_multiseed.m`
- `tests/test_stage_cs2_step_12_contract.m`

## 契约测试命令

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_cs2_step_12_contract.m'))
```

## 正式五随机种子命令

运行前需要单独确认，因为会执行 5 次正式搜索并生成输出：

```matlab
cd('D:\CODEX\机器故障')
addpath(fullfile(pwd,'scripts'))

data = load(fullfile(pwd,'outputs', ...
    'stage_cs2_complete_reschedule_search', ...
    '20260616_150249','result.mat'));

stage11 = run_stage_cs2_combination_selection(data.scenario);
stage12Multiseed = run_stage_cs2_step_12_multiseed(stage11);
```

## 完成标准

- 权重扫描覆盖 `0:0.1:1`；
- 所有候选通过 C-S2 从头加工、维修、最终卸载和能耗审计；
- 多随机种子入口可复用同一 C-S2 场景；
- 正式多随机种子运行后能输出 `multiseed_summary.csv`。

## 当前五随机种子正式结果

基于 `outputs/stage_cs2_step_12_robustness/20260616_203807`：

| seed | stop_reason | generations | Pareto | strategy | makespan | tD | SD | Y |
|---:|---|---:|---:|---|---:|---:|---:|---:|
| 11 | `no_pareto_improvement` | 69 | 1 | `complete_rescheduling` | 116.50 | -27.703 | 26 | -22.333 |
| 22 | `no_pareto_improvement` | 37 | 2 | `complete_rescheduling` | 123.00 | -21.203 | 13 | -17.783 |
| 33 | `time_limit` | 84 | 4 | `complete_rescheduling` | 116.08 | -28.127 | 25 | -22.814 |
| 42 | `time_limit` | 74 | 4 | `complete_rescheduling` | 123.95 | -20.250 | 23 | -15.925 |
| 55 | `no_pareto_improvement` | 56 | 3 | `complete_rescheduling` | 110.43 | -33.770 | 26 | -27.793 |

汇总结论：

- `5/5` 次均选择 `complete_rescheduling`；
- 最好 `Y=-27.793`，最差 `Y=-15.925`，平均 `Y=-21.3296`；
- 平均 `tD=-26.2106`，说明最终卸载时间平均减少约 `26.21`；
- 平均 `SD=22.6`，说明完全重调度通过改变部分机器分配换取更短完工时间；
- 所有运行均保留 `restart_from_zero=true` 的 C-S2 规则。

解释：在当前原数据、同时故障、从头加工规则和 `0.9/0.1` 权重下，完全重调度选择具有多随机种子稳定性。
