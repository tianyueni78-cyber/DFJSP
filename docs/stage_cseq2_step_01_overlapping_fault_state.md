# C-SEQ2 第 1 步：维修区间重叠的连续故障事件

## 目标

构造一个连续故障场景，使后一故障发生时，前一故障机器仍处于维修不可用区间。
本步只定义事件和状态，不传播影响、不修改调度、不运行搜索。

## 与 C-SEQ1 的区别

C-SEQ1 默认选择前一轮维修结束之后的下一故障，因此：

```text
next_fault.start_time > max(previous_faults.repair_end_time)
```

C-SEQ2 刻意选择维修尚未结束时发生的下一故障：

```text
min(previous_faults.start_time) < next_fault.start_time
next_fault.start_time < max(previous_faults.repair_end_time)
```

这样可以验证计划版本机制是否能在后一故障处理中保留历史维修约束。

## 代码入口

- `src/screening/screen_stage_cseq2_overlapping_next_fault_event.m`
- `scripts/run_stage_cseq2_overlapping_fault_state.m`
- `tests/test_stage_cseq2_overlapping_fault_state.m`

## 验证内容

- 当前计划视图来自阶段 C 第 12 步的 V1 版本；
- 下一故障时刻落在历史维修区间内部；
- `active_previous_repairs` 非空；
- 状态提取能识别新故障在制工序；
- 历史计划不回滚、不修改；
- 不传播影响、不运行搜索。

## 测试命令

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_cseq2_overlapping_fault_state.m'))
```

## 完成标准

- 测试通过；
- 下一故障与历史维修区间确实重叠；
- 后续步骤可以在该状态上合并历史不可用区间与新不可用区间。
