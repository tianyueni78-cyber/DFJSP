# 阶段 C 第 12 步：事件回放与计划版本模型

## 本步目标

建立不可覆盖的计划版本链，使后续连续故障从事件时刻真正生效的计划继续，
而不是回到原始正常基线。

## 版本结构

每个版本记录：

- `version_id`：从 `0` 连续递增；
- `predecessor_version_id`：直接前一版本；
- `effective_time`：版本开始生效的时刻；
- `source_event_group` 和 `source_event_ids`；
- `strategy`：正常基线、局部右移或完全重调度；
- `plan`：该版本的完整机器与 AGV 计划。

`V0` 为正常基线。第 11 步选定方案形成 `V1`，其生效时刻为当前同时故障
事件组的故障时刻。

## 代码入口

- 初始化版本链：`src/state/initialize_stage_c_plan_history.m`
- 追加版本：`src/state/append_stage_c_plan_version.m`
- 查询生效版本：`src/state/resolve_stage_c_active_plan.m`
- 运行入口：`scripts/run_stage_c_plan_version_history.m`
- 测试：`tests/test_stage_c_plan_version_history.m`

## 当前边界

本步只保存已有第 11 步结果并验证故障前读取 `V0`、故障时刻及之后读取
`V1`。不虚构第二个生产场景、不提取下一故障状态、不运行搜索、不生成输出。
第 13 步将在该版本链上加入下一故障时刻的状态提取。
