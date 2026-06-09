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

阶段 A 第 8.2a 步使用 `rescheduling/`：

- `rescheduling/decode_stage_a_complete_reschedule.m`
- `rescheduling/build_stage_a_baseline_seed_decision.m`

它只解码未开工工序的顺序、候选机器、AGV 和速度决策。当前原染色体仅作为契约测试种子，不代表搜索结果。MATLAB 契约测试已通过。

阶段 A 第 8.2b 步使用 `rescheduling/`：

- `rescheduling/initialize_stage_a_reschedule_population.m`
- `rescheduling/vary_stage_a_reschedule_population.m`

它保留原项目 OS/MS/AS/SS 编码语义及 IPOX、MPX 和变异思想，但只操作未开工工序。首个个体保留原基线种子，其余候选严格从原候选机器、AGV 和速度范围生成。本步不计算适应度，也不运行 NSGA-II。

阶段 A 场景筛选使用 `screening/`：

- `screening/screen_stage_a_fault_scenarios.m`

它遍历原机器时间表中的工序完成时刻，使用当前维修时长和已有影响传播逻辑筛选有效故障候选，不修改配置。
