# C-S2 第 5 步：从头加工 AGV 与机器联动右移

## 目标

在 C-S2 第 4 步 AGV 影响分析的基础上，正式调整受影响 AGV 运输任务，
并将运输延迟反馈到目标工序开工时间，形成同时故障从头加工规则下的
机器 + AGV 联动局部右移候选方案。

本步仍不运行完全重调度搜索。

## 实现思路

C-S2 复用阶段 C 同时故障 AGV 联动核心：

1. 将 C-S2 的 `lost_processing_segment` 映射为核心所需的
   `completed_segment`；
2. 将 C-S2 的 `restart_segment` 映射为核心所需的 `resumed_segment`；
3. 调用 `build_stage_c_simultaneous_agv_linked_right_shift`；
4. 将输出恢复为 `stage = C-S2`、`step = 5`；
5. 重新保留 `restart_from_zero = true` 和 `progress_preserved = false`。

这样 AGV 约束判断和阶段 C 主链路保持同一口径。

## 约束检查

- 机器加工段不重叠；
- 故障维修区间内不加工；
- 工件工序顺序不逆转；
- 负载运输必须在加工前到达；
- 负载运输必须等待前序工序完成；
- 同一 AGV 任务不重叠；
- 已冻结 AGV 任务不改变；
- 从头加工的损失段和完整重加工段不被 AGV 反馈修改。

## 代码入口

- AGV 联动右移：`src/rescheduling/build_stage_cs2_agv_linked_right_shift.m`
- 阶段入口：`scripts/run_stage_cs2_agv_linked_right_shift.m`
- 契约测试：`tests/test_stage_cs2_agv_linked_right_shift.m`

## 完成标准

- 能生成 `cs2_linked_right_shift`；
- 候选方案通过机器、工件、AGV、维修和最终卸载约束；
- 从头加工规则保持成立；
- AGV 分配、路线和持续时间不变；
- 如第 4 步要求 AGV 调整，则候选方案标记 `is_agv_updated = true`。

## 运行方式

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_cs2_agv_linked_right_shift.m'))
```
