# 阶段 B 第 6 步：AGV 与机器联动局部右移

## 本步目标

正式调整第 5 步识别出的 AGV 运输，并把运输延迟反馈给目标工序和机器后续
工序，生成加工中故障场景下完整可行的局部右移候选。

## 保持不变的内容

- 工序机器分配；
- AGV 分配、路线和任务顺序；
- 工序有效加工时长；
- AGV 活动持续时间；
- 中断工序故障前已加工段和修复后续加工段；
- 故障时刻前已经开始的 AGV 活动。

## 联动传播

1. 负载运输必须等待前序工序完成；
2. 同一 AGV 后续活动必须等待前一活动结束；
3. 目标工序必须等待负载运输到达；
4. 同机后续工序必须等待机器释放；
5. 同工件后续工序必须等待前序工序完成；
6. 上述时间变化迭代传播，直到机器和 AGV 时间都不再变化。

## 阶段 B 特殊处理

中断工序不是一段连续加工。联动过程中它始终保留：

- 故障前已加工段；
- 维修不可用区间；
- 修复后剩余加工段。

AGV 反馈不能移动或合并这两个加工段，只能影响它之后的任务。故障发生时
已经开始执行的 AGV 活动也保持原计划至完成。

## 代码入口

- 构建函数：
  [`build_stage_b_agv_linked_right_shift.m`](../src/rescheduling/build_stage_b_agv_linked_right_shift.m)
- 运行入口：
  [`run_stage_b_agv_linked_right_shift.m`](../scripts/run_stage_b_agv_linked_right_shift.m)
- 轻量测试：
  [`test_stage_b_agv_linked_right_shift.m`](../tests/test_stage_b_agv_linked_right_shift.m)

## MATLAB 轻量测试

```matlab
run(fullfile(pwd,'tests','test_stage_b_agv_linked_right_shift.m'))
```

本步不改变问题数据，也不运行完全重调度搜索。
