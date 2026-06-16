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

## 阶段 B 第 11 步测试

`test_stage_b_complete_search_config.m`

只检查正式搜索参数、相对输出路径和运行入口是否存在，不运行搜索、不创建
输出目录。

```matlab
run(fullfile(pwd,'tests','test_stage_b_complete_search_config.m'))
```

## 阶段 B 第 12 步测试

`test_stage_b_combination_contract.m`

检查权重、`tD`、`SD`、`Y` 公式、局部右移零机器变化、两段加工搜索标志及
最小 `Y` 选择规则。测试使用轻量搜索，不读取正式输出。

```matlab
run(fullfile(pwd,'tests','test_stage_b_combination_contract.m'))
```

## 阶段 B 第 13 步测试

`test_stage_b_step_13_contract.m`

检查 11 组权重、五个种子配置、中断工序两段承诺、维修区间、最终卸载和
能耗闭合。测试只使用轻量契约搜索，不运行多随机种子实验。

```matlab
run(fullfile(pwd,'tests','test_stage_b_step_13_contract.m'))
```

## 阶段 B-R 第 1 步测试

`test_stage_br_restart_rule.m`

检查故障前加工被标记为损失、修复后完整重加工、机器不迁移、有效完成加工
时间和总机器加工时间的区别。

```matlab
run(fullfile(pwd,'tests','test_stage_br_restart_rule.m'))
```

## 阶段 B-R 第 2 步测试

`test_stage_br_impact_analysis.m`

检查完整重加工根节点、损失加工字段、未开始工序划分和预计延迟，并与阶段 B
保留进度场景比较根延迟和影响数量。

```matlab
run(fullfile(pwd,'tests','test_stage_br_impact_analysis.m'))
```

## 阶段 B-R 第 3 步测试

`test_stage_br_machine_right_shift.m`

检查逻辑工序完整性、损失加工段、完整重加工段、受影响工序时间、机器无
重叠、工序优先关系和维修区间。

```matlab
run(fullfile(pwd,'tests','test_stage_br_machine_right_shift.m'))
```

## 阶段 B-R 第 4 步测试

`test_stage_br_agv_impact_analysis.m`

检查完整重加工根节点、变化工序数量、运输集合完整划分、直接违反原因和
同一 AGV 顺序复核标记。

```matlab
run(fullfile(pwd,'tests','test_stage_br_agv_impact_analysis.m'))
```

## 阶段 B-R 第 5 步测试

`test_stage_br_agv_linked_right_shift.m`

检查 AGV 分配、路线和持续时间保持不变，同一 AGV 无冲突，运输延迟正确
反馈至机器，并验证损失加工段、完整重加工段和维修区间约束。

```matlab
run(fullfile(pwd,'tests','test_stage_br_agv_linked_right_shift.m'))
```

## 阶段 B-R 第 6 步测试

`test_stage_br_frozen_problem.m`

检查工序和运输完整分区、损失加工与完整重加工承诺、候选机器数据，以及
工件、机器和 AGV 的故障时刻边界。

```matlab
run(fullfile(pwd,'tests','test_stage_br_frozen_problem.m'))
```

## 阶段 B-R 第 7 步测试

`test_stage_br_complete_reschedule_decode.m`

检查冻结任务、候选机器、AGV 运输、维修区间、损失加工段、完整重加工段，
并独立复算包含损失加工的机器能耗。

```matlab
run(fullfile(pwd,'tests','test_stage_br_complete_reschedule_decode.m'))
```

## 阶段 B-R 第 8 步测试

`test_stage_br_reschedule_operators.m`

检查父代和子代的 OS 工件次数、机器选择、AGV、速度范围及固定随机种子的
可复现性，并要求每个个体通过 B-R 完全重调度解码器。

```matlab
run(fullfile(pwd,'tests','test_stage_br_reschedule_operators.m'))
```

## 阶段 B-R 第 9 步测试

`test_stage_br_restricted_search_contract.m`

