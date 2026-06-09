# 阶段 A 第 5 步：生成机器部分右移候选方案

## 1. 工作表位置

```text
阶段 A：工序完成时单机器故障
├── 第 1 步：正常调度基线
├── 第 2 步：故障事件
├── 第 3 步：故障时刻状态
├── 第 4 步：维修区间与影响识别
└── 第 5 步：机器部分右移候选方案（本步）
```

本步正式生成右移后的机器工序时间表，但暂不调整 AGV。

当前已确认使用原基线筛选候选第 1 名：`J5-O1` 完成时 `M5` 故障，故障时刻为 `6`，维修时长为 `5`。筛选结果预计传播影响 6 道工序、最大预计延迟为 `5`。该结果仍需通过本步骤回归测试确认。

## 2. 输入与数据来源

本步不创建人工工序数据，输入来自：

- `baseline.machineTable`
- `baseline.AGVTable`
- `fault`
- `state`
- `impact.affected_operations`

第 4 步给出的 `projected_start` 和 `projected_end` 在本步成为受影响工序的正式候选时间。

## 3. 机器右移规则

本步保持：

- 工序数量不变；
- 工件工艺顺序不变；
- 每道工序的加工机器不变；
- 每道工序的加工时长不变；
- 未受影响工序的开始和结束时间不变。

只将受影响工序更新为：

```text
start = projected_start
end   = projected_end
```

## 4. 为什么重新构造机器时间表

原 `machineTable` 同时包含真实加工块和空闲块。

受影响加工块右移后，旧空闲块的边界已经失效。若只修改加工块，会产生错误空隙或时间重叠。因此本步：

1. 从正常基线提取全部真实加工块；
2. 更新受影响工序时间；
3. 按机器和新开始时间重新排序；
4. 根据真实加工块重新生成空闲块；
5. 为每台机器保留末尾无限空闲块。

这只是重建同一批工序的机器时间表，不是生成新的工序数据。

## 5. 机器方案校验

候选方案必须满足：

1. 所有原工序仍恰好存在一次。
2. 机器分配没有改变。
3. 加工时长没有改变。
4. 未受影响工序时间没有改变。
5. 受影响工序采用第 4 步预计时间。
6. 同一机器上的加工块不重叠。
7. 机器时间表从零开始、块间连续并以无限空闲块结束。
8. 工件前序工序不晚于后序工序开始。
9. 故障机器在维修区间内没有加工块。

## 6. AGV 边界

本步按用户要求不调整 AGV：

```matlab
candidate.AGVTable = baseline.AGVTable;
candidate.is_agv_updated = false;
candidate.is_agv_validated = false;
candidate.is_fully_validated = false;
```

因此当前候选方案只完成机器层验证，不能宣称为完整 FJSP-AGV 可行方案。

## 7. 新增文件

- `src/rescheduling/build_stage_a_machine_right_shift.m`
- `scripts/run_stage_a_machine_right_shift.m`
- `tests/test_stage_a_machine_right_shift.m`

主要输出：

```matlab
scenario.right_shift.machineTable
scenario.right_shift.AGVTable
scenario.right_shift.operation_records
scenario.right_shift.machine_makespan
scenario.right_shift.validation
```

## 8. 当前验证状态

已完成：

- 受影响时间写入候选副本；
- 未受影响任务冻结；
- 机器时间表空闲块重建；
- 机器分配和时长保持检查；
- 机器不重叠检查；
- 工件工艺顺序检查；
- 维修区间检查；
- 零影响场景检查：若原故障配置没有影响后续工序，候选工序时间必须全部保持原样；
- AGV 未调整状态标记；
- 使用原项目数据的 MATLAB 测试代码；
- 静态副作用检查。

尚未完成：

- MATLAB 运行验证；
- AGV 联动调整和验证。

当前状态：

> 阶段 A 第 5 步机器右移代码与静态检查完成，MATLAB 测试待执行。

## 9. MATLAB 测试

```matlab
run(fullfile(pwd, 'tests', 'test_stage_a_machine_right_shift.m'))
```

预期输出：

```text
test_stage_a_machine_right_shift passed
```

## 10. 本步没有做什么

本步没有：

- 修改正常基线对象；
- 修改 `raw_code/`；
- 调整 AGV 任务时间；
- 重新分配 AGV 或速度；
- 检查加工开始是否晚于运输到达；
- 计算 AGV 冲突、电量或能耗；
- 实现完全重调度；
- 计算组合评价指标。

## 11. 下一步

测试通过后，需要检查机器右移造成哪些运输到达时间失效，再按原项目运输规则联动调整相关 AGV 任务。
