# 阶段 A 结构与代码导读

## 1. 这套程序现在解决什么问题

阶段 A 处理的是：

> 单台机器在某道工序加工完成后发生故障，故障机器在维修区间内不可用，
> 程序分别生成部分右移方案和完全重调度方案，并联动调整 AGV，最后自动
> 选择综合评价更好的方案。

单机器故障没有集中在一个文件中，而是由“故障状态、影响分析、局部修复、
完全重调度、组合评价和测试”多个模块共同实现。

## 2. 总体结构

```text
正常计划
  ↓
故障事件与状态快照
  ↓
识别受影响工序
  ├─ 部分右移 + AGV 联动
  └─ 冻结已执行任务 + 完全重调度
                         ↓
                  受限 NSGA-II 搜索
  └──────────────────────┘
             ↓
       计算 tD、SD、Y
             ↓
       组合选择最终方案
             ↓
     约束、能耗和稳健性测试
```

## 3. 数学模型

### 3.1 决策对象

完全重调度只改变故障时刻尚未开工的任务：

- 工序加工顺序；
- 工序选择的机器；
- 工序运输使用的 AGV；
- AGV 空载速度；
- AGV 载货速度。

已完成和正在执行的任务被冻结，不参与重新优化。

代码入口：

- [冻结问题建模](../src/rescheduling/build_stage_a_frozen_problem.m)
- [故障影响传播](../src/impact/identify_stage_a_affected_operations.m)

### 3.2 主要约束

- 同一工件的工序顺序不能颠倒；
- 同一机器同一时刻只能加工一道工序；
- 故障机器在维修区间内不能加工；
- 同一 AGV 同一时刻只能执行一个活动；
- 工序必须等待工件运输到达；
- 已冻结任务不能被完全重调度改变；
- 最后一道工序完成后必须安排最终卸载。

### 3.3 评价指标

```text
tD = 重调度方案最终卸载完工时间 - 正常基线完工时间
SD = 未开工工序中发生机器变更的数量
Y  = ω1 × tD + ω2 × SD
```

`Y` 越小越好。对应代码：

- [计算 tD、SD、Y](../src/evaluation/evaluate_stage_a_rescheduling_plan.m)
- [选择最终策略](../src/evaluation/select_stage_a_combined_strategy.m)

关键代码逐行解释：

```matlab
candidateMakespan = final_unload_makespan(candidate);
```

取得候选方案所有工件完成最终卸载后的完工时间。

```matlab
sequenceDeviation = machine_assignment_deviation( ...
    state.unstarted_operations, candidate.operation_records);
```

逐道比较未开工工序原机器和重调度机器，得到 `SD`。

```matlab
completionTimeDeviation = candidateMakespan - baseline.makespan;
```

计算候选方案相对正常计划的完工时间变化 `tD`。

```matlab
combinedScore = weights.completion_time_weight * ...
    completionTimeDeviation + ...
    weights.sequence_deviation_weight * sequenceDeviation;
```

按照权重计算综合指标 `Y`。

## 4. 编码

一个完全重调度个体包含五段决策：

| 编码字段 | 含义 |
|---|---|
| `operation_sequence` | 未开工工序的调度顺序 |
| `machine_choice` | 每道工序选择候选机器中的第几个 |
| `agv_assignment` | 每道工序选择哪台 AGV |
| `free_speed_choice` | AGV 空载速度档位 |
| `load_speed_choice` | AGV 载货速度档位 |

代码入口：

- [种群初始化](../src/rescheduling/initialize_stage_a_reschedule_population.m)
- [交叉与变异](../src/rescheduling/vary_stage_a_reschedule_population.m)
- [从基线生成种子个体](../src/rescheduling/build_stage_a_baseline_seed_decision.m)

初始化关键代码逐行解释：

```matlab
population(1) = normalize_decision(seedDecision, ...
    'baseline_chromosome_unstarted_suffix');
```

第一个个体保留正常基线中未开工部分的原决策，作为稳定种子。

```matlab
decision.operation_sequence = jobMultiset(randperm(operationCount));
```

在保持各工件工序数量不变的前提下，随机生成调度顺序。

```matlab
decision.machine_choice(index) = randi(upper);
```

只在该工序原数据给出的候选机器范围内随机选择。

```matlab
decision.agv_assignment = randi( ...
    baseline.agvData.AGVNum, 1, operationCount);
```

为每道未开工工序分配一台 AGV。

交叉与变异说明：

- 工序顺序使用受限 IPOX 思路，保留工件出现次数；
- 机器、AGV 和速度使用掩码交叉；
- 变异可以交换不同工件的位置，并重新选择少量机器、AGV 或速度；
- 所有新值都被限制在原数据允许的范围内。

## 5. 解码

解码器把一个编码个体变成可以执行的机器和 AGV 时间表：

- [完全重调度解码器](../src/rescheduling/decode_stage_a_complete_reschedule.m)

