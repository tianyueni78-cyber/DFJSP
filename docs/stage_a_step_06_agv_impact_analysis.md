# 阶段 A 第 6 步：分析 AGV 运输影响

## 1. 工作表位置

```text
阶段 A：工序完成时单机器故障
├── 第 1 至 4 步：基线、故障、状态和影响范围
├── 第 5 步：机器部分右移候选方案
└── 第 6 步：分析需要调整的 AGV 运输（本步）
```

本步只识别运输影响，不修改或重新生成 AGV 任务。

## 2. 数据来源

没有生成额外数据。输入全部来自原项目：

- `baseline.AGVTable`
- `right_shift.operation_records`
- `baseline.problem.operaNumVec`

当前已确认使用原基线筛选候选第 1 名：`J5-O1` 完成时 `M5` 故障，故障时刻为 `6`，维修时长为 `5`。该场景预计会产生真实机器右移，因此本步骤将用于识别实际失效的 AGV 运输约束；具体运输影响数量以回归测试结果为准。

## 3. 原代码运输语义

根据原 `sorting.m`：

- `load_status=-1`：空载移动；
- `load_status=-2`：负载运输；
- `opera=j`：该运输服务于工序 `Oj`；
- `opera=-1`：最后一道工序完成后的卸载运输。

充电、前往充电和空闲块不属于本步的工件运输集合。

## 4. 直接约束检查

只对负载运输进行直接时间约束判断。

### 运往加工工序

对于运往 `Oij` 的负载运输：

```text
运输结束时间 <= Oij 候选开始时间
```

若 `j>1`，还必须满足：

```text
运输开始时间 >= Oi(j-1) 候选完成时间
```

### 最终卸载运输

对于 `opera=-1`：

```text
运输开始时间 >= 该工件最后一道工序候选完成时间
```

违反上述条件的运输进入直接受影响集合。

## 5. AGV 序列连带影响

某个运输需要调整后：

- 同一运输组中的空载和负载任务需要共同复核；
- 同一 AGV 在其后的运输任务需要复核，避免调整后出现 AGV 时间冲突。

本步只标记这些任务，不计算新开始时间。

## 6. 输出

```matlab
analysis.changed_operations
analysis.directly_affected_transports
analysis.affected_transports
analysis.unaffected_transports
analysis.requires_agv_adjustment
analysis.counts
```

每个受影响运输记录：

- AGV、工件和工序编号；
- 空载或负载状态；
- 出发和到达机器；
- 原开始和结束时间；
- 直接约束违反或 AGV 序列复核标记；
- 影响原因。

## 7. 新增文件

- `src/impact/analyze_stage_a_agv_impact.m`
- `scripts/run_stage_a_agv_impact_analysis.m`
- `tests/test_stage_a_agv_impact_analysis.m`

## 8. 当前验证状态

已完成：

- 原 AGV 字段和运输语义核对；
- 机器时间变化识别；
- 工件前序完成约束检查；
- 运输到达与加工开始约束检查；
- 最终卸载运输约束检查；
- 同一 AGV 后续任务连带标记；
- 零机器变化对应零 AGV 调整检查；
- 原 AGV 时间表不修改检查；
- MATLAB 测试代码；
- 静态副作用检查。

尚未完成：

- MATLAB 运行验证；
- AGV 任务正式调整。

## 9. MATLAB 测试

```matlab
run(fullfile(pwd, 'tests', 'test_stage_a_agv_impact_analysis.m'))
```

预期输出：

```text
test_stage_a_agv_impact_analysis passed
```

## 10. 本步没有做什么

- 没有生成测试数据；
- 没有修改 `raw_code/`；
- 没有改变 AGV 分配、速度、时间或路线；
- 没有重新计算电量、充电和能耗；
- 没有把机器候选方案标记为完整可行方案。

## 11. 下一步

若运输影响集合非空，下一步复用原项目运输时间、AGV 序列和能量规则调整相关任务；若集合为空，则机器右移候选方案不需要 AGV 联动修改。
