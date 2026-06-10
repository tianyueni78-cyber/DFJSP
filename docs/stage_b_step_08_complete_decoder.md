# 阶段 B 第 8 步：两段加工完全重调度解码器

## 本步目标

将阶段 B 第 7 步冻结问题和一组 OS/MS/AS/SS 决策解码为完整的机器与 AGV
调度候选，同时正确保留中断工序的两段加工承诺。

本步只解码一个基线种子，不运行种群搜索。

## 复用与改造

未来未开工任务继续复用阶段 A 已验证的逻辑：

- 工序顺序解码；
- 候选机器选择；
- AGV 分配和运输速度；
- 空载、负载运输；
- AGV 充电；
- 最终卸载；
- AGV 能耗。

阶段 B 专用适配器随后完成：

1. 将中断工序有效加工时长恢复为原加工时长；
2. 恢复故障前已加工段和修复后剩余加工段；
3. 按实际加工段重建机器时间表；
4. 维修区间保持为空闲停机；
5. 按有效加工时长重算机器工作能耗；
6. 将维修停机计入机器空闲时间，而不是加工时间。

## 输出结构

- `operation_records`：每道工序一条逻辑记录；
- `processing_segments`：实际机器加工段，中断工序有两条；
- `machineTable`：基于实际加工段重建；
- `transport_records`：解码生成的未来运输；
- `machine_energy`、`agv_energy`、`total_energy`；
- `job_complete_unload` 和最终完工时间。

## 代码入口

- 解码器：
  [`decode_stage_b_complete_reschedule.m`](../src/rescheduling/decode_stage_b_complete_reschedule.m)
- 运行入口：
  [`run_stage_b_complete_reschedule_decode.m`](../scripts/run_stage_b_complete_reschedule_decode.m)
- 轻量测试：
  [`test_stage_b_complete_reschedule_decode.m`](../tests/test_stage_b_complete_reschedule_decode.m)

## MATLAB 轻量测试

```matlab
run(fullfile(pwd,'tests','test_stage_b_complete_reschedule_decode.m'))
```

测试使用原基线染色体中未开工部分作为解码种子，不生成替代问题数据。
