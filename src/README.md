# src

当前源码按职责分为：

```text
data/           无副作用的数据读取
scheduling/     正常调度解码与基线包装入口
search/         从原项目迁移的搜索基础函数
visualization/  甘特图等可视化函数
fault/          后续故障事件与状态提取
rescheduling/   后续右移和完全重调度
evaluation/     后续重调度评价指标
```

阶段 A 第 1 步使用：

- `data/read_fjsp.m`
- `data/read_machine_data.m`
- `data/read_agv_data.m`
- `scheduling/build_normal_schedule.m`

`raw_code/` 始终只读。新的入口通过包装函数调用已迁移代码。

阶段 A 第 2 步已开始使用 `fault/`：

- `fault/create_completion_fault_event.m`
- `fault/validate_completion_fault_event.m`

当前只负责工序完成时故障事件的创建和校验。

阶段 A 第 3 步使用 `state/`：

- `state/extract_stage_a_state.m`

它只读取正常机器和 AGV 时间表，提取故障时刻的状态快照，不生成新调度数据。

阶段 A 第 4 步使用 `impact/`：

- `impact/identify_stage_a_affected_operations.m`

它建立维修不可用区间，并沿工件和机器后继关系识别受影响工序。预计时间只用于传播判断，不回写正常基线。

阶段 A 第 5 步使用 `rescheduling/`：

- `rescheduling/build_stage_a_machine_right_shift.m`

它将受影响时间写入机器候选计划，重建机器空闲块并检查机器、工件和维修区间约束。AGV 暂不调整。

阶段 A 第 6 步继续使用 `impact/`：

- `impact/analyze_stage_a_agv_impact.m`

它根据原 AGV 时间表和机器候选时间检查运输约束，只输出需要调整的运输集合，不修改 AGV。

阶段 A 第 7 步使用 `rescheduling/`：

- `rescheduling/build_stage_a_agv_linked_right_shift.m`

它保持原机器、AGV、路线和任务顺序，通过固定点传播同步右移运输与机器工序，并检查机器、工件、AGV 和维修区间约束。

阶段 A 第 8.1 步使用 `rescheduling/`：

- `rescheduling/build_stage_a_frozen_problem.m`

它冻结故障时刻已完成和正在执行的工序，释放未开工工序及其原运输，为完全重调度建立工件、机器和 AGV 边界。
AGV 边界同时从原 `AGVTable` 和 `agvEGRecord` 恢复可用时间、位置、剩余电量、已发生能耗和已完成充电次数。

阶段 A 第 8.2a 步使用 `rescheduling/`：

- `rescheduling/decode_stage_a_complete_reschedule.m`
- `rescheduling/build_stage_a_baseline_seed_decision.m`

它只解码未开工工序的顺序、候选机器、AGV 和速度决策。当前原染色体仅作为契约测试种子，不代表搜索结果。解码器现在还按原规则安排阈值充电和最终卸载，并输出完整完工时间与能耗。MATLAB 原解码契约测试已通过，8.2d 扩展后需要回归。

阶段 A 第 8.2b 步使用 `rescheduling/`：

- `rescheduling/initialize_stage_a_reschedule_population.m`
- `rescheduling/vary_stage_a_reschedule_population.m`

它保留原项目 OS/MS/AS/SS 编码语义及 IPOX、MPX 和变异思想，但只操作未开工工序。首个个体保留原基线种子，其余候选严格从原候选机器、AGV 和速度范围生成。本步不计算适应度，也不运行 NSGA-II。

阶段 A 第 8.2c 步使用 `rescheduling/`：

- `rescheduling/evaluate_stage_a_reschedule_candidate.m`
- `rescheduling/search_stage_a_complete_reschedule.m`

它将第 8.2a 解码器和第 8.2b 算子连接为受限 NSGA-II 主循环。评价目标已恢复为最终卸载完工时间和机器与 AGV 总能耗。轻量入口只验证搜索契约，不作为正式实验。

阶段 A 第 8.2d 步继续使用 `rescheduling/`：

