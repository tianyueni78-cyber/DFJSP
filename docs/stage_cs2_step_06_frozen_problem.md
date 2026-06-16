# C-S2 第 6 步：从头加工完全重调度冻结问题

## 目标

在 C-S2 局部右移链路通过机器与 AGV 联动约束后，建立完全重调度候选
需要使用的冻结问题边界。

本步只定义搜索边界，不运行完全重调度搜索。

## 冻结内容

冻结以下对象：

1. 故障时刻前已完成工序；
2. 故障时刻正在正常加工且未受故障中断的工序；
3. 被故障中断并承诺从头加工的工序；
4. 已完成或正在执行的 AGV 运输；
5. 故障机器维修区间；
6. 各工件、机器和 AGV 在故障时刻后的可用边界。

## C-S2 特有规则

每个中断工序保存为固定承诺：

- `rule = restart_from_zero`；
- `restart_from_zero = true`；
- `progress_preserved = false`；
- 保留 `lost_processing_segment`；
- 保留 `restart_segment`；
- 不允许中断工序迁移机器。

## 代码入口

- 冻结问题：`src/rescheduling/build_stage_cs2_frozen_problem.m`
- 阶段入口：`scripts/run_stage_cs2_frozen_problem.m`
- 契约测试：`tests/test_stage_cs2_frozen_problem.m`

## 完成标准

- 冻结工序 + 可重调工序 = 原全部工序；
- 可重调工序数等于故障时刻未开工工序数；
- 多个中断工序均保存从头加工承诺；
- 工件边界、机器边界和 AGV 边界有效；
- 运输集合满足“已完成 + 在执行 + 未开始 = 原全部运输”；
- 不执行搜索，不修改原始基线。

## 运行方式

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_cs2_frozen_problem.m'))
```
