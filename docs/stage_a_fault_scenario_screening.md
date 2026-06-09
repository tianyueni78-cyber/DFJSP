# 阶段 A 补充步骤：筛选有效故障场景

## 1. 目的

前六步已经能够处理当前默认故障场景，但原配置：

```matlab
trigger_job = 1;
trigger_operation = 1;
repair_duration = 5;
```

在原基线中没有影响故障机器的后续工序，因此机器和 AGV 调整集合均为空。

本补充步骤从原基线筛选在维修时长 `5` 下会产生真实影响的其他工序完成时故障场景。它只生成候选分析结果，不修改配置。

## 2. 数据来源

没有生成或替换调度数据。

输入为：

- 原项目数据生成的 `baseline.machineTable`；
- 当前 `stage_a_fault_config.m` 中的 `repair_duration=5`；
- 已实现的故障事件、状态快照和影响传播函数。

候选故障的工件、工序、机器、完成时刻和同机后续工序均直接来自原机器时间表。

## 3. 筛选规则

对每台机器原加工序列中的相邻真实工序，设：

```text
gap = 下一工序开始时刻 - 当前工序完成时刻
```

把当前工序完成时刻作为故障时刻。维修区间要与下一工序产生直接冲突，必须满足：

```text
repair_duration > gap
```

本次统一使用当前配置的维修时长 `5`，只保留：

```text
5 > gap
```

的候选场景。

## 4. 候选评价

对每个候选，程序复用：

```text
create_completion_fault_event
→ extract_stage_a_state
→ identify_stage_a_affected_operations
```

得到：

- 直接受影响工序数；
- 传播后的受影响工序总数；
- 最大预计延迟；
- 机器空闲间隔；
- 产生直接影响的维修时长阈值。

阈值字段记录 `gap`，其严格含义是：

```text
维修时长必须大于该阈值
```

## 5. 排序规则

候选按以下顺序排列：

1. 受影响工序总数降序；
2. 机器空闲间隔升序；
3. 故障时刻升序。

排序只用于帮助选择实验场景，不会自动修改配置。

## 6. 新增文件

- `src/screening/screen_stage_a_fault_scenarios.m`
- `scripts/run_stage_a_fault_scenario_screening.m`
- `tests/test_stage_a_fault_scenario_screening.m`

运行入口会在 MATLAB 命令窗口打印：

```text
排名、触发工序、机器、故障时刻、同机下一工序、
空闲间隔、预计受影响工序数、最大预计延迟
```

同时返回完整结构：

```matlab
result.screening.candidates
```

## 7. 安全边界

本步骤：

- 不修改 `stage_a_fault_config.m`；
- 不修改 `raw_code/`；
- 不创建人工工序或机器时间表；
- 不改变维修时长；
- 不自动选择最终场景；
- 不执行正式重调度实验。

## 8. 当前验证状态

已完成：

- 原机器序列相邻工序提取；
- 空闲间隔计算；
- 当前维修时长下的候选筛选；
- 复用原影响传播逻辑计算候选影响；
- 候选排序；
- 命令窗口候选表输出；
- 配置不修改和无额外数据检查；
- MATLAB 测试代码；
- 静态副作用检查。

尚未完成：

- MATLAB 运行验证；
- 用户确认最终故障场景。

## 9. MATLAB 测试

```matlab
run(fullfile(pwd, 'tests', 'test_stage_a_fault_scenario_screening.m'))
```

预期最后输出：

```text
test_stage_a_fault_scenario_screening passed
```

测试前会打印候选表。请将候选表和测试结果发回，再选择最终场景。
