# 阶段 B 第 1 步：加工中故障事件与在制工序状态

## 1. 目标

在现有正常调度基线上，将故障时刻设置在一道真实工序的加工区间内部，
识别故障机器上的在制工序，并计算：

- 原加工时间；
- 已加工时间；
- 剩余加工时间；
- 已完成加工比例。

本步不选择“暂停续加工、从头加工或允许迁移”，也不修改右移、解码和搜索
算法。

运行入口允许直接传入第 10 步保存的优化正常基线。未传入参数时才调用
现有正常基线入口，用于轻量契约测试。

## 2. 数据边界

- 工件、工序、机器和加工时间全部来自现有正常基线；
- `trigger_job` 和 `trigger_operation` 只选择原数据中的工序；
- `interruption_fraction` 表示在该工序加工进度的什么位置发生故障；
- `repair_duration` 是故障实验参数；
- 不修改 `raw_code/`，不生成新的生产问题数据。

首个轻量场景使用：

```text
工序：J5-O1
中断比例：0.5
维修时长：5
中断规则：unresolved
```

## 3. 计算关系

```text
故障时刻 = 原开始时间 + 中断比例 × 原加工时间
已加工时间 = 故障时刻 - 原开始时间
剩余加工时间 = 原结束时间 - 故障时刻
原加工时间 = 已加工时间 + 剩余加工时间
```

故障时刻必须严格位于工序开始和结束之间。

## 4. 新增代码

- `configs/stage_b_processing_fault_config.m`
- `src/fault/create_processing_fault_event.m`
- `src/fault/validate_processing_fault_event.m`
- `src/state/extract_stage_b_interrupted_state.m`
- `scripts/run_stage_b_processing_fault_state.m`
- `tests/test_stage_b_processing_fault_state.m`

## 5. 完成标准

- 故障机器上恰好识别出一道匹配的在制工序；
- 已加工时间和剩余加工时间均大于零；
- 两者之和等于原加工时间；
- 全部工序仍被完整划分为已完成、在制和未开始；
- `interruption_rule` 保持 `unresolved`；
- 不执行任何重调度。

## 6. 轻量测试

```matlab
run(fullfile(pwd,'tests', ...
    'test_stage_b_processing_fault_state.m'))
```

预期输出：

```text
test_stage_b_processing_fault_state passed
```
