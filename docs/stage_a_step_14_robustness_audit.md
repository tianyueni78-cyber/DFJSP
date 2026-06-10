# 阶段 A 第 14 步：稳健性与最终约束审计

## 1. 目标

验证第 13 步“选择完全重调度”的结论是否对随机种子和组合权重稳定，并对
部分右移及全部完全重调度 Pareto 候选执行统一约束审计。

## 2. 三部分工作

1. 多随机种子：默认使用 `11、22、33、42、55` 重复同等预算搜索，其中
   `42` 用于复核第 13 步正式搜索结果。
2. 权重敏感性：固定已有候选，将完工时间权重从 `0` 到 `1` 按 `0.1` 扫描。
3. 约束审计：检查算法验证标志、维修区间、最终卸载及能耗一致性。

权重敏感性不重复搜索；多种子属于正式长实验，本次仅实现入口，不自动运行。

约束审计与能耗审计分开报告。候选方案缺少完整能耗字段时，可以保留
“调度约束通过”的结论，但 `energy_audit_complete` 必须为 `false`，不能把
缺失数据视为能耗审计通过。

## 3. 新增代码

- `configs/stage_a_step_14_config.m`
- `src/evaluation/analyze_stage_a_weight_sensitivity.m`
- `src/evaluation/audit_stage_a_rescheduling_candidate.m`
- `scripts/run_stage_a_step_14_analysis.m`
- `scripts/run_stage_a_step_14_multiseed.m`
- `tests/test_stage_a_step_14_contract.m`

## 4. 轻量测试

```matlab
run(fullfile(pwd, 'tests', ...
    'test_stage_a_step_14_contract.m'))
```

## 5. 正式分析

已有第 13 步结果时，可直接执行：

```matlab
stage14Analysis = run_stage_a_step_14_analysis(stage13);
```

多种子实验需要单独确认：

```matlab
stage14Multiseed = run_stage_a_step_14_multiseed(stage12);
```

正式多种子实验保存：

- `result.mat`
- `multiseed_summary.csv`