检查双目标评价、非支配排序、Pareto 去重、固定随机种子复现，以及最大代数、
连续无改善和时间上限停止契约。

```matlab
run(fullfile(pwd,'tests','test_stage_br_restricted_search_contract.m'))
```

## 阶段 B-R 第 10 步测试

`test_stage_br_complete_search_config.m`

只检查正式搜索参数、相对输出路径和运行入口，不运行搜索，也不创建输出。

```matlab
run(fullfile(pwd,'tests','test_stage_br_complete_search_config.m'))
```

## 阶段 B-R 第 11 步测试

`test_stage_br_combination_contract.m`

检查从头加工语义、权重、`tD`、`SD`、`Y` 公式、局部右移零机器变化及
最小 `Y` 选择规则。

```matlab
run(fullfile(pwd,'tests','test_stage_br_combination_contract.m'))
```

## 阶段 B-R 第 12 步测试

`test_stage_br_step_12_contract.m`

复用轻量第 11 步候选，检查 11 组权重、从头加工承诺、维修区间、最终卸载
和能耗闭合。测试不运行五随机种子实验，不创建输出。

```matlab
run(fullfile(pwd,'tests','test_stage_br_step_12_contract.m'))
```

## 阶段 C 第 1 步测试

`test_stage_c_fault_events.m`

检查统一故障数组的字段校验、时间排序、来源顺序、同时故障分组，以及重复
编号、非法机器、非法中断规则和错误维修结束时间。测试只使用最小事件参数，
不生成生产问题数据，不运行调度算法。

```matlab
run(fullfile(pwd,'tests','test_stage_c_fault_events.m'))
```

## 阶段 C 第 2 步测试

`test_stage_c_machine_unavailability.m`

检查同机重叠区间、相接区间和分离区间，不同机器区间、无故障机器空数组，
以及合并后来源事件完整性。测试不运行调度算法，不生成输出。

```matlab
run(fullfile(pwd,'tests','test_stage_c_machine_unavailability.m'))
```

## 阶段 C 第 3 步测试

`test_stage_c_event_group_state.m`

从原项目正常基线动态寻找至少两台机器同时加工的时刻，检查工序四类状态、
故障在制工序来源、AGV 三类运输状态和活动 AGV。测试不生成生产问题数据，
不修改基线，不执行重调度。

```matlab
run(fullfile(pwd,'tests','test_stage_c_event_group_state.m'))
```

## 阶段 C 第 4 步测试

`test_stage_c_simultaneous_fault_scenario.m`

检查原基线候选筛选、两台机器直接中断、候选排序、统一中断规则、维修区间
和状态快照。测试不传播影响，不执行重调度，不生成输出。

```matlab
run(fullfile(pwd,'tests','test_stage_c_simultaneous_fault_scenario.m'))
```

## 阶段 C 第 5 步测试

`test_stage_c_simultaneous_impact_analysis.m`

检查双根独立传播、影响集合去重、全部故障来源、最大预计时间、未开工工序
完整分区和输入顺序无关性。测试不修改机器或 AGV 时间表。

```matlab
run(fullfile(pwd,'tests','test_stage_c_simultaneous_impact_analysis.m'))
```

## 阶段 C 第 6 步测试

`test_stage_c_simultaneous_machine_right_shift.m`

检查两个中断工序的两段加工承诺、合并影响时间写入、机器无重叠、工件先后
约束、维修区间不可加工、未受影响工序保持不变以及 AGV 表未调整。

```matlab
run(fullfile(pwd,'tests', ...
    'test_stage_c_simultaneous_machine_right_shift.m'))
```

## 阶段 C 第 7 步测试

`test_stage_c_simultaneous_agv_impact_analysis.m`

检查直接失效运输、同一 AGV 后继复核、运输去重、故障来源保留、完整分区、
输入顺序无关性以及 AGV 表保持不变。

```matlab
run(fullfile(pwd,'tests', ...
    'test_stage_c_simultaneous_agv_impact_analysis.m'))
```

