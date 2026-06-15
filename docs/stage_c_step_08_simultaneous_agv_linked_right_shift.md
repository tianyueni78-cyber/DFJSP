# 阶段 C 第 8 步：同时故障 AGV 与机器联动局部右移

## 本步目标

正式调整第 7 步识别出的运输影响，并将运输延迟反馈至目标工序。机器与 AGV
之间反复传播时间约束，直到两类时间均不再变化。

## 保持不变

- AGV 分配、路线、任务顺序和运输持续时间；
- 机器分配和工序加工时间；
- 故障时刻前已经开始的 AGV 活动；
- 两个中断工序的故障前加工段和修复后续加工段。

## 联动传播

1. 按原 AGV 顺序更新未冻结活动；
2. 负载运输等待前序工序完成；
3. 机器工序等待负载运输到达；
4. 机器工序同时满足工件先后、机器先后和全部维修区间；
5. 重复以上过程直到收敛。

## 验证范围

- 同一 AGV 活动不重叠；
- 负载运输不早于工件可运输时间；
- 工序不早于运输到达；
- 机器加工段不重叠；
- 所有维修区间内无加工；
- 两个中断加工承诺保持不变；
- 每个工件最后工序完成后才执行最终卸载；
- 反转故障输入顺序不改变候选方案。

## 代码入口

- 实现：`src/rescheduling/build_stage_c_simultaneous_agv_linked_right_shift.m`
- 入口：`scripts/run_stage_c_simultaneous_agv_linked_right_shift.m`
- 测试：`tests/test_stage_c_simultaneous_agv_linked_right_shift.m`

```matlab
run(fullfile(pwd,'tests', ...
    'test_stage_c_simultaneous_agv_linked_right_shift.m'))
```

测试通过后进入第 9 步：建立同时故障完全重调度冻结问题。
