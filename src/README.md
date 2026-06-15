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

阶段 C 第 1 步新增：

- `fault/normalize_stage_c_fault_events.m`

它校验并规范化统一 `faults[]` 输入，按故障时间排序、保留原输入顺序，并
为同时故障分配相同事件组。本函数不读取或修改调度计划。

阶段 C 第 2 步新增：

- `fault/build_stage_c_machine_unavailability.m`

它按机器汇总故障事件，合并同机重叠或相接的维修区间，并保留全部来源事件
编号和事件组。本函数不读取机器时间表，不修改调度计划。

阶段 A 第 3 步使用 `state/`：

- `state/extract_stage_a_state.m`

它只读取正常机器和 AGV 时间表，提取故障时刻的状态快照，不生成新调度数据。

阶段 C 第 3 步新增：

- `state/extract_stage_c_event_group_state.m`

它在一个同时故障事件组的时刻分类已完成、正常在制、故障在制和未开工
工序，并分类 AGV 运输状态。函数只读正常基线，不执行影响传播或重调度。

阶段 C 第 4 步新增：

- `screening/screen_stage_c_simultaneous_fault_scenarios.m`

它从原基线动态筛选两台同时在制的机器，并按维修期与原计划相交的工序数等
指标排序候选。本函数只筛选场景，不传播影响，不修改调度。

阶段 C 第 5 步新增：

- `impact/identify_stage_c_simultaneous_affected_operations.m`

它对每个故障根独立传播工件和机器后继延迟，再按工序合并，取最大预计时间
并保留全部来源事件编号。本函数不修改机器或 AGV 时间表。

阶段 C 第 6 步新增：

- `rescheduling/build_stage_c_simultaneous_machine_right_shift.m`

它把两个中断工序分别拆成故障前加工段和修复后续加工段，并将第 5 步合并
后的预计时间写入机器候选表。机器分配不变，AGV 表保持原样。

阶段 C 第 7 步新增：

- `impact/analyze_stage_c_simultaneous_agv_impact.m`

它检查机器候选时间对负载运输和最终卸载的影响，再沿同一 AGV 后续任务
传播待复核范围；运输记录保留全部故障来源，但不修改时间表。

阶段 C 第 8 步新增：

- `rescheduling/build_stage_c_simultaneous_agv_linked_right_shift.m`

它在保留两个中断工序承诺的前提下，迭代传播 AGV 顺序、运输就绪、工序
到达、机器先后和多个维修区间约束，生成完整局部右移候选方案。

阶段 C 第 9 步新增：

- `rescheduling/build_stage_c_simultaneous_frozen_problem.m`

阶段 C 第 10.1 步新增：

- `rescheduling/decode_stage_c_simultaneous_complete_reschedule.m`

该适配器复用阶段 A 共享解码核心，并恢复多个故障在制工序的真实加工时长、
两段加工承诺和故障来源，最后重建机器表并校验全部维修区间。

阶段 C 第 10.3 步新增：

- `rescheduling/evaluate_stage_c_simultaneous_reschedule_candidate.m`
- `rescheduling/search_stage_c_simultaneous_complete_reschedule.m`

评价目标为最终卸载完工时间和总能耗；搜索使用受限 NSGA-II、Pareto 去重和
自适应停止，每个候选均经过阶段 C 多中断解码器。

它冻结已完成、正常在制和多个故障在制承诺，提取未开工工序及原问题候选
机器数据，并建立工件、机器、AGV 和维修资源边界。

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

## 阶段 B 第 5 步

`impact/analyze_stage_b_agv_impact.m`

使用第 4 步逻辑工序新时间检查负载运输出发、到达和最终卸载约束，并将直接
失效运输沿同一 AGV 后续任务传播为待复核集合。本步不修改 AGV 时间表。

## 阶段 B 第 6 步

`rescheduling/build_stage_b_agv_linked_right_shift.m`

迭代传播 AGV 顺序、运输就绪、运输到达、机器顺序和工件顺序约束。阶段 B
中断工序的两个实际加工段固定不变，故障前已开始 AGV 活动被冻结。

## 阶段 B 第 7 步

`rescheduling/build_stage_b_frozen_problem.m`

冻结已完成、在制和中断工序，释放未开工工序与运输，并建立工件、机器和
AGV 边界。中断工序以两段固定承诺保存，不能直接交给阶段 A 解码器。

## 阶段 B 第 8 步

`rescheduling/decode_stage_b_complete_reschedule.m`

复用成熟的未来任务解码核心，并恢复中断工序两段加工、重建机器表和重算
机器能耗，确保维修停机不被当成加工时间。

## 阶段 B 第 9 步

继续复用：

- `rescheduling/initialize_stage_a_reschedule_population.m`
- `rescheduling/vary_stage_a_reschedule_population.m`

