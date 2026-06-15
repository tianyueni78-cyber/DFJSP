# 阶段 C 第 3 步：多故障事件组状态快照

## 本步目标

从原项目正常机器与 AGV 调度基线中，在一个同时故障事件组的发生时刻提取
只读状态快照。本步不修改计划，不传播故障影响。

## 工序分类

每道真实工序恰好属于以下一类：

- `completed_operations`：结束时间不晚于故障时刻；
- `normal_in_progress_operations`：故障时刻正在正常机器加工；
- `fault_in_progress_operations`：故障时刻正在故障机器加工；
- `unstarted_operations`：开始时间不早于故障时刻。

故障在制工序额外记录：

- 原加工时长；
- 已加工时间；
- 剩余加工时间；
- 加工进度比例；
- 对应的故障事件编号；
- 事件指定的中断规则。

本步只记录规则，不执行续加工或从头加工。

## AGV 分类

原 AGV 运输任务分类为：

- `completed_transports`；
- `in_progress_transports`；
- `unstarted_transports`。

`active_agv_ids` 列出故障时刻正在执行运输任务的 AGV。空闲块、充电块和
非工件运输记录不进入这三个任务集合。

## 测试数据来源

测试直接运行原项目正常基线，并动态寻找至少两台机器同时加工的时刻。测试
随后把这两台机器设为同一时刻故障。工序、机器和 AGV 数据全部来自原项目；
只新增故障实验参数，不生成新的生产问题数据。

## 代码入口

- 实现：`src/state/extract_stage_c_event_group_state.m`
- 测试：`tests/test_stage_c_event_group_state.m`

```matlab
run(fullfile(pwd,'tests','test_stage_c_event_group_state.m'))
```

## 完成标准

- 每道工序恰好进入一个状态类别；
- 每台故障机器上的在制工序被识别并关联故障事件；
- 正常机器在制工序与故障在制工序分开；
- AGV 已完成、在执行和未开始运输被正确分类；
- 状态快照不修改正常基线，不执行重调度。
