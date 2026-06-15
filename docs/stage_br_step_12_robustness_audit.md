# 阶段 B-R 第 12 步：稳健性与最终审计

## 本步目标

在不改变阶段 B-R 第 11 步两个候选方案的前提下，检查组合选择是否受评价
权重影响，并确认“损失加工后从头加工”的约束和能耗计算完整。另建立五个
随机种子的正式实验入口，但轻量测试不会启动正式搜索。

## 1. 权重敏感性

对完工时间偏差权重 `omega1 = 0:0.1:1` 逐项计算：

```text
Y = omega1 * tD + (1 - omega1) * SD
```

每个权重只重新评价第 11 步已有的局部右移和 Pareto 候选，不重新运行
NSGA-II。输出记录所选策略、候选编号、最终卸载时间、`tD`、`SD` 和 `Y`。

## 2. 最终约束与能耗审计

局部右移和完全重调度候选均检查：

- 机器、工件、AGV 和最终卸载约束；
- 故障机器维修区间；
- 故障前损失加工段；
- 修复后的完整重加工段；
- 从头加工而非保留进度；
- 机器能耗、AGV 能耗和总能耗闭合。

能耗口径为：损失加工段和完整重加工段都属于实际机器工作时间，维修停机
间隔不计机器工作能耗。

## 3. 多随机种子入口

正式入口使用随机种子 `[11,22,33,42,55]`，每次保持与阶段 B-R 第 10 步
相同的种群、代数和自适应停止预算。每次运行保存停止原因、实际代数、
运行时间、Pareto 数量、所选策略和评价指标。

该入口会运行五次正式搜索并生成新输出，必须在用户确认后单独执行：

```matlab
stage12Multiseed = run_stage_br_step_12_multiseed(stage11);
```

## 代码入口

- 配置：`configs/stage_br_step_12_config.m`
- 权重敏感性：`src/evaluation/analyze_stage_br_weight_sensitivity.m`
- 候选审计：`src/evaluation/audit_stage_br_rescheduling_candidate.m`
- 局部右移能耗：`src/evaluation/evaluate_stage_br_right_shift_energy.m`
- 静态分析入口：`scripts/run_stage_br_step_12_analysis.m`
- 五种子实验入口：`scripts/run_stage_br_step_12_multiseed.m`
- 轻量测试：`tests/test_stage_br_step_12_contract.m`

## 当前边界

本步不修改 `raw_code/`，不改变算法逻辑，不新建问题数据。轻量测试不保存
输出；五随机种子正式结果尚未运行，因此当前不能写入稳健性实验结论。