这两个算子仅操作未开工工序的 OS/MS/AS/SS 决策，不依赖故障类型。阶段 B
通过专用入口和第 8 步解码器验证全部父代及子代。

## 阶段 B 第 10 步

- `rescheduling/evaluate_stage_b_reschedule_candidate.m`
- `rescheduling/search_stage_b_complete_reschedule.m`

候选评价调用阶段 B 两段加工解码器；NSGA-II 主循环复用阶段 A 已验证的
排序、拥挤距离、选择、Pareto 去重和自适应停止逻辑。

## 阶段 B 第 12 步

- `evaluation/evaluate_stage_b_rescheduling_plan.m`
- `evaluation/select_stage_b_combined_strategy.m`

第一个函数计算最终卸载完工时间偏差 `tD`、未开工工序机器变化数 `SD`
和组合指标 `Y`。第二个函数比较 AGV 联动局部右移与全部完全重调度 Pareto
候选，并按最小 `Y` 选择最终策略。

## 阶段 B 第 13 步

- `evaluation/analyze_stage_b_weight_sensitivity.m`
- `evaluation/audit_stage_b_rescheduling_candidate.m`
- `evaluation/evaluate_stage_b_right_shift_energy.m`

权重扫描只重新计算固定候选的组合指标。阶段 B 审计使用实际
`processing_segments` 检查维修区间和中断工序两段承诺，并按加工段重算
局部右移机器能耗，避免把维修间隔当成加工时间。

## 阶段 B-R 第 1 步

`rescheduling/build_stage_br_restart_operation_plan.m`

将故障前加工段标记为损失加工，并在维修结束后安排完整原加工时间。损失段
实际占用机器和消耗能量，但不贡献工序完成进度。本步不传播后续任务。

## 阶段 B-R 第 2 步

`impact/identify_stage_br_affected_operations.m`

将完整重加工完成时间适配为传播根，复用阶段 B 已验证的工件和机器后继传播
核心。输出记录损失加工语义，但不修改阶段 B 稳定实现或正常基线。

## 阶段 B-R 第 3 步

`rescheduling/build_stage_br_machine_right_shift.m`

将损失加工段、修复后完整重加工段和受影响工序预计时间写入机器候选，并
重建机器时间表。逻辑加工时长保持原值，机器实际加工时间额外包含损失加工。

## 阶段 B-R 第 4 步

`impact/analyze_stage_br_agv_impact.m`

将 B-R 机器候选适配到阶段 B 已验证的运输约束分析核心，识别直接失效和
同一 AGV 后续待复核任务，并保留损失加工和完整重加工语义。

## 阶段 B-R 第 5 步

`rescheduling/build_stage_br_agv_linked_right_shift.m`

保持 AGV 分配、路线、顺序和持续时间不变，正式推迟受影响运输，并把运输
到达延迟反馈至机器工序。中断根始终保留损失加工段和修复后完整重加工段。

## 阶段 B-R 第 6 步

`rescheduling/build_stage_br_frozen_problem.m`

以故障时刻划分冻结和可重调度任务，保存损失加工段与完整重加工段承诺，
并建立工件、机器和 AGV 的完全重调度初始边界。

## 阶段 B-R 第 7 步

`rescheduling/decode_stage_br_complete_reschedule.m`

复用未开工任务调度核心，随后恢复损失加工段与完整重加工段，重建机器表，
并按实际加工段重算机器能耗。

## 阶段 B-R 第 8 步

复用 `rescheduling/initialize_stage_a_reschedule_population.m` 和
`rescheduling/vary_stage_a_reschedule_population.m`。

算子只改变未开工任务的 OS、机器、AGV 和速度决策，不读取或修改从头加工
承诺。每个父代和子代由 B-R 专用解码器验证。

## 阶段 B-R 第 9 步

- `rescheduling/evaluate_stage_br_reschedule_candidate.m`
- `rescheduling/search_stage_br_complete_reschedule.m`

评价器使用最终卸载时间和包含损失加工的总能耗。搜索器执行非支配排序、
拥挤距离、锦标赛、精英保留、Pareto 去重和自适应停止。

## 阶段 B-R 第 11 步

- `evaluation/evaluate_stage_br_rescheduling_plan.m`
- `evaluation/select_stage_br_combined_strategy.m`

计算最终卸载时间偏差 `tD`、未开工工序机器变化数 `SD` 和组合指标 `Y`，
并在局部右移与完全重调度 Pareto 候选中选择最小 `Y`。

## 阶段 B-R 第 12 步

- `evaluation/analyze_stage_br_weight_sensitivity.m`
- `evaluation/audit_stage_br_rescheduling_candidate.m`
- `evaluation/evaluate_stage_br_right_shift_energy.m`

复用第 11 步候选进行权重敏感性，不重新搜索；审计维修区间、损失加工段、
完整重加工段、最终卸载和能耗闭合。损失加工与完整重加工均计入机器工作
能耗，维修停机间隔不计工作能耗。
