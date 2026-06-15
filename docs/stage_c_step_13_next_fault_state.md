# 阶段 C 第 13 步：从当前计划提取下一故障状态

## 本步目标

从第 12 步版本链中解析下一故障时刻实际生效的计划版本，并在该计划上分类
已完成、正常在制、新故障在制、未开工工序以及 AGV 状态，不回到 `V0`。

## 当前计划视图

第 11 步可能选择完全重调度。其候选保存逻辑工序和 AGV 活动记录，本步建立
只读 `isCurrentPlanView`：

- 从 `operation_records` 重建每道逻辑工序只出现一次的机器表；
- 从 `agv_activity_records` 重建 AGV 表；
- 从 `V0` 继承问题规模和原始参数；
- 记录 `source_version_id`，但不伪装成新的正常基线。

## 下一故障筛选

从 `V1` 中第一次故障维修结束后仍在加工的真实工序动态筛选下一故障。事件
编号与事件组顺延，维修时长和中断规则沿用当前配置，不生成生产问题数据。

## 代码入口

- 当前计划视图：`src/state/build_stage_c_current_plan_view.m`
- 下一故障筛选：`src/screening/screen_stage_c_next_fault_event.m`
- 连续故障状态：`src/state/extract_stage_c_sequential_fault_state.m`
- 运行入口：`scripts/run_stage_c_next_fault_state.m`
- 测试：`tests/test_stage_c_next_fault_state.m`

## 当前边界

本步只提取状态和保留仍未结束的旧维修区间列表，不传播影响、不修改 `V1`、
不追加 `V2`、不运行搜索。当前轻量场景把下一故障选在旧维修结束之后，因此
旧活动维修区间数量为零；重叠维修将在第 14 和第 17 步专项验证。
