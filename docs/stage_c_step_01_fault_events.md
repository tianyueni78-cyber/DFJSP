# 阶段 C 第 1 步：统一多故障事件输入

## 本步目标

为单故障、同时故障和连续故障建立统一 `faults[]` 输入契约。本步只处理
事件数据，不提取调度状态、不建立维修区间、不运行重调度算法。

## 输入字段

每个原始事件必须包含：

```matlab
event_id
machine_id
start_time
repair_duration
interruption_rule
```

允许的中断规则：

- `resume_remaining`：保留进度，修复后继续剩余加工；
- `restart_from_zero`：进度作废，修复后从头加工。

若输入带 `repair_end_time`，必须满足：

```text
repair_end_time = start_time + repair_duration
```

## 标准化输出

`normalize_stage_c_fault_events` 增加并保证：

- `stage = 'C'`；
- `trigger_type = 'machine_failure'`；
- 自动计算 `repair_end_time`；
- 按 `start_time` 稳定排序；
- 使用 `source_order` 保留原输入位置；
- 同时发生的事件使用相同 `event_group`；
- 每个 `event_id` 唯一；
- `is_validated = true`。

## 轻量测试数据说明

测试中使用三个最小故障参数记录，仅验证排序、同时故障分组和非法输入。
这些记录不是新的生产问题数据，不包含工件、加工时间、机器能力或 AGV
数据，也不会进入正式实验。

## 代码入口

- 实现：`src/fault/normalize_stage_c_fault_events.m`
- 测试：`tests/test_stage_c_fault_events.m`

测试命令：

```matlab
run(fullfile(pwd,'tests','test_stage_c_fault_events.m'))
```

## 完成标准

- 单故障、同时故障和连续故障可使用同一结构体数组；
- 非法机器、重复事件编号、非法规则和错误维修结束时间会被拒绝；
- 相同故障时刻得到相同 `event_group`；
- 排序后仍能通过 `source_order` 追踪原输入；
- 不修改 A/B/B-R 的单故障代码。
