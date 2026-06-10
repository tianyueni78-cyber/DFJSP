# 阶段 A 第 11 步：优化基线上的故障重定位与筛选

## 1. 目标

第 10 步已经从原数据获得完工时间 `112.72` 的优化正常基线。本步不再使用
旧随机基线中的机器、绝对故障时刻或影响范围，而是在优化基线上重新建立
工序完成时故障。

## 2. 选择规则

维修时长保持：

```text
tr = 5
```

首先在优化基线上重新定位配置中的 `J5-O1`：

1. 查找其新加工机器；
2. 以其新完成时刻作为 `tf`；
3. 建立维修区间 `[tf, tf+5)`；
4. 提取故障状态并传播影响；
5. 若至少有一个直接维修冲突工序，则继续使用 `J5-O1`。

如果 `J5-O1` 不再产生直接影响，则遍历优化机器时间表中的工序完成时刻，
按现有规则筛选候选，并自动选择排名第 1 的有效场景。

## 3. 数据边界

本步只读取：

- 第 10 步选定的 `optimized_baseline`；
- 原 `stage_a_fault_config.m` 中的 `J5-O1` 和 `tr=5`；
- 现有故障事件、状态快照与影响传播逻辑。

不生成新工件、机器、加工时间、运输距离或 AGV 参数，不修改配置文件，
不修改 `raw_code/`。

## 4. 新增入口

```matlab
stage11 = run_stage_a_optimized_baseline_fault_screening( ...
    normalScenario);
```

返回配置场景在优化基线上的新故障事件与影响、全部有效候选、最终选择的
候选及选择原因。

## 5. 契约测试

```matlab
run(fullfile(pwd, 'tests', ...
    'test_stage_a_optimized_baseline_fault_screening.m'))
```

契约测试只验证接口和选择规则。正式结论必须使用第 10 步正式运行得到的
`normalScenario` 执行本步入口。

契约测试内部使用 `contractScenario`，不会覆盖 MATLAB 工作区中的正式
`normalScenario`。

如果在旧版测试后发现 `normalScenario.optimized_baseline.makespan` 为
`144.2033`，说明正式变量已被测试变量覆盖。无需重新运行搜索，可从第 10
步保存结果恢复：

```matlab
saved = load(fullfile(pwd, 'outputs', ...
    'normal_baseline_search', '20260610_095431', 'result.mat'));
normalScenario = saved.scenario;

normalScenario.optimized_baseline.makespan
stage11 = run_stage_a_optimized_baseline_fault_screening( ...
    normalScenario);
```

恢复后显示的优化基线完工时间应为 `112.72`。

## 6. 正式运行结果

第 10 步正式优化基线恢复后，本步运行结果为：

```text
optimized baseline makespan: 112.72
configured trigger: J5-O1, M1, tf=40, tr=5
configured trigger effective: 0
effective candidate count: 36
selected rank: 1, trigger: J8-O1, M2, tf=12,
affected=7, max_delay=5
selection reason: configured_trigger_ineffective_use_rank_1
```

结论：

- `J5-O1` 在优化基线中改由 `M1` 加工，完成时刻变为 `40`；
- 维修区间 `[40,45)` 没有与后续未开始工序产生直接冲突；
- 因此原 `J5-O1 / M5 / tf=6` 场景只适用于旧随机基线，正式失效；
- 优化基线在 `tr=5` 下共有 `36` 个有效候选；
- 按既定排序规则选择 `J8-O1 / M2 / tf=12 / tr=5`；
- 该场景预计影响 `7` 道工序，最大预计延迟为 `5`。

本次变化来自正常计划优化后机器分配和加工顺序改变，不是新增或修改问题数据。

## 7. 下一步

进入阶段 A 第 12 步：以优化正常基线和新故障场景为统一输入，重新生成
状态快照、影响集合、机器部分右移、AGV 联动及完全重调度冻结问题。
