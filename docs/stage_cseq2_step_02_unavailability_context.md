# C-SEQ2 第 2 步：重叠维修不可用上下文

## 目标

在 C-SEQ2 第 1 步的重叠连续故障基础上，保留历史维修区间，并加入新故障
维修区间，形成累计机器不可用上下文。

本步只处理维修区间：

- 不传播影响；
- 不修改机器计划；
- 不调整 AGV；
- 不运行搜索。

## 处理规则

- 历史维修区间不删除、不回滚；
- 新故障维修区间加入累计故障集合；
- 同一机器维修区间重叠或相接时合并；
- 不同机器维修区间独立保留；
- 每个合并区间保留来源 `event_id`。

## 代码入口

- `src/fault/build_stage_cseq2_overlapping_unavailability_context.m`
- `scripts/run_stage_cseq2_unavailability_context.m`
- `tests/test_stage_cseq2_unavailability_context.m`

## 测试命令

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_cseq2_unavailability_context.m'))
```

## 完成标准

- `active_previous_repairs` 非空；
- 历史维修与新维修存在重叠关系；
- 累计不可用区间覆盖全部历史故障和新故障；
- 同机器合并后区间不再重叠；
- 不传播影响、不修改计划、不运行搜索。
