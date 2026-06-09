# 阶段 A 第 4 步：维修区间与受影响工序识别

## 1. 工作表位置

```text
阶段 A：工序完成时单机器故障
├── 第 1 步：建立正常调度基线（已完成）
├── 第 2 步：定义工序完成时故障事件（已完成）
├── 第 3 步：提取故障时刻系统状态（已完成）
└── 第 4 步：建立维修区间并识别受影响工序（本步）
```

本步只回答“哪些未开始工序会受到故障影响”，不把任何预计时间写回正常计划。

## 2. 数据来源

本步没有生成新调度数据，输入全部来自前序步骤：

```text
原项目数据
→ 正常基线
→ 阶段 A 故障事件
→ 故障时刻状态快照
→ 本步影响识别
```

分析对象只包括 `state.unstarted_operations`。

## 3. 维修不可用区间

故障机器在以下半开区间内不可加工：

```text
[fault.start_time, fault.repair_end_time)
```

维修结束时刻机器重新可用。

输出字段：

```matlab
impact.unavailable_interval.machine_id
impact.unavailable_interval.start_time
impact.unavailable_interval.end_time
impact.unavailable_interval.interval_type
```

## 4. 直接受影响工序

未开始工序同时满足以下条件时，与维修区间直接冲突：

```text
operation.machine_id == fault.machine_id
operation.original_start < fault.repair_end_time
fault.start_time < operation.original_end
```

直接冲突工序的预计最早开始时刻至少为维修结束时刻。

## 5. 影响传播

从直接冲突工序开始，按两类后继关系传播：

1. 同一工件的下一道工序，即论文中的左分支。
2. 同一机器原加工序列中的下一道工序，即论文中的右分支。

只有当前受影响工序的预计完成时刻晚于后继工序原开始时刻时，后继工序才进入影响集合。传播持续到不再产生新延迟。

这实现了“由时间冲突决定局部范围”，不会把所有后续工序一概标记为受影响。

## 6. 预计时间的含义

每个受影响工序保存：

- `original_start`
- `original_end`
- `projected_start`
- `projected_end`
- `projected_delay`
- `direct_repair_conflict`
- `job_precedence_conflict`
- `machine_sequence_conflict`

`projected_*` 仅用于识别影响范围。本步：

- 不修改 `baseline.machineTable`；
- 不更新 AGV 时间表；
- 不生成右移后的正式调度方案。

## 7. 新增文件

- `src/impact/identify_stage_a_affected_operations.m`
- `scripts/run_stage_a_impact_analysis.m`
- `tests/test_stage_a_impact_analysis.m`

运行入口增加：

```matlab
scenario.impact
scenario.is_impact_identified
scenario.is_rescheduled
```

## 8. 输出集合

```matlab
impact.directly_affected_operations
impact.affected_operations
impact.unaffected_unstarted_operations
impact.counts
```

受影响集合与未受影响集合必须完整划分第 3 步的全部未开始工序。

## 9. 当前验证状态

已完成：

- 维修不可用区间结构；
- 直接维修冲突识别；
- 工件后继传播；
- 机器后继传播；
- 传播收敛保护；
- 影响集合完整性检查；
- 基线不修改检查；
- 使用原项目数据的 MATLAB 测试代码；
- 静态路径与副作用检查。

尚未完成：

- MATLAB 运行验证。

当前状态：

> 阶段 A 第 4 步代码与静态检查完成，MATLAB 测试待执行。

## 10. MATLAB 测试

```matlab
run(fullfile(pwd, 'tests', 'test_stage_a_impact_analysis.m'))
```

预期输出：

```text
test_stage_a_impact_analysis passed
```

## 11. 本步没有做什么

本步没有：

- 修改原任务开始或完成时刻；
- 修改 `raw_code/`；
- 执行正式部分右移；
- 重新生成 AGV 运输；
- 执行完全重调度；
- 计算 `tD`、`SD` 或 `Y`。

## 12. 下一步

测试通过后，下一步才根据本步的受影响集合生成正式部分右移候选计划，并检查机器、工件和 AGV 约束。
