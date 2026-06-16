# 阶段 C 第 15 步：连续故障局部右移与 AGV 联动

## 本步目标

在第 14 步已经确定的连续故障和合并影响集合基础上，正式生成局部右移候选
计划：

1. 对下一故障的在制工序保留已加工进度，修复后继续加工剩余时间；
2. 将第 14 步合并后的受影响工序时间写入机器表；
3. 识别机器时间变化导致的 AGV 运输约束失效；
4. 调整 AGV 时间并反馈到机器开工时间；
5. 验证机器、工件顺序、维修区间、AGV 不重叠和运输到达约束。

## 复用关系

本步没有重写调度算法，而是把阶段 C 同时故障的已验证构件扩展为“一个或
多个同组故障”均可使用：

- `src/rescheduling/build_stage_c_simultaneous_machine_right_shift.m`
- `src/impact/analyze_stage_c_simultaneous_agv_impact.m`
- `src/rescheduling/build_stage_c_simultaneous_agv_linked_right_shift.m`

第 15 步入口负责把第 14 步的当前计划视图、下一故障、状态和合并影响集合
送入这些构件。

## 代码入口

- 运行入口：`scripts/run_stage_c_sequential_agv_linked_right_shift.m`
- 测试：`tests/test_stage_c_sequential_agv_linked_right_shift.m`

## 当前边界

本步只生成连续故障的局部右移候选方案，不追加新的计划版本，不运行完全重
调度搜索，也不做组合选择。
