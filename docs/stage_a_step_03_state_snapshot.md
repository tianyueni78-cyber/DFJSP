# 阶段 A 第 3 步：提取故障时刻系统状态

## 1. 工作表位置

```text
阶段 A：工序完成时单机器故障
├── 第 1 步：建立正常调度基线（已完成）
├── 第 2 步：定义工序完成时故障事件（已完成）
└── 第 3 步：提取故障时刻系统状态（本步）
```

本步把正常基线中的机器任务和 AGV 运输，按照故障时刻划分为已完成、进行中和未开始集合。它只形成状态快照，不改变原计划，也不执行重调度。

## 2. 数据来源

本步没有生成新的工序、运输、机器或 AGV 数据。

全部数据来自原项目：

- FJSP 实例：`raw_code/fjsp/Brandimarte_Data/Mk02.fjs`
- 机器距离与能耗：`raw_code/机器数据.xlsx`
- AGV 数量、速度与能耗：`raw_code/AGV数据.xlsx`
- 正常基线随机种子：`42`

执行链为：

```text
原项目数据
→ run_normal_schedule_baseline()
→ baseline.machineTable / baseline.AGVTable
→ run_stage_a_fault_event()
→ fault.start_time
→ extract_stage_a_state()
```

测试也直接使用这条数据链，不包含人工生成的调度样例。

## 3. 分类边界

设故障时刻为 `tf`。

| 时间关系 | 状态 |
|---|---|
| `end <= tf` | 已完成 |
| `start < tf < end` | 进行中 |
| `start >= tf` | 未开始 |

因此：

- 恰好在 `tf` 完成的触发工序属于已完成；
- 恰好在 `tf` 开始的任务属于未开始；
- 其他机器和 AGV 在 `tf` 时正在执行的任务被单独保留，不能在后续局部修复中随意修改。

## 4. 提取内容

### 机器工序

只统计 `job > 0`、`opera > 0` 的真实加工块，排除机器空闲块。

- `completed_operations`
- `in_progress_operations`
- `unstarted_operations`

每条记录保留机器编号、原时间表位置、工件、工序、开始时间和结束时间。

### AGV 运输

只统计与工件关联、未标记为充电且 `load_status` 为 `-1` 或 `-2` 的移动记录：

- `-1`：空载移动；
- `-2`：负载运输。

排除：

- AGV 空闲块；
- 充电块；
- 与具体工件无关的前往充电移动。

输出：

- `completed_transports`
- `in_progress_transports`
- `unstarted_transports`

## 5. 新增文件

- `src/state/extract_stage_a_state.m`
- `scripts/run_stage_a_state_snapshot.m`
- `tests/test_stage_a_state_snapshot.m`

运行入口返回：

```matlab
scenario.baseline
scenario.fault
scenario.state
scenario.is_state_extracted
scenario.is_rescheduled
```

其中 `scenario.is_rescheduled = false`。

## 6. 校验规则

状态快照必须满足：

1. 基线是无故障正常计划。
2. 故障是已经校验的阶段 A 工序完成时事件。
3. 每道真实工序恰好进入一个状态集合。
4. 三个工序集合总数等于实例定义的总工序数。
5. 触发故障的工序必须属于已完成集合。
6. 空闲块和无限结束时间块不得进入任务集合。
7. 本步骤不得修改基线或执行重调度。

## 7. 当前验证状态

已完成：

- 原始时间表字段静态分析；
- 机器工序分类逻辑；
- AGV 运输筛选和分类逻辑；
- 状态计数和完整性校验；
- 独立运行入口；
- 使用原项目数据的 MATLAB 测试代码；
- 相对路径和无文件输出检查。

尚未完成：

- MATLAB 运行验证。

当前状态：

> 阶段 A 第 3 步代码与静态检查完成，MATLAB 测试待执行。

## 8. MATLAB 测试

在项目根目录运行：

```matlab
run(fullfile(pwd, 'tests', 'test_stage_a_state_snapshot.m'))
```

预期输出：

```text
test_stage_a_state_snapshot passed
```

## 9. 本步没有做什么

本步没有：

- 创建人工调度数据；
- 修改 `raw_code/`；
- 设置维修不可用区间；
- 传播故障影响；
- 执行二叉树右移；
- 执行完全重调度；
- 重新生成 AGV 运输；
- 计算 `tD`、`SD` 或 `Y`。

## 10. 下一步

测试通过后进入阶段 A 第 4 步：基于本状态快照建立故障机器维修不可用区间，并实现受影响任务识别与部分右移传播。