## 阶段 C 第 8 步测试

`test_stage_c_simultaneous_agv_linked_right_shift.m`

检查 AGV 无重叠、运输就绪、运输先于加工、机器和工件约束、多个维修区间、
双中断承诺、最终卸载及故障输入顺序无关性。

```matlab
run(fullfile(pwd,'tests', ...
    'test_stage_c_simultaneous_agv_linked_right_shift.m'))
```

## 阶段 C 第 9 步测试

`test_stage_c_simultaneous_frozen_problem.m`

检查工序与运输完整分区、双中断承诺、多维修区间、候选机器数据、工件和
资源边界、AGV 电量边界及故障输入顺序无关性。

```matlab
run(fullfile(pwd,'tests', ...
    'test_stage_c_simultaneous_frozen_problem.m'))
```

## 阶段 C 第 10.1 步测试

`test_stage_c_simultaneous_complete_reschedule_decode.m`

检查冻结任务不变、多个中断工序各自展开为两段加工、全部维修区间无加工、
机器无重叠、工件顺序、最终卸载以及机器和 AGV 能耗字段完整。

```matlab
run(fullfile(pwd,'tests', ...
    'test_stage_c_simultaneous_complete_reschedule_decode.m'))
```

## 阶段 C 第 10.2 步测试

`test_stage_c_simultaneous_reschedule_operators.m`

检查固定随机种子可复现、OS 多重集合不变、MS/AS/SS 均在原数据范围内，
并逐个使用阶段 C 多中断解码器验证父代和子代。

```matlab
run(fullfile(pwd,'tests', ...
    'test_stage_c_simultaneous_reschedule_operators.m'))
```

## 阶段 C 第 10.3 步测试

`test_stage_c_simultaneous_restricted_search_contract.m`

检查双目标评价、非支配排序、Pareto 去重、固定随机种子可复现、全部多中断
和维修约束，以及无改善停止和时间上限停止。

```matlab
run(fullfile(pwd,'tests', ...
    'test_stage_c_simultaneous_restricted_search_contract.m'))
```

## 阶段 C 第 10.4 步测试

`test_stage_c_simultaneous_complete_search_config.m`

只检查正式参数、相对输出目录和运行入口是否存在，不调用搜索、不创建输出。

```matlab
run(fullfile(pwd,'tests', ...
    'test_stage_c_simultaneous_complete_search_config.m'))
```

## 阶段 C 第 11 步测试

`test_stage_c_combination_contract.m`

检查 `tD、SD、Y`、Pareto 多候选选择、多个维修区间、多个中断承诺、最终
卸载和机器/AGV 能耗闭合。

```matlab
run(fullfile(pwd,'tests','test_stage_c_combination_contract.m'))
```

## 阶段 C 第 12 步测试

`test_stage_c_plan_version_history.m`

检查版本编号、前驱关系、生效时刻、来源事件、选定策略、历史不可覆盖，以及
故障前后解析到正确的计划版本。

```matlab
run(fullfile(pwd,'tests','test_stage_c_plan_version_history.m'))
```

## 阶段 C 第 13 步测试

`test_stage_c_next_fault_state.m`

检查下一故障确实来自 `V1`、事件编号顺延、工序完整分区、新故障在制工序、
旧维修列表以及 `V0/V1` 历史保持不变。

```matlab
run(fullfile(pwd,'tests','test_stage_c_next_fault_state.m'))
```

## 阶段 C 第 14 步测试

`test_stage_c_sequential_impact_context.m`

检查累计维修事件完整覆盖、新故障影响传播、影响集合去重、来源事件保留、
未开工工序完整分区以及版本历史保持不变。

```matlab
run(fullfile(pwd,'tests', ...
    'test_stage_c_sequential_impact_context.m'))
```

## 阶段 C 第 15 步测试

`test_stage_c_sequential_agv_linked_right_shift.m`