主循环关键代码逐行解释：

```matlab
jobId = decision.operation_sequence(sequenceIndex);
operationId = nextOperation(jobId);
```

读取当前要安排的工件，并确定该工件下一道尚未安排的工序。

```matlab
machineId = source.candidate_machines(machineChoice);
processingTime = source.processing_times(machineChoice);
```

将机器选择编码转换为真实机器编号和加工时间。

```matlab
agvId = decision.agv_assignment(sourceIndex);
```

取得负责本次运输的 AGV。

```matlab
startTime = max([jobReady, transportReady, ...
    machineAvailable(machineId)]);
```

工序开始时间必须同时满足：前序完成、运输到达和机器可用。

```matlab
machineAvailable(machineId) = endTime;
jobState(jobId).release_time = endTime;
```

加工完成后更新机器和工件的下一次可用时间。

```matlab
candidate.total_energy = machineEnergy + agvEnergyUse;
```

输出机器能耗与 AGV 能耗之和。

解码结束后还会检查机器冲突、工序优先关系、AGV 冲突、运输到达、最终
卸载及 AGV 电量。

## 6. 优化算法

完全重调度使用受限 NSGA-II：

- [NSGA-II 搜索主循环](../src/rescheduling/search_stage_a_complete_reschedule.m)
- [候选解评价](../src/rescheduling/evaluate_stage_a_reschedule_candidate.m)

优化目标：

1. 最终卸载完工时间最小；
2. 机器与 AGV 总能耗最小。

主循环关键代码逐行解释：

```matlab
population = initialize_stage_a_reschedule_population(...);
```

生成初始种群。

```matlab
evaluated = evaluate_population(population, baseline, frozen);
evaluated = rank_population(evaluated);
```

解码每个个体，计算目标值，再进行非支配排序和拥挤距离计算。

```matlab
parents = tournament_select(...);
offspringDecisions = vary_stage_a_reschedule_population(...);
```

选择父代并执行交叉、变异。

```matlab
combined = rank_population([evaluated, offspring]);
evaluated = select_elite(combined, options.population_size);
```

合并父代和子代，保留等级更高、分布更均匀的个体。

```matlab
stopReason = 'no_pareto_improvement';
```

连续若干代 Pareto 前沿没有改善时自适应停止；同时还支持最大代数和时间
上限。

## 7. 部分右移

部分右移属于局部修复，不使用遗传算法：

- [机器工序右移](../src/rescheduling/build_stage_a_machine_right_shift.m)
- [AGV 与机器联动右移](../src/rescheduling/build_stage_a_agv_linked_right_shift.m)
- [右移方案能耗评价](../src/evaluation/evaluate_stage_a_right_shift_energy.m)

它保持原机器分配、AGV 分配、运输路线和加工顺序，只把受故障影响的任务
向后移动，并沿工件、机器和 AGV 约束传播延迟。

## 8. 组合选择

[组合选择代码](../src/evaluation/select_stage_a_combined_strategy.m)完成以下工作：

1. 评价部分右移方案；
2. 评价完全重调度 Pareto 候选；
3. 选择 `Y` 最小的方案；
4. 若 `Y` 相同，优先 `tD` 更小的方案；
5. 若仍相同，优先 `SD` 更小的方案。

因此程序不是固定使用局部优化或全局优化，而是动态比较两类方案。

## 9. 测试入口

| 测试 | 检查内容 |
|---|---|
| [冻结问题测试](../tests/test_stage_a_frozen_problem.m) | 已执行任务冻结、未开工任务释放 |
| [影响分析测试](../tests/test_stage_a_impact_analysis.m) | 维修冲突和延迟传播 |
| [机器右移测试](../tests/test_stage_a_machine_right_shift.m) | 机器和工序约束 |
| [AGV 联动测试](../tests/test_stage_a_agv_linked_right_shift.m) | AGV 冲突与运输到达 |
| [编码算子测试](../tests/test_stage_a_reschedule_operators.m) | 初始化、交叉、变异合法性 |
| [解码测试](../tests/test_stage_a_complete_reschedule_decode.m) | 编码到完整时间表 |
| [搜索测试](../tests/test_stage_a_restricted_search_contract.m) | NSGA-II 轻量主循环 |
| [组合选择测试](../tests/test_stage_a_combination_contract.m) | `tD、SD、Y` 和策略选择 |
| [最终综合测试](../tests/test_stage_a_step_14_contract.m) | 约束、权重和能耗审计 |

## 10. 当前状态

阶段 A 已经具备：

- 数学评价模型；
- 完全重调度编码；
- 机器与 AGV 联合解码；
- 受限 NSGA-II；
- 部分右移局部修复；
- 组合策略选择；
- 约束、能耗、权重和多随机种子验证。

阶段 A 尚未处理“加工过程中机器突然故障”的在制工序剩余加工问题，该
问题属于阶段 B。
