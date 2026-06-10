# 阶段 B 第 7 步：完全重调度冻结问题

## 本步目标

在加工中故障时刻建立完全重调度边界，明确哪些任务不可改变、哪些任务可以
重新优化，以及机器、工件和 AGV 从什么状态继续。

本步不运行搜索，也不生成完全重调度候选。

## 工序划分

### 冻结工序

- 故障前已完成工序；
- 故障时刻其他机器上的在制工序；
- 故障机器上的中断工序。

中断工序作为固定承诺保存：

- 已完成加工进度；
- 修复后剩余加工段；
- 原机器；
- 修复后的新完成时间。

它不允许从头加工，也不允许迁移机器。

### 可重调度工序

只有故障时刻尚未开始的工序进入完全重调度决策，可重新选择：

- 工序顺序；
- 原候选集合内的机器；
- AGV；
- 运输速度。

## AGV 边界

- 故障前已完成运输冻结；
- 故障时刻正在执行的运输冻结至原完成时间；
- 尚未开始的原运输释放，由后续解码器重新生成；
- 每台 AGV 保存可用时间、位置、电量、累计能耗和充电次数。

## 为什么不能直接使用阶段 A 解码器

阶段 A 解码器把冻结工序的 `end-start` 当作连续加工时长。加工中断工序的
日历跨度包含维修停机，不能将停机时间计入加工时间或机器能耗。

因此本步明确输出：

- `stage_a_decoder_compatible = false`
- `decoder_requirement = 'stage_b_split_operation_decoder'`

下一步需要实现支持两段加工承诺的阶段 B 专用完全重调度解码器。

## 代码入口

- 构建函数：
  [`build_stage_b_frozen_problem.m`](../src/rescheduling/build_stage_b_frozen_problem.m)
- 运行入口：
  [`run_stage_b_frozen_problem.m`](../scripts/run_stage_b_frozen_problem.m)
- 轻量测试：
  [`test_stage_b_frozen_problem.m`](../tests/test_stage_b_frozen_problem.m)

## MATLAB 轻量测试

```matlab
run(fullfile(pwd,'tests','test_stage_b_frozen_problem.m'))
```
