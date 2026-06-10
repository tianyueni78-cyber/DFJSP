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

## 8. 正式运行结果

使用第 10 步保存的优化正常基线运行结果：

```text
baseline makespan: 112.72
fault: J8-O1, M2, tf=12, tr=5
affected operations: 7, directly affected: 2
AGV adjustment required: 1, affected transports: 53
linked right shift makespan: 112.72
frozen operations: 5, reschedulable operations: 53
complete search executed: 0
```

结果解释：

- 维修区间直接冲突 `2` 道工序；
- 沿工件和机器后继传播后，共有 `7` 道工序受影响；
- 机器时间变化使 AGV 运输约束发生连锁变化，`53` 个运输任务进入联动复核；
- AGV 与机器联动右移通过全部约束检查；
- 联动右移后的机器完工时间仍为 `112.72`，说明本场景的延迟被原计划余量吸收；
- 故障时刻已有 `5` 道工序被冻结，剩余 `53` 道工序可进入完全重调度；
- 本步没有运行完全重调度搜索。

`linked right shift makespan = 112.72` 目前只表示机器工序层面的完工时间没有
增加。第 9 步的 `tD` 使用最终卸载最大完工时间，因此仍需在后续统一评价，
不能在本步直接宣布 `tD=0`。

## 9. 下一步

进入阶段 A 第 13 步：基于本步 `frozen_problem` 对 `53` 道未开工工序执行
同等预算完全重调度搜索，再将新 Pareto 候选与本步联动右移方案进行公平的
`tD`、`SD`、`Y` 组合评价。