检查连续故障局部右移、AGV 联动、单个中断承诺、机器非重叠、维修区间、
AGV 非重叠和运输到达约束。

```matlab
run(fullfile(pwd,'tests', ...
    'test_stage_c_sequential_agv_linked_right_shift.m'))
```

## 阶段 C 第 16.1 步测试

`test_stage_c_sequential_frozen_problem.m`

检查连续故障完全重调度冻结边界、单个中断承诺、工件/机器/AGV 释放边界，
以及运输集合完整分区。

```matlab
run(fullfile(pwd,'tests','test_stage_c_sequential_frozen_problem.m'))
```

## 阶段 C 第 16.2 步测试

`test_stage_c_sequential_complete_reschedule_decode.m`

检查连续故障完全重调度轻量候选、冻结工序、中断两段加工承诺、维修区间、
工件顺序、机器非重叠和能耗闭合。

```matlab
run(fullfile(pwd,'tests', ...
    'test_stage_c_sequential_complete_reschedule_decode.m'))
```

## 阶段 C 第 16.3 步测试

- `test_stage_c_sequential_reschedule_operators.m`
- `test_stage_c_sequential_restricted_search_contract.m`

前者检查连续故障受限种群初始化、交叉变异和固定随机种子复现；后者检查
`6×2` 轻量 NSGA-II、候选评价、Pareto 去重和自适应停止分支。

```matlab
run(fullfile(pwd,'tests','test_stage_c_sequential_reschedule_operators.m'))
run(fullfile(pwd,'tests', ...
    'test_stage_c_sequential_restricted_search_contract.m'))
```

## 阶段 C 第 16.4 步测试

`test_stage_c_sequential_complete_search_config.m`

只检查正式参数、相对输出目录和运行入口是否存在，不调用搜索、不创建输出。

```matlab
run(fullfile(pwd,'tests', ...
    'test_stage_c_sequential_complete_search_config.m'))
```

## 阶段 C 第 16.5 步测试

`test_stage_c_sequential_combination_contract.m`

使用第 16.3 步轻量搜索结果验证连续故障局部右移与完全重调度候选的
`tD、SD、Y`、最终选择、维修区间、中断承诺和能耗审计。

```matlab
run(fullfile(pwd,'tests','test_stage_c_sequential_combination_contract.m'))
```

## 阶段 C 第 16.6 步

第 16.6 步为结果总结文档，不新增 MATLAB 测试。结果来自第 16.4 正式搜索和
第 16.5 正式组合评价。

## 阶段 C 第 17.1 步测试

`test_stage_c_final_audit_matrix_config.m`

检查最终审计场景矩阵、多随机种子、正式搜索参数和审计项定义。本测试不运行
正式实验、不创建输出。

```matlab
run(fullfile(pwd,'tests','test_stage_c_final_audit_matrix_config.m'))
```

## 阶段 C 第 17.2 步测试

`test_stage_c_final_audit_multiseed_config.m`

检查最终审计多随机种子入口只覆盖已实现的 `C-S1` 和 `C-SEQ1`，确认五个
随机种子、正式搜索预算、输出目录和运行入口存在。本测试不运行正式实验、
不创建输出。

```matlab
run(fullfile(pwd,'tests','test_stage_c_final_audit_multiseed_config.m'))
```

## 阶段 C 第 18 步

第 18 步为总结和代码导读文档，不新增 MATLAB 测试。结果来自第 10.4、
第 11、 第 16.4、 第 16.5 和第 17.2 的正式输出与组合评价。

## C-S2 第 1 步测试

`test_stage_cs2_restart_commitments.m`

检查同时故障下多个中断工序的从头加工承诺：故障前加工段作废、修复后完整
重加工、进度不保留、机器不迁移。本测试不传播影响、不修改机器或 AGV 时间表。

```matlab
run(fullfile(pwd,'tests','test_stage_cs2_restart_commitments.m'))
```

## C-S2 第 2 步测试

