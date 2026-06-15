# 阶段 C 第 9 步：同时故障完全重调度冻结问题

## 本步目标

在双机器同时故障场景下划定完全重调度边界。故障时刻前已经完成或已经开始
执行的任务保持不变，只有尚未开工的工序和运输进入后续搜索。

## 冻结任务

- 故障时刻前已完成工序；
- 故障时刻正在正常加工的工序；
- 两个故障在制工序及其“故障前加工段 + 修复后续加工段”承诺；
- 已完成运输和故障时刻正在执行的运输。

## 可重调度任务

每道未开工工序保存：

- 原机器、原开始时间和原结束时间；
- 原问题定义中的候选机器；
- 各候选机器对应的加工时间。

本步不生成候选机器或加工时间，全部读取原项目问题数据。

## 资源边界

- 工件边界：冻结工序必须形成连续前缀；
- 机器边界：取快照时刻、正常在制完成、故障承诺完成和维修结束的最大值；
- AGV 边界：保存可用时间、位置、电量、累计消耗和已完成充电次数；
- 多个维修区间和中断承诺分别保存。

## 输出边界

`decoder_requirement` 设置为：

```text
stage_c_multiple_split_operation_decoder
```

表示后续解码器必须支持多个两段式中断加工承诺。

## 代码入口

- 实现：`src/rescheduling/build_stage_c_simultaneous_frozen_problem.m`
- 入口：`scripts/run_stage_c_simultaneous_frozen_problem.m`
- 测试：`tests/test_stage_c_simultaneous_frozen_problem.m`

```matlab
run(fullfile(pwd,'tests', ...
    'test_stage_c_simultaneous_frozen_problem.m'))
```

本步不运行搜索。测试通过后进入第 10 步：扩展完全重调度解码与受限搜索。
