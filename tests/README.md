# tests

## 当前测试

`test_normal_schedule_contract.m`

检查正常调度入口能否返回：

- 染色体和目标值；
- 机器时间表与 AGV 时间表；
- 最大完工时间与能耗；
- AGV 电量和充电记录；
- 后续故障状态提取需要的输入数据。

当前仅完成测试代码与静态检查，尚未运行 MATLAB。

## 运行方法

先把 MATLAB 当前文件夹切换到项目根目录，并确认当前目录下存在 `tests/`、`scripts/`、`src/` 和 `raw_code/`。

```matlab
pwd
run(fullfile(pwd, 'tests', 'test_normal_schedule_contract.m'))
```

不能在其他项目目录中直接使用相对路径 `run('tests/test_normal_schedule_contract.m')`。

## 阶段 A 第 2 步测试

`test_completion_fault_event.m`

检查故障事件是否：

- 发生在目标工序完成时刻；
- 自动关联正确机器；
- 没有中断正在加工的工序；
- 正确计算维修结束时刻；
- 没有提前执行重调度。

```matlab
run(fullfile(pwd, 'tests', 'test_completion_fault_event.m'))
```

## 阶段 A 第 3 步测试

`test_stage_a_state_snapshot.m`

测试直接使用原项目数据生成的正常基线，不创建人工调度样例。它检查：

- 触发工序属于已完成集合；
- 所有真实工序被完整且唯一地分类；
- 已完成、进行中、未开始的时间边界；
- AGV 空闲和充电记录不会被误算为工件运输；
- 本步骤没有执行重调度。

```matlab
run(fullfile(pwd, 'tests', 'test_stage_a_state_snapshot.m'))
```

## 阶段 A 第 4 步测试

`test_stage_a_impact_analysis.m`

测试直接使用原项目数据生成的正常基线，检查：

- 维修区间与故障事件一致；
- 直接冲突工序属于故障机器并与维修区间重叠；
- 受影响与未受影响集合完整划分未开始工序；
- 每个受影响工序具有正的预计延迟和明确原因；
- 正常机器时间表没有被修改；
- 本步骤没有执行重调度。

```matlab
run(fullfile(pwd, 'tests', 'test_stage_a_impact_analysis.m'))
```

## 阶段 A 第 5 步测试

`test_stage_a_machine_right_shift.m`

检查：

- 正常基线没有被修改；
- 受影响工序使用第 4 步预计时间；
- 未受影响工序保持原时间；
- 若原故障场景的影响集合为空，全部工序时间保持原样；
- 机器分配和加工时长不变；
- 机器无加工重叠；
- 工件工艺顺序有效；
- 维修区间内无加工；
- AGV 时间表保持原样且未被标记为已验证。

```matlab
run(fullfile(pwd, 'tests', 'test_stage_a_machine_right_shift.m'))
```

## 阶段 A 第 6 步测试

`test_stage_a_agv_impact_analysis.m`

检查：

- 使用原项目 AGV 时间表；
- AGV 时间表未被修改；
- 受影响和未受影响运输完整划分工件运输；
- 直接受影响项是违反时间约束的负载运输；
- 同一 AGV 后续任务被标记为需要复核；
- 当前零机器变化场景得到零 AGV 调整。

```matlab
run(fullfile(pwd, 'tests', 'test_stage_a_agv_impact_analysis.m'))
```

## 阶段 A 有效故障场景筛选测试

`test_stage_a_fault_scenario_screening.m`

检查：

- 候选全部来自原机器时间表；
- 使用当前配置维修时长；
- 每个候选都产生至少一个直接受影响工序；
- 候选的空闲间隔和故障时刻与原基线一致；
- 候选按影响范围和空闲间隔排序；
- 配置未修改且没有生成额外调度数据。

```matlab
run(fullfile(pwd, 'tests', 'test_stage_a_fault_scenario_screening.m'))
```

## 阶段 B 第 1 步测试

`test_stage_b_processing_fault_state.m`

检查故障时刻位于工序内部、故障机器上恰好存在一道匹配的在制工序，以及：

```text
已加工时间 + 剩余加工时间 = 原加工时间
```

同时确认中断规则仍为 `unresolved`，且没有执行重调度。

```matlab
run(fullfile(pwd,'tests', ...
    'test_stage_b_processing_fault_state.m'))
```

## 阶段 B 第 2 步测试

`test_stage_b_resume_rule.m`

检查已加工进度保留、维修结束后从原机器续加工、总有效加工时间不变，以及
禁止从头加工和禁止迁移。

```matlab
run(fullfile(pwd,'tests','test_stage_b_resume_rule.m'))
```

## 阶段 B 第 3 步测试

`test_stage_b_impact_analysis.m`

检查传播根、工件直接后继、机器直接后继、正延迟和影响集合划分，并确认
正常基线机器时间表没有被修改。

```matlab
run(fullfile(pwd,'tests','test_stage_b_impact_analysis.m'))
```

## 阶段 B 第 4 步测试

`test_stage_b_machine_right_shift.m`

检查中断工序的两段加工、受影响时间写入、未受影响工序保持、机器无重叠、
工件顺序和维修区间，并确认 AGV 时间表尚未调整。

```matlab
run(fullfile(pwd,'tests','test_stage_b_machine_right_shift.m'))
```

## 阶段 B 第 5 步测试

`test_stage_b_agv_impact_analysis.m`

检查变化工序计数、中断工序边界、运输完整划分、直接违反原因和同一 AGV
顺序复核标记，并确认 AGV 时间表保持原样。

```matlab
run(fullfile(pwd,'tests','test_stage_b_agv_impact_analysis.m'))
```

## 阶段 B 第 6 步测试

`test_stage_b_agv_linked_right_shift.m`

检查中断工序两段保持、已开始 AGV 活动冻结、AGV 无重叠、运输与加工衔接、
机器无重叠及维修区间。

```matlab
run(fullfile(pwd,'tests','test_stage_b_agv_linked_right_shift.m'))
```

## 阶段 B 第 7 步测试

`test_stage_b_frozen_problem.m`

检查工序与运输完整划分、中断工序两段承诺、工件和故障机器释放时间、AGV
边界，以及阶段 B 专用解码器要求。

```matlab
run(fullfile(pwd,'tests','test_stage_b_frozen_problem.m'))
```

## 阶段 B 第 8 步测试

`test_stage_b_complete_reschedule_decode.m`

检查冻结任务、两段加工承诺、未开工工序解码、机器与工件约束、运输衔接、
最终卸载和能耗计算。

```matlab
run(fullfile(pwd,'tests','test_stage_b_complete_reschedule_decode.m'))
```

## 阶段 B 第 9 步测试

`test_stage_b_reschedule_operators.m`

检查父代与子代的编码长度、工件出现次数、候选机器、AGV 和速度范围，并用
阶段 B 第 8 步解码器验证每个个体。测试还检查固定随机种子的可复现性。

```matlab
run(fullfile(pwd,'tests','test_stage_b_reschedule_operators.m'))
```

## 阶段 B 第 10 步测试

`test_stage_b_restricted_search_contract.m`

检查双目标评价、阶段 B 两段加工解码、非支配排序、Pareto 去重、固定种子
可复现性，以及连续无改善和时间上限两种停止原因。

```matlab
run(fullfile(pwd,'tests','test_stage_b_restricted_search_contract.m'))
```
