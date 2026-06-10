# 阶段 A 第 12 步：新基线与新故障的重调度链重建

## 1. 目标

使用第 10 步优化正常基线和第 11 步正式故障场景，重新贯通故障后的全部
确定性处理环节，避免继续调用会自行生成旧随机基线的历史脚本入口。

正式输入为：

```text
正常基线完工时间：112.72
故障：J8-O1
故障机器：M2
故障时刻：12
维修时长：5
```

## 2. 重建链

```text
第 10 步优化正常基线
→ 第 11 步正式故障选择
→ 状态快照
→ 影响范围识别
→ 机器部分右移
→ AGV 运输影响分析
→ AGV 与机器联动右移
→ 完全重调度冻结问题
```

本步不运行完全重调度搜索，也不执行 `tD`、`SD`、`Y` 组合选择。

## 3. 代码修改

新增：

- `scripts/run_stage_a_rebuilt_rescheduling_chain.m`
- `tests/test_stage_a_rebuilt_rescheduling_chain.m`

现有状态、影响、右移、AGV 联动和冻结算法不修改。新入口只负责将同一个
优化基线与同一个故障事件传入全部环节，并验证各环节边界一致。

## 4. 正式运行

```matlab
stage12 = run_stage_a_rebuilt_rescheduling_chain(normalScenario);
```

如果工作区没有正式 `normalScenario`，先从第 10 步结果恢复：

```matlab
saved = load(fullfile(pwd, 'outputs', ...
    'normal_baseline_search', '20260610_095431', 'result.mat'));
normalScenario = saved.scenario;
stage12 = run_stage_a_rebuilt_rescheduling_chain(normalScenario);
```

## 5. 契约测试

```matlab
run(fullfile(pwd, 'tests', ...
    'test_stage_a_rebuilt_rescheduling_chain.m'))
```

测试只验证链路契约，不替代正式优化基线运行。

## 6. 契约测试结果

MATLAB 契约测试已通过：

```text
test_stage_a_rebuilt_rescheduling_chain passed
```

测试输出为：

```text
baseline makespan: 144.203
fault: J5-O1, M5, tf=6, tr=5
affected operations: 6, directly affected: 1
AGV adjustment required: 0, affected transports: 0
linked right shift makespan: 141.203
frozen operations: 4, reschedulable operations: 54
complete search executed: 0
```

这些数值来自测试内部的 `contractScenario`，只证明完整链路可以贯通、约束
验证通过且没有执行搜索。它们不属于第 10 步正式优化基线，不能作为阶段 A
正式实验结果。

## 7. 正式运行边界

正式运行前应确认：

```matlab
normalScenario.optimized_baseline.makespan
```

结果必须为 `112.72`。随后执行：

```matlab
stage12 = run_stage_a_rebuilt_rescheduling_chain(normalScenario);
```

正式输出必须显示 `J8-O1 / M2 / tf=12 / tr=5`。若仍显示 `144.203` 或
`J5-O1`，说明工作区中的 `normalScenario` 不是第 10 步保存的正式结果。
