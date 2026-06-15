# 阶段 C 第 5 步：同时故障影响传播与合并

## 本步目标

从第 4 步的两个故障在制工序出发，分别沿同工件后续工序和同机器后续工序
传播预计延迟，再合并两个影响集合。本步只计算预计时间，不修改机器或 AGV
时间表。

## 单根传播

第一版中断规则为保留进度，因此每个故障根的修复后预计完成时间为：

```text
revised_end = repair_end_time + remaining_processing_time
```

从该完成时间分别约束：

- 同工件下一道未开始工序；
- 同机器下一道未开始工序。

新增延迟继续沿两类后继传播，直到预计时间不再变化。

## 多根合并

每个故障根先独立生成影响记录。相同 `job-operation` 的记录合并为一条：

- `projected_start` 取所有来源最大值；
- `projected_end` 取所有来源最大值；
- `source_event_ids` 保存全部故障来源；
- 原因标记按逻辑或合并；
- `source_count > 1` 表示该工序受到多个故障传播链影响。

合并结果按工件和工序编号排序，因此故障事件输入顺序不会改变最终集合。

## 代码入口

- 实现：`src/impact/identify_stage_c_simultaneous_affected_operations.m`
- 场景入口：`scripts/run_stage_c_simultaneous_impact_analysis.m`
- 测试：`tests/test_stage_c_simultaneous_impact_analysis.m`

```matlab
run(fullfile(pwd,'tests','test_stage_c_simultaneous_impact_analysis.m'))
```

## 完成标准

- 两个故障根分别完成后继传播；
- 合并结果没有重复工序；
- 受多个故障影响的工序保留全部事件编号；
- 预计时间采用最大约束；
- 受影响和未受影响集合完整划分未开工工序；
- 反转故障输入顺序不改变合并结果；
- 不修改机器和 AGV 时间表，不执行重调度。
