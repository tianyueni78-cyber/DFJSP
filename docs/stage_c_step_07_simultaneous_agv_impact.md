# 阶段 C 第 7 步：同时故障 AGV 影响分析

## 本步目标

读取第 6 步机器候选计划，识别原 AGV 运输中已经失效或需要沿 AGV 顺序
复核的任务。本步只分析，不修改 AGV 或机器时间表。

## 直接失效条件

仅对负载运输检查：

- 运输到达晚于目标工序的新开工时间；
- 运输开始早于前序工序的新完工时间；
- 最终卸载开始早于工件最后工序的新完工时间。

一条运输可同时具有多个原因，并保留相关工序的全部故障来源编号。

## AGV 后继传播

从每条直接失效运输出发：

- 标记同一 AGV 上后续运输为待复核；
- 标记同一运输组的空载与负载任务为待复核；
- 合并重复任务；
- 后继任务继承前序失效任务的故障来源。

## 输出边界

- `directly_affected_transports`：直接违反机器工序约束；
- `sequence_review_transports`：因同一 AGV 前序任务失效而待复核；
- `affected_transports`：合并去重后的全部待调整任务；
- `unaffected_transports`：当前无需调整的运输。

## 代码入口

- 实现：`src/impact/analyze_stage_c_simultaneous_agv_impact.m`
- 入口：`scripts/run_stage_c_simultaneous_agv_impact_analysis.m`
- 测试：`tests/test_stage_c_simultaneous_agv_impact_analysis.m`

```matlab
run(fullfile(pwd,'tests', ...
    'test_stage_c_simultaneous_agv_impact_analysis.m'))
```

测试通过后进入第 8 步：正式调整 AGV 运输并将运输延迟反馈至机器工序。
