# C-S2 第 2 步：从头加工影响传播

## 目标

从 C-S2 第 1 步生成的多个从头加工承诺出发，传播同时故障下的后续影响。
本步只计算受影响工序集合，不修改机器时间表、不调整 AGV、不运行搜索。

## 本步逻辑

`C-S1` 的影响传播使用：

```text
故障机器修复时间 + 剩余加工时间
```

作为中断根工序的新完成时间。

`C-S2` 改为使用：

```text
restart_segment.end
```

也就是修复后完整重加工的完成时间。

传播路径仍然是两条：

1. 同一工件后续工序；
2. 同一机器后续加工队列。

多个故障根分别传播后再合并，同一道工序如被多个故障源影响，则保留全部
来源事件，并取最严格的投影开始/结束时间。

## 代码入口

- 影响传播：`src/impact/identify_stage_cs2_restart_affected_operations.m`
- 阶段入口：`scripts/run_stage_cs2_impact_analysis.m`
- 契约测试：`tests/test_stage_cs2_impact_analysis.m`

## 关键输出

- `cs2_impact.root_impacts`：每个中断根单独传播的影响；
- `cs2_impact.affected_operations`：合并后的受影响工序集合；
- `cs2_impact.unaffected_unstarted_operations`：未受影响的未开工工序；
- `cs2_impact.counts.multi_source_operations`：被多个故障源共同影响的工序数量。

## 完成标准

- 每个从头加工承诺都生成一个根影响；
- 根影响的新完成时间等于 `restart_segment.end`；
- 所有受影响工序 `projected_delay > 0`；
- 合并后受影响工序无重复；
- 受影响工序保留全部来源事件；
- 本步不修改机器表和 AGV 表。

## 运行方式

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_cs2_impact_analysis.m'))
```
