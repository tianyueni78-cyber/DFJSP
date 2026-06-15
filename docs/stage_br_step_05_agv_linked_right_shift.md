# 阶段 B-R 第 5 步：AGV 与机器联动调整

## 目标

在第 3 步机器候选和第 4 步运输影响集合基础上，正式调整 AGV 时间，并将
运输延迟反馈到机器工序，形成从头加工规则下完整可行的局部右移候选。

本步不改变机器分配、AGV 分配、运输路线、任务顺序和活动持续时间。

## 联动规则

1. 故障时刻前已开始的 AGV 活动冻结；
2. 未冻结活动不得早于原开始时间；
3. 同一 AGV 按原任务顺序依次安排，前一活动结束后才能开始下一活动；
4. 负载运输必须等待对应工件就绪；
5. 负载运输到达后，目标工序才能开始；
6. 运输造成的工序延迟继续沿机器顺序和工件顺序传播；
7. 传播迭代至机器和 AGV 时间均不再变化。

## 从头加工语义

中断工序保持两个固定实际加工段：

- 故障前加工段为损失加工，不贡献工序完成进度；
- 维修结束后在原机器重新执行完整原加工时间；
- 两段实际加工时间之和等于损失时间加原加工时间；
- AGV 反馈不得改变这两个加工段。

## 约束检查

- 机器加工段不重叠；
- 故障机器在维修区间内不加工；
- 工件工序优先关系成立；
- 运输到达不晚于目标工序开始；
- 负载运输不早于工件就绪；
- 同一 AGV 活动不重叠；
- 冻结 AGV 活动不变；
- AGV 分配、路线和持续时间不变；
- 损失加工段和完整重加工段均被保留。

## 代码入口

- 联动构建器：
  [`build_stage_br_agv_linked_right_shift.m`](../src/rescheduling/build_stage_br_agv_linked_right_shift.m)
- 运行入口：
  [`run_stage_br_agv_linked_right_shift.m`](../scripts/run_stage_br_agv_linked_right_shift.m)
- 轻量测试：
  [`test_stage_br_agv_linked_right_shift.m`](../tests/test_stage_br_agv_linked_right_shift.m)

## 轻量测试

```matlab
run(fullfile(pwd,'tests','test_stage_br_agv_linked_right_shift.m'))
```

## 下一步

测试通过后进入阶段 B-R 第 6 步：建立从头加工规则下的完全重调度冻结问题。
