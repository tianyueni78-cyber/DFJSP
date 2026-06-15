# 阶段 C 第 6 步：同时故障机器局部右移

## 本步目标

把第 5 步合并后的预计时间正式写入机器候选计划，同时处理两个故障在制
工序的恢复加工。本步只调整机器时间表，不调整 AGV 时间表。

## 中断工序规则

第一版同时故障继续采用阶段 B 已验证的保留进度规则：

```text
故障前已加工段 = [original_start, fault_time]
修复后续加工段 = [repair_end_time,
                    repair_end_time + remaining_processing_time]
```

每个中断工序仍是一道逻辑工序，但在机器占用表中表示为两个加工段。

## 未开工工序

- 使用第 5 步的 `projected_start` 和 `projected_end`；
- 机器分配和加工时长不变；
- 多故障来源保存在 `source_event_ids`；
- 未进入影响集合的工序保持原计划。

## 验证范围

- 两个维修区间内均无机器加工；
- 同一机器加工段不重叠；
- 工件工序先后关系成立；
- 中断工序加工时间守恒；
- 未受影响工序不变；
- 原机器表和 AGV 表不被覆盖；
- 候选 AGV 表仍为原表，尚未验证机器与运输联动。

## 代码入口

- 实现：`src/rescheduling/build_stage_c_simultaneous_machine_right_shift.m`
- 场景入口：`scripts/run_stage_c_simultaneous_machine_right_shift.m`
- 测试：`tests/test_stage_c_simultaneous_machine_right_shift.m`

```matlab
run(fullfile(pwd,'tests', ...
    'test_stage_c_simultaneous_machine_right_shift.m'))
```

测试通过后进入第 7 步：分析机器时间变化对 AGV 运输约束的影响。
