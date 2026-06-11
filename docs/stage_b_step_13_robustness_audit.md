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

## 复用正式第 12 步结果

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

## 多随机种子入口

正式运行前需确认：

```matlab
stage13Multiseed = run_stage_b_step_13_multiseed(stage12);
```

输出保存到新的相对目录：

```text
outputs/stage_b_step_13_robustness/YYYYMMDD_HHMMSS/
```

保存 `result.mat` 和 `multiseed_summary.csv`，不覆盖已有结果。
