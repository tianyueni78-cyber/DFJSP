# 阶段 B-R 第 6 步：完全重调度冻结问题

## 目标

以故障时刻为边界，把不可修改的历史状态与可重新调度的未来任务分开，为
从头加工规则下的完全重调度建立输入契约。

本步只建立冻结问题，不解码候选、不运行搜索、不生成正式实验输出。

## 冻结范围

- 故障时刻前已经完成的工序；
- 故障时刻正在其他机器加工的工序；
- 故障机器上的中断工序；
- 故障时刻前已完成的运输；
- 故障时刻正在执行的运输。

只有故障时刻尚未开工的工序和运输被释放给后续完全重调度。

## 中断工序承诺

中断工序冻结为一个逻辑工序，同时保存两个不可修改的实际加工段：

1. 故障前损失加工段；
2. 维修结束后的完整重加工段。

其中：

- `progress_preserved = false`；
- `restart_from_zero = true`；
- 逻辑有效加工时长等于原加工时长；
- 机器实际加工时间等于损失加工时间加原加工时长；
- 不允许迁移中断工序所在机器。

## 边界信息

- 工件边界：已冻结工序前缀、释放时间和当前位置；
- 机器边界：故障时刻后的最早可用时间和维修约束；
- AGV 边界：可用时间、位置、电量、累计耗电和充电次数；
- 可重调度工序：原机器、原时间、候选机器及对应加工时间。

## 解码要求

后续解码器必须使用：

`stage_br_restart_operation_decoder`

阶段 A 解码器和阶段 B 续加工解码器均不能直接处理本冻结问题。

## 代码入口

- 冻结构建器：
  [`build_stage_br_frozen_problem.m`](../src/rescheduling/build_stage_br_frozen_problem.m)
- 运行入口：
  [`run_stage_br_frozen_problem.m`](../scripts/run_stage_br_frozen_problem.m)
- 轻量测试：
  [`test_stage_br_frozen_problem.m`](../tests/test_stage_br_frozen_problem.m)

## 轻量测试

```matlab
run(fullfile(pwd,'tests','test_stage_br_frozen_problem.m'))
```

## 下一步

测试通过后进入阶段 B-R 第 7 步：实现支持损失加工段和完整重加工承诺的
完全重调度解码器。
