# 阶段 C 第 16.5 步：连续故障组合评价

## 本步目标

将连续故障局部右移方案与完全重调度 Pareto 候选放到同一评价框架中：

1. 以当前计划 `V1` 的完工时间作为比较基线；
2. 计算局部右移和完全重调度候选的 `tD、SD、Y`；
3. 对局部右移方案补充可比较的机器能耗和 AGV 能耗；
4. 审计维修区间、中断承诺、最终卸载和能耗闭合；
5. 选择 `Y` 最小的连续故障最终策略。

## 代码入口

- 组合入口：`scripts/run_stage_c_sequential_combination_selection.m`
- 契约测试：`tests/test_stage_c_sequential_combination_contract.m`
- 复用评价器：
  - `src/evaluation/evaluate_stage_c_rescheduling_plan.m`
  - `src/evaluation/evaluate_stage_c_right_shift_energy.m`
  - `src/evaluation/select_stage_c_combined_strategy.m`
  - `src/evaluation/audit_stage_c_rescheduling_candidate.m`

## 当前边界

契约测试复用第 16.3 步轻量搜索结果，不运行正式搜索、不生成输出。正式结果
分析时应加载第 16.4 步已保存的 `result.mat`。
