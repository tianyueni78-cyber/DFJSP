# 阶段 A 第 2 步：定义工序完成时单机器故障事件

## 1. 这一步在项目中的位置

```text
阶段 A：工序完成时单机器故障
├── 第 1 步：建立正常调度基线（已完成）
└── 第 2 步：定义工序完成时单机器故障事件（本步）
```

本步只定义“故障是什么、何时发生、发生在哪台机器”，不提取故障时刻系统状态，也不执行右移或完全重调度。

## 2. 为什么不能直接手写故障时间

阶段 A 要求故障发生在某道工序刚完成时。

如果只手写：

```matlab
fault.machine_id = 3;
fault.start_time = 50;
```

程序无法保证：

- 机器 3 在时刻 50 是否真的刚完成一道工序；
- 时刻 50 是否落在某道工序加工过程中；
- 故障机器和触发工序是否一致；
- 更换正常调度方案后该故障场景是否仍然有效。

因此本步采用：

> 指定正常计划中的工件与工序，由程序从机器时间表查出其实际加工机器和完成时刻。

## 3. 事件如何生成

调用形式：

```matlab
fault = create_completion_fault_event( ...
    baseline, jobId, operationId, repairDuration);
```

程序执行：

```text
读取 baseline.machineTable
→ 唯一查找目标工序
→ 得到该工序所在机器
→ 读取该工序结束时刻
→ 将结束时刻作为故障开始时刻
→ 根据维修时长计算维修结束时刻
→ 校验故障未落在加工区间内部
```

## 4. 故障事件字段

| 字段 | 含义 |
|---|---|
| `event_id` | 故障事件编号 |
| `stage` | 当前研究阶段，固定为 `A` |
| `trigger_type` | 触发类型，固定为 `operation_completion` |
| `machine_id` | 由正常机器时间表查出的故障机器 |
| `start_time` | 目标工序的完成时刻 |
| `repair_duration` | 预计维修时长 |
| `repair_end_time` | 故障结束时刻 |
| `trigger_job` | 触发故障的工件编号 |
| `trigger_operation` | 触发故障的工序编号 |
| `trigger_operation_start` | 触发工序原开始时刻 |
| `trigger_operation_end` | 触发工序原结束时刻 |
| `interrupted_operation` | 阶段 A 固定为空 |
| `is_validated` | 事件是否通过校验 |

## 5. 本步新增内容

### 故障事件模块

- `src/fault/create_completion_fault_event.m`
- `src/fault/validate_completion_fault_event.m`

### 配置

- `configs/stage_a_fault_config.m`

当前默认场景指定：

```matlab
trigger_job = 5;
trigger_operation = 1;
repair_duration = 5;
```

机器编号和故障时刻由正常基线自动确定。

该场景来自原基线候选筛选结果第 1 名。按当前正常基线：

- 触发工序为 `J5-O1`；
- 故障机器为 `M5`；
- 故障时刻为 `6`；
- 同机下一工序为 `J5-O2`；
- 预计传播影响 6 道工序。

### 运行入口

- `scripts/run_stage_a_fault_event.m`

该入口返回：

```matlab
scenario.baseline
scenario.fault
scenario.config
scenario.stage
scenario.is_rescheduled
```

其中 `scenario.is_rescheduled = false`，明确表示本步尚未进行重调度。

### 测试

- `tests/test_completion_fault_event.m`

测试检查：

- 事件字段完整；
- 事件属于阶段 A；
- 故障类型是工序完成触发；
- 故障时刻严格等于触发工序结束时刻；
- 维修结束时刻计算正确；
- 没有在制工序被中断；
- 本步骤没有执行重调度。
- 非正维修时长会被拒绝；
- 落入加工区间内部的故障时刻会被拒绝。

## 6. 校验规则

事件必须满足：

1. 从故障前正常基线创建。
2. 目标工序在机器时间表中恰好出现一次。
3. 故障机器编号有效。
4. 维修时长为正数。
5. `repair_end_time = start_time + repair_duration`。
6. 故障时刻等于目标工序完成时刻。
7. 故障时刻不位于任何工序的开区间 `(start, end)` 内。
8. `interrupted_operation` 为空。

如果另一道工序恰好计划在同一时刻开始，它属于“尚未开始、将受故障影响”的任务，不属于加工中断。

## 7. 本步没有做什么

本步骤没有：

- 判断故障时刻哪些任务已完成或未开始；
- 冻结机器与 AGV 历史任务；
- 建立机器维修不可用区间；
- 传播故障影响；
- 执行二叉树右移；
- 执行完全重调度；
- 修改 AGV 运输；
- 计算 `tD`、`SD` 或 `Y`；
- 修改 `raw_code/`。

## 8. 当前验证状态

已完成：

- 事件数据结构设计；
- 工序到机器与完成时刻的查找逻辑；
- 阶段 A 事件校验逻辑；
- 配置和运行入口；
- MATLAB 测试代码；
- 静态路径和副作用检查；
- MATLAB 运行验证。

当前状态：

> 阶段 A 第 2 步已完成，并通过 MATLAB 测试。

实际测试结果：

```text
test_completion_fault_event passed
```

测试确认：

- 故障事件能够从正常基线成功生成；
- 故障机器与目标工序实际所在机器一致；
- 故障时刻等于目标工序实际完成时刻；
- 非正维修时长会被拒绝；
- 位于加工区间内部的故障时刻会被拒绝；
- 本步骤没有提前执行重调度。

## 9. MATLAB 测试入口

在 MATLAB 当前文件夹为项目根目录时运行：

```matlab
run(fullfile(pwd, 'tests', 'test_completion_fault_event.m'))
```

预期输出：

```text
test_completion_fault_event passed
```

## 10. 下一步

测试通过后进入阶段 A 第 3 步：

> 根据正常基线和故障事件，提取故障时刻已完成工序、已完成运输和未开始任务。
