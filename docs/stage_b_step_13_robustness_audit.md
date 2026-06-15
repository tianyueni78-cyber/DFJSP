# 阶段 B 第 13 步：稳健性与最终约束审计

## 目标

验证第 12 步“选择完全重调度”的结论是否对组合权重和随机种子稳定，并对
加工中故障的局部右移及完全重调度候选执行统一约束与能耗审计。

## 三部分工作

1. 权重敏感性：固定第 12 步候选，将完工时间权重从 `0` 到 `1` 按 `0.1`
   扫描，不重复搜索。
2. 最终审计：检查两段加工承诺、维修区间、最终卸载、已有验证标志和能耗闭合。
3. 多随机种子：使用 `11、22、33、42、55` 重复同等预算正式搜索。

多随机种子会运行五次搜索并生成输出，本步只实现入口，运行前仍需确认。

## 阶段 B 专用审计

阶段 B 不能直接用阶段 A 的维修区间审计。中断工序的逻辑记录跨越维修区间，
但实际加工由以下两段组成：

- 故障前已加工段；
- 修复后剩余加工段。

因此维修冲突、机器工作时间和机器能耗均按 `processing_segments` 审计，
维修间隔不得计入有效加工时长或工作能耗。

## 配置

```text
随机种子：11、22、33、42、55
完工时间权重：0:0.1:1
种群规模：10
最大代数：100
连续无改善停止：10 代
时间上限：30 秒/种子
```

## 代码入口

- 配置：[`stage_b_step_13_config.m`](../configs/stage_b_step_13_config.m)
- 权重扫描：[`analyze_stage_b_weight_sensitivity.m`](../src/evaluation/analyze_stage_b_weight_sensitivity.m)
- 候选审计：[`audit_stage_b_rescheduling_candidate.m`](../src/evaluation/audit_stage_b_rescheduling_candidate.m)
- 局部右移能耗：[`evaluate_stage_b_right_shift_energy.m`](../src/evaluation/evaluate_stage_b_right_shift_energy.m)
- 轻量分析：[`run_stage_b_step_13_analysis.m`](../scripts/run_stage_b_step_13_analysis.m)
- 多种子入口：[`run_stage_b_step_13_multiseed.m`](../scripts/run_stage_b_step_13_multiseed.m)
- 测试：[`test_stage_b_step_13_contract.m`](../tests/test_stage_b_step_13_contract.m)

## 轻量测试

```matlab
run(fullfile(pwd,'tests','test_stage_b_step_13_contract.m'))
```

该测试使用既有 `6×2` 契约搜索，不读取正式输出，不运行五个随机种子，也不
生成结果目录。

测试结果：

```text
test_stage_b_step_13_contract passed
```

## 正式权重敏感性结果

复用第 12 步正式候选，未重新运行搜索：

| 完工时间权重 omega1 | 选择策略 | tD | SD | Y |
|---:|---|---:|---:|---:|
| 0.0 | 局部右移 | 0 | 0 | 0 |
| 0.1 | 局部右移 | 0 | 0 | 0 |
| 0.2 | 局部右移 | 0 | 0 | 0 |
| 0.3 | 局部右移 | 0 | 0 | 0 |
| 0.4 | 局部右移 | 0 | 0 | 0 |
| 0.5 | 完全重调度 | -48.04 | 36 | -6.02 |
| 0.6 | 完全重调度 | -48.04 | 36 | -14.424 |
| 0.7 | 完全重调度 | -48.04 | 36 | -22.828 |
| 0.8 | 完全重调度 | -48.04 | 36 | -31.232 |
| 0.9 | 完全重调度 | -48.04 | 36 | -39.636 |
| 1.0 | 完全重调度 | -48.04 | 36 | -48.04 |

离散扫描的策略切换点为 `omega1=0.5`：

- `omega1=0` 至 `0.4` 选择局部右移；
- `omega1=0.5` 至 `1.0` 选择完全重调度。

这说明第 12 步结论对当前权重 `0.9/0.1` 成立，但并非对所有决策偏好成立。
越重视机器分配稳定性，越倾向选择局部右移。

## 正式约束与能耗审计

- `all_constraint_audits_validated=true`
- `all_energy_audits_complete=true`
- 两种方案均保持中断工序两段加工承诺；
- 两种方案均未在故障机器维修区间内加工；
- 两种方案均完成全部工件最终卸载；
- 两种方案的机器能耗、AGV 能耗与总能耗均闭合。

| 方案 | 最终卸载 | 机器能耗 | AGV 能耗 | 总能耗 |
|---|---:|---:|---:|---:|
| 局部右移 | 144.2033 | 约 1565.0 | 501.4667 | 约 2066.5 |
| 完全重调度 | 96.1633 | 约 1328.8 | 373.7333 | 约 1702.6 |

当前正式候选中，完全重调度同时降低最终卸载时间和总能耗，但该结论仍需
通过多随机种子检查搜索稳定性。

## 复现正式分析

```matlab
data = load(fullfile(pwd,'outputs', ...
    'stage_b_complete_reschedule_search', ...
    '20260611_100355','result.mat'));
stage12 = run_stage_b_combination_selection(data.scenario);
stage13Analysis = run_stage_b_step_13_analysis(stage12);

stage13Analysis.weight_sensitivity.rows
stage13Analysis.all_constraint_audits_validated
stage13Analysis.all_energy_audits_complete
stage13Analysis.right_shift_audit
stage13Analysis.complete_reschedule_audits
```

## 下一步：多随机种子

正式运行前需确认：

```matlab
stage13Multiseed = run_stage_b_step_13_multiseed(stage12);
```

输出保存到新的相对目录：

```text
outputs/stage_b_step_13_robustness/YYYYMMDD_HHMMSS/
```

保存 `result.mat` 和 `multiseed_summary.csv`，不覆盖已有结果。
