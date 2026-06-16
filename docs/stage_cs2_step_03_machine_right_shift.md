# C-S2 第 3 步：从头加工机器局部右移

## 目标

将 C-S2 的从头加工承诺和第 2 步传播得到的受影响工序时间写入候选机器
时间表，生成同时故障从头加工规则下的机器局部右移方案。

本步只调整机器候选表，不调整 AGV，不运行完全重调度搜索。

## 本步写入的内容

对每个被故障直接中断的工序：

1. 写入故障前损失加工段 `lost_processing_before_fault`；
2. 写入修复后完整重加工段 `restart_after_repair`；
3. 将逻辑工序完成时间更新为完整重加工结束时间；
4. 保留机器不迁移；
5. 记录 `restart_from_zero=true`、`progress_preserved=false`。

对受影响的后续工序：

1. 使用第 2 步 `projected_start`；
2. 使用第 2 步 `projected_end`；
3. 保留机器分配不变；
4. 保留影响来源事件。

未受影响工序保持原时间不变。

## 代码入口

- 机器右移：`src/rescheduling/build_stage_cs2_machine_right_shift.m`
- 阶段入口：`scripts/run_stage_cs2_machine_right_shift.m`
- 契约测试：`tests/test_stage_cs2_machine_right_shift.m`

## 完成标准

- 每个中断工序有两个加工段；
- 损失加工段不贡献完工；
- 完整重加工段贡献完工；
- 受影响工序时间与第 2 步投影一致；
- 未受影响工序时间不变；
- 机器加工不重叠；
- 维修区间内故障机器无加工；
- 工件工序顺序成立；
- 原机器表和 AGV 表不被修改。

## 运行方式

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_cs2_machine_right_shift.m'))
```
