# 阶段 C 第 17.2 步：最终审计多随机种子入口

## 目标

为阶段 C 最终审计矩阵中已经实现的两个可运行场景建立统一的多随机种子正式实验入口：

- `C-S1`：两台机器同时故障，保留进度继续加工；
- `C-SEQ1`：两次故障先后发生且维修不重叠，保留进度继续加工。

`C-S2` 和 `C-SEQ2` 仍是计划项，不在本次多随机种子入口中运行。

## 本步完成的内容

- 新增 `stage_c_final_audit_multiseed_config`，统一种子、种群规模、迭代上限和自适应停止规则；
- 新增 `run_stage_c_final_audit_multiseed`，按场景和随机种子循环运行正式搜索；
- 对每次运行执行组合选择，记录 `tD`、`SD`、`Y`、策略选择、Pareto 数量、停止原因和审计结果；
- 输出 `result.mat`、`multiseed_summary.csv`、`scenario_summary.csv` 和 `run_summary.txt`；
- 新增配置契约测试，确认入口存在且只覆盖已实现场景。

## 代码入口

- 配置：`configs/stage_c_final_audit_multiseed_config.m`
- 正式运行入口：`scripts/run_stage_c_final_audit_multiseed.m`
- 契约测试：`tests/test_stage_c_final_audit_multiseed_config.m`

## 运行方式

先运行轻量配置测试：

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_c_final_audit_multiseed_config.m'))
```

确认后再运行正式多随机种子实验：

```matlab
cd('D:\CODEX\机器故障')
addpath(fullfile(pwd,'scripts'))
result = run_stage_c_final_audit_multiseed();
```

## 当前状态

入口已建立，配置测试已通过，正式多随机种子实验已完成。

输出目录：

```text
outputs/stage_c_final_audit_multiseed/20260616_094301
```

## 正式结果

总体结果：

- 运行场景数：`2`
- 总运行次数：`10`
- 随机种子：`[11,22,33,42,55]`
- 种群规模：`10`
- 最大代数：`100`
- 连续无改善停止阈值：`10`
- 单次运行时间上限：`30` 秒
- 全部约束与能耗审计通过：`true`

场景汇总：

| 场景 | 运行次数 | 最优 Y | 平均 Y | 最差 Y | 最优最终卸载 | 平均最终卸载 | 全部通过 |
|---|---:|---:|---:|---:|---:|---:|---|
| `C-S1` | 5 | -28.9830 | -20.7118 | -13.7730 | 109.6667 | 118.7680 | 是 |
| `C-SEQ1` | 5 | -23.6420 | -17.8016 | -7.2590 | 113.4900 | 119.3127 | 是 |

逐次结果：

| 场景 | 种子 | 停止原因 | 代数 | Pareto 数 | 最终策略 | 最终卸载 | tD | SD |
|---|---:|---|---:|---:|---|---:|---:|---:|
| `C-S1` | 11 | no_pareto_improvement | 33 | 2 | complete_rescheduling | 119.0000 | -25.2033 | 24 |
| `C-S1` | 22 | no_pareto_improvement | 77 | 3 | complete_rescheduling | 126.9000 | -17.3033 | 18 |
| `C-S1` | 33 | no_pareto_improvement | 33 | 2 | complete_rescheduling | 122.1900 | -22.0133 | 20 |
| `C-S1` | 42 | no_pareto_improvement | 42 | 2 | complete_rescheduling | 116.0833 | -28.1200 | 26 |
| `C-S1` | 55 | maximum_generations | 100 | 3 | complete_rescheduling | 109.6667 | -34.5367 | 21 |
| `C-SEQ1` | 11 | no_pareto_improvement | 29 | 1 | complete_rescheduling | 132.0267 | -9.1767 | 10 |
| `C-SEQ1` | 22 | maximum_generations | 100 | 5 | complete_rescheduling | 120.6667 | -20.5367 | 25 |
| `C-SEQ1` | 33 | no_pareto_improvement | 61 | 4 | complete_rescheduling | 116.5833 | -24.6200 | 26 |
| `C-SEQ1` | 42 | maximum_generations | 100 | 2 | complete_rescheduling | 113.4900 | -27.7133 | 13 |
| `C-SEQ1` | 55 | no_pareto_improvement | 39 | 3 | complete_rescheduling | 113.7967 | -27.4067 | 21 |

结论：

- 在已实现的两个阶段 C 场景中，`10` 次运行全部选择 `complete_rescheduling`；
- 两个场景均通过最终约束审计和能耗审计；
- 策略选择稳定，但不同随机种子下解质量仍有波动；
- `C-S2` 和 `C-SEQ2` 尚未实现，不能纳入最终结论。
