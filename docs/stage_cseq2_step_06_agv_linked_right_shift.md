# C-SEQ2 第 6 步：AGV 与机器联动右移

## 目标

在 C-SEQ2 第 5 步 AGV 影响分析基础上，正式调整受影响 AGV 运输任务，并将
运输延迟反馈到机器工序开工时间，生成完整的局部右移候选。

本步仍不运行搜索。

## 处理内容

- 保持 AGV 分配、路线和运输持续时间不变；
- 调整受影响运输开始/结束时间；
- 避免同一 AGV 时间冲突；
- 工序必须等待运输到达后才能加工；
- 新故障维修区间被机器候选避开；
- 历史维修累计不可用上下文继续保留，供后续最终审计使用。

## 代码入口

- `scripts/run_stage_cseq2_agv_linked_right_shift.m`
- `tests/test_stage_cseq2_agv_linked_right_shift.m`

## 测试命令

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_cseq2_agv_linked_right_shift.m'))
```

## 完成标准

- AGV 不重叠；
- 运输到达约束满足；
- 最终卸载约束满足；
- 机器加工段不重叠；
- 新故障维修区间被避开；
- 不运行搜索。