- `rescheduling/build_stage_a_frozen_problem.m`
- `rescheduling/decode_stage_a_complete_reschedule.m`

并新增：

- `scripts/run_stage_a_complete_energy_contract.m`

它从原基线恢复故障边界电量，按原 `sorting.m` 规则检查阈值充电，在每个工件最后工序完成时安排最早可用 AGV 卸载，并按原 `fitness.m` 口径计算机器能耗、AGV 能耗和总能耗。

阶段 A 场景筛选使用 `screening/`：

- `screening/screen_stage_a_fault_scenarios.m`

它遍历原机器时间表中的工序完成时刻，使用当前维修时长和已有影响传播逻辑筛选有效故障候选，不修改配置。

阶段 A 第 9 步评价与组合选择使用 `evaluation/`：

- `evaluation/evaluate_stage_a_rescheduling_plan.m`
- `evaluation/select_stage_a_combined_strategy.m`

它统一计算部分右移方案和完全重调度 Pareto 候选的最终卸载完工时间偏差 `tD`、未开工工序机器变化数 `SD` 和加权指标 `Y`，并选择 `Y` 最小的最终方案。

阶段 A 第 10 步同等预算正常基线搜索使用 `search/`：

- `search/build_normal_search_problem.m`
- `search/chromosome_to_full_decision.m`
- `search/full_decision_to_chromosome.m`
- `search/search_normal_schedule.m`

它复用原项目正常调度解码器与受限搜索算子，只在原 `Mk02.fjs`、
原候选机器、原 AGV 和原速度范围中生成候选。用户已允许基于原数据生成
优化候选方案，但不允许生成替代问题数据。

阶段 A 第 11 步继续使用 `screening/`：

- `screening/screen_stage_a_fault_scenarios.m`

筛选器现在可接收可选的基线来源标签。旧入口仍默认为
`original_baseline`；第 11 步传入 `optimized_normal_baseline`。筛选规则、
影响传播和候选排序均未改变。

阶段 A 第 12 步不修改 `src/` 核心算法。它通过脚本编排复用：

- `state/extract_stage_a_state.m`
- `impact/identify_stage_a_affected_operations.m`
- `rescheduling/build_stage_a_machine_right_shift.m`
- `impact/analyze_stage_a_agv_impact.m`
- `rescheduling/build_stage_a_agv_linked_right_shift.m`
- `rescheduling/build_stage_a_frozen_problem.m`

各模块必须共享第 10 步优化基线和第 11 步选定故障。

阶段 A 第 14 步在 `evaluation/` 新增：

- `analyze_stage_a_weight_sensitivity.m`
- `audit_stage_a_rescheduling_candidate.m`
- `evaluate_stage_a_right_shift_energy.m`

前者固定候选重新计算组合权重，后者汇总候选已有验证标志并独立检查维修
区间、最终卸载和能耗一致性。右移能耗函数按右移后的工序时间重新计算
机器能耗；在路线和运输时长均已验证保持不变时，AGV 能耗沿用正常基线。

## 阶段 B 第 1 步

`fault/` 新增：

- `create_processing_fault_event.m`
- `validate_processing_fault_event.m`

`state/` 新增：

- `extract_stage_b_interrupted_state.m`

本步只建立加工中故障事件和在制工序状态，不修改阶段 A 的右移、解码和
搜索模块。

## 阶段 B 第 2 步

`rescheduling/build_stage_b_resume_operation_plan.m`

将中断工序拆分为故障前已加工段和修复后剩余加工段。它只建立恢复计划，
不修改完整机器时间表，不传播后续任务。

## 阶段 B 第 3 步

`impact/identify_stage_b_affected_operations.m`

将中断工序作为独立传播根，按其新完成时间驱动同工件后继和同机器后继，
再迭代传播全部时间冲突。函数只生成影响集合和预计时间。

## 阶段 B 第 4 步

`rescheduling/build_stage_b_machine_right_shift.m`

把第 3 步预计时间写入机器候选计划。中断工序在逻辑上保留为一道工序，
在机器占用上拆成故障前和修复后两个加工段。本步复制但不调整 AGV 时间表。