`test_stage_cs2_impact_analysis.m`

检查从头加工完成时间是否正确传播到同工件后续工序和同机器后续队列，验证
多故障源合并、来源保留和输入表不变。本测试不修改机器或 AGV 时间表。

```matlab
run(fullfile(pwd,'tests','test_stage_cs2_impact_analysis.m'))
```

## C-S2 第 3 步测试

`test_stage_cs2_machine_right_shift.m`

检查 C-S2 机器局部右移候选：损失加工段、完整重加工段、受影响工序时间、
维修区间、机器非重叠、工件顺序和输入表不变。本测试不调整 AGV。

```matlab
run(fullfile(pwd,'tests','test_stage_cs2_machine_right_shift.m'))
```

## C-S2 第 4 步测试

`test_stage_cs2_agv_impact_analysis.m`

检查 C-S2 机器时间变化对 AGV 运输的影响：直接违规、同 AGV 后续复核、
运输集合划分、故障来源保留，以及从头加工规则信息保留。本测试不修改 AGV。

```matlab
run(fullfile(pwd,'tests','test_stage_cs2_agv_impact_analysis.m'))
```

## C-S2 第 5 步测试

`test_stage_cs2_agv_linked_right_shift.m`

检查 C-S2 AGV 与机器联动右移候选：AGV 不重叠、运输约束、最终卸载、维修
区间、从头加工两段承诺和输入顺序无关性。本测试不运行搜索。

```matlab
run(fullfile(pwd,'tests','test_stage_cs2_agv_linked_right_shift.m'))
```

## C-S2 第 6 步测试

`test_stage_cs2_frozen_problem.m`

检查 C-S2 完全重调度冻结边界：冻结/可重调工序划分、多个从头加工承诺、
维修区间、工件/机器/AGV 边界和运输集合划分。本测试不运行搜索。

```matlab
run(fullfile(pwd,'tests','test_stage_cs2_frozen_problem.m'))
```

## C-S2 第 7 步测试

`test_stage_cs2_complete_reschedule_decode.m`

检查 C-S2 完全重调度解码器：冻结工序不变、多个从头加工承诺保留、损失
加工计入机器工作能耗、维修区间、工件顺序、机器不重叠和最终卸载约束。
本测试不运行搜索。

```matlab
run(fullfile(pwd,'tests','test_stage_cs2_complete_reschedule_decode.m'))
```

## C-S2 第 8 步测试

`test_stage_cs2_reschedule_operators.m`

检查 C-S2 受限种群初始化、交叉和变异：固定随机种子可复现，OS/MS/AS/SS
取值范围合法，父代和子代均能通过 C-S2 第 7 步解码器。本测试不运行搜索。

```matlab
run(fullfile(pwd,'tests','test_stage_cs2_reschedule_operators.m'))
```

## C-S2 第 9 步测试

`test_stage_cs2_restricted_search_contract.m`

检查 C-S2 候选评价与受限搜索契约：最终卸载时间、总能耗、Pareto 去重、
从头加工标记、损失加工时间、无改善停止和时间上限停止。本测试不是正式实验。

```matlab
run(fullfile(pwd,'tests','test_stage_cs2_restricted_search_contract.m'))
```

## C-S2 第 10 步测试

`test_stage_cs2_complete_search_config.m`

检查 C-S2 正式搜索配置和保存入口是否存在，确认预算为 `10×100`、连续
`10` 代无改善或 `30` 秒停止。本测试不运行正式搜索、不生成输出。

```matlab
run(fullfile(pwd,'tests','test_stage_cs2_complete_search_config.m'))
```

## C-S2 第 11 步测试

`test_stage_cs2_combination_contract.m`

检查 C-S2 局部右移与完全重调度候选的 `tD、SD、Y` 组合评价，以及 C-S2
专用从头加工承诺审计。本测试不读取正式输出目录。

```matlab
run(fullfile(pwd,'tests','test_stage_cs2_combination_contract.m'))
```
