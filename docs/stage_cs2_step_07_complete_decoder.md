# C-S2 第 7 步：从头加工完全重调度解码器

## 目标

在第 6 步冻结问题的基础上，实现一个轻量完全重调度解码器，用于把一组
未开工工序的决策解码成完整候选方案。

本步只解码一个基线种子决策，不运行搜索。

## 解码逻辑

1. 复用阶段 A 完全重调度核心，安排未开工工序、机器选择、AGV 分配和运输；
2. 对 C-S2 中断工序恢复固定承诺；
3. 每个中断工序保留两段：
   - `lost_processing_before_fault`；
   - `restart_after_repair`；
4. 逻辑工序有效加工时间仍为原加工时长；
5. 机器能耗按物理加工段统计，因此损失加工段也计入机器工作能耗；
6. 校验机器、工件、维修区间、冻结工序和最终卸载约束。

## 与 C-S1 的差异

C-S1 是续加工，故障前加工段和修复后续加工段之和等于原加工时长。

C-S2 是从头加工，故障前加工段作废，修复后再完整加工一次。因此机器物理
工作量为：

```text
total_machine_processing_time = lost_processing_time + original_duration
```

## 代码入口

- 解码器：`src/rescheduling/decode_stage_cs2_complete_reschedule.m`
- 阶段入口：`scripts/run_stage_cs2_complete_reschedule_decode.m`
- 契约测试：`tests/test_stage_cs2_complete_reschedule_decode.m`

## 完成标准

- 能生成 `complete_reschedule_candidate`；
- 多个从头加工承诺均被保留；
- 损失加工段计入机器工作能耗；
- 未开工工序可被解码；
- 冻结工序不被改变；
- 维修区间、工件顺序、机器不重叠和最终卸载约束成立；
- 不运行搜索。

## 运行方式

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_cs2_complete_reschedule_decode.m'))
```
