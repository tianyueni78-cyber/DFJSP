# 阶段 C 第 11 步：组合评价与最终审计

## 本步目标

在同一正常基线和同一同时故障事件组上，比较 AGV 联动局部右移与完全重调度
Pareto 候选，计算 `tD、SD、Y`，选择组合指标最小的方案，并审计全部维修
区间、中断承诺、最终卸载和能耗。

## 评价指标

```text
tD = 候选最终卸载完工时间 - 正常基线完工时间
SD = 故障时刻未开工工序中发生机器变化的数量
Y  = 0.9 × tD + 0.1 × SD
```

局部右移保持机器分配，因此 `SD = 0`。完全重调度对 Pareto 前沿中的每个
候选分别计算指标，再与局部右移共同选择最小 `Y`。

## 能耗口径

- 机器能耗按物理加工段重新计算，维修等待不计入工作能耗；
- 局部右移保持 AGV 路线、速度和持续时间，AGV 能耗沿用正常基线；
- 完全重调度使用解码器输出的机器与 AGV 总能耗。

## 代码入口

- 计划评价：`src/evaluation/evaluate_stage_c_rescheduling_plan.m`
- 局部方案能耗：`src/evaluation/evaluate_stage_c_right_shift_energy.m`
- 组合选择：`src/evaluation/select_stage_c_combined_strategy.m`
- 最终审计：`src/evaluation/audit_stage_c_rescheduling_candidate.m`
- 正式结果复用入口：`scripts/run_stage_c_combination_selection.m`
- 轻量契约入口：`scripts/run_stage_c_combination_contract.m`
- 测试：`tests/test_stage_c_combination_contract.m`

轻量契约复用 `6×2` 搜索，不生成输出。正式结果分析应加载第 10.4 步保存的
`result.mat`，再调用组合选择入口，不重新运行正式搜索。
