# 阶段 C 最终总结与代码导读

## 1. 阶段目标

阶段 C 研究的是多机器故障下的 FJSP-AGV 动态重调度问题。它建立在阶段 A
和阶段 B 已完成的单机器故障链路上，扩展到：

1. 多台机器在同一时刻同时故障；
2. 多个故障按时间先后发生；
3. 多故障下的局部右移、完全重调度、AGV 联动和组合选择；
4. 多随机种子下的最终审计。

本阶段仍然使用原项目生产数据。新增内容是故障事件、维修区间和重调度
实验参数，不重新生成生产问题数据。

## 2. 总体流程

```text
原正常调度基线
  ↓
统一 faults[] 故障事件
  ↓
维修不可用区间 + 故障时刻状态提取
  ↓
同时故障或连续故障场景
  ↓
影响传播与合并
  ├─ 局部右移 + AGV 联动
  └─ 冻结问题 + 完全重调度搜索
                         ↓
                  受限 NSGA-II 搜索
  └──────────────────────┘
             ↓
       计算 tD、SD、Y
             ↓
       组合选择最终方案
             ↓
       约束、能耗、多种子审计
```

阶段 C 的重点不是把单故障代码简单复制多次，而是解决多故障带来的三个新
问题：

- 同一工序可能被多个故障传播链同时影响；
- 连续故障必须从上一轮已生效计划继续，不能回到原始基线；
- 多个维修区间、中断承诺和 AGV 运输约束必须同时成立。

## 3. 数学模型

### 3.1 故障事件模型

阶段 C 使用统一的 `faults[]` 结构描述一个或多个故障事件：

```matlab
faults(k).event_id
faults(k).machine_id
faults(k).start_time
faults(k).repair_duration
faults(k).repair_end_time
faults(k).interruption_rule
faults(k).event_group
faults(k).source_order
```

含义：

- `event_id`：故障身份；
- `machine_id`：故障机器；
- `start_time`：故障发生时刻；
- `repair_duration` / `repair_end_time`：维修时长和维修结束时间；
- `interruption_rule`：中断规则，本阶段已验证 `resume_remaining`；
- `event_group`：同一时刻的故障属于同一事件组；
- `source_order`：保留输入顺序，便于追踪结果来源。

代码入口：

- [统一故障事件规范化](../src/fault/normalize_stage_c_fault_events.m)
- [机器维修不可用区间](../src/fault/build_stage_c_machine_unavailability.m)

### 3.2 维修区间约束

每台机器可以有零个、一个或多个维修区间。同一机器上重叠或相接的维修
区间会合并，不同机器的维修区间不能混合。

约束含义：

```text
任意工序加工区间不得与其所在机器的维修不可用区间重叠。
```

对应代码：

- [维修区间生成](../src/fault/build_stage_c_machine_unavailability.m)
- [候选方案审计](../src/evaluation/audit_stage_c_rescheduling_candidate.m)

### 3.3 影响传播模型

故障影响沿两条链传播：

1. 同一工件的后续工序；
2. 同一机器上的后续加工队列。

同时故障下，多个故障根分别传播后合并。若同一道工序被多个来源影响，程序
保留全部来源，并用最严格的时间约束决定其最早可执行时间。

代码入口：

- [同时故障影响传播](../src/impact/identify_stage_c_simultaneous_affected_operations.m)
- [连续故障影响上下文](../src/impact/build_stage_c_sequential_impact_context.m)

## 4. 编码与解码

### 4.1 完全重调度编码

阶段 C 完全重调度继续使用阶段 A/B 已验证的五段决策编码：

| 编码字段 | 含义 |
|---|---|
| `operation_sequence` | 可重调度工序的调度顺序 |
| `machine_choice` | 每道工序选择候选机器中的第几个 |
| `agv_assignment` | 每次运输分配的 AGV |
| `free_speed_choice` | AGV 空载速度档位 |
| `load_speed_choice` | AGV 载货速度档位 |

搜索只改变故障时刻之后尚未开工、且未被冻结的任务。已完成任务、正常在制
任务、中断承诺和维修区间均作为冻结条件输入解码器。

代码入口：

- [同时故障冻结问题](../src/rescheduling/build_stage_c_simultaneous_frozen_problem.m)
- [同时故障解码器](../src/rescheduling/decode_stage_c_simultaneous_complete_reschedule.m)
- [同时/连续故障搜索器](../src/rescheduling/search_stage_c_simultaneous_complete_reschedule.m)

### 4.2 解码器做什么

解码器把一个候选个体转换成完整调度方案。主要工作包括：

1. 保留冻结加工与运输；
2. 写入多个维修不可用区间；
3. 保留一个或多个中断加工承诺；
4. 按 `operation_sequence` 依次安排未开工工序；
5. 根据 `machine_choice` 选择机器；
6. 根据 `agv_assignment` 和速度档位安排空载、负载运输；
7. 确保工序开始不早于工件运输到达；
8. 安排最终卸载；
9. 计算机器能耗、AGV 能耗和总能耗。

连续故障复用同一个 Stage C 解码器，但输入基线不是原始正常计划，而是上一
轮故障处理后的当前计划视图。

相关入口：

- [连续故障当前计划视图](../src/state/build_stage_c_current_plan_view.m)
- [连续故障冻结问题](../scripts/run_stage_c_sequential_frozen_problem.m)
- [连续故障解码入口](../scripts/run_stage_c_sequential_complete_reschedule_decode.m)

## 5. 调度方法

### 5.1 局部右移

局部右移属于局部修复思路。它不改变机器分配和工序相对策略，只把受影响
任务向后推，并把 AGV 运输延迟反馈到机器开工时间。

代码入口：

- [同时故障机器局部右移](../src/rescheduling/build_stage_c_simultaneous_machine_right_shift.m)
- [同时故障 AGV 影响分析](../src/impact/analyze_stage_c_simultaneous_agv_impact.m)
- [同时故障 AGV 联动右移](../src/rescheduling/build_stage_c_simultaneous_agv_linked_right_shift.m)
- [连续故障局部右移入口](../scripts/run_stage_c_sequential_agv_linked_right_shift.m)

### 5.2 完全重调度

完全重调度属于剩余任务全局搜索思路。它冻结历史和承诺任务，只对可重调度
的未开工工序重新搜索。

搜索算法为受限 NSGA-II：

- 双目标：最终卸载完工时间、总能耗；
- 保留 Pareto 去重；
- 支持连续若干代无改善停止；
- 支持最大运行时间停止；
- 正式实验使用多随机种子验证稳定性。

代码入口：

- [同时故障正式搜索入口](../scripts/run_stage_c_simultaneous_complete_search.m)
- [连续故障正式搜索入口](../scripts/run_stage_c_sequential_complete_search.m)
- [最终多种子审计入口](../scripts/run_stage_c_final_audit_multiseed.m)

### 5.3 组合选择

局部右移和完全重调度不是互相替代的单一路线，而是同时生成候选，然后用
评价指标选择：

```text
tD = 候选最终卸载完工时间 - 对应基准计划最终卸载完工时间
SD = 可重调度工序中机器分配发生变化的数量
Y  = omega1 × tD + omega2 × SD
```

本项目默认：

```text
omega1 = 0.9
omega2 = 0.1
```

代码入口：

- [阶段 C 评价指标](../src/evaluation/evaluate_stage_c_rescheduling_plan.m)
- [阶段 C 组合选择](../src/evaluation/select_stage_c_combined_strategy.m)
- [阶段 C 候选审计](../src/evaluation/audit_stage_c_rescheduling_candidate.m)

## 6. 已完成结果

### 6.1 同时故障

正式搜索输出：

```text
outputs/stage_c_simultaneous_complete_reschedule_search/20260615_221423
```

正式组合评价：

| 方案 | 最终卸载 | tD | SD | Y |
|---|---:|---:|---:|---:|
| 局部右移 | 144.2033 | 0 | 0 | 0 |
| 完全重调度 | 116.0833 | -28.1200 | 26 | -22.7080 |

当前权重下选择：`complete_rescheduling`。

### 6.2 连续故障

正式搜索输出：

```text
outputs/stage_c_sequential_complete_reschedule_search/20260616_092142
```

正式组合评价：

| 方案 | 最终卸载 | tD | SD | Y |
|---|---:|---:|---:|---:|
| 局部右移 | 144.2033 | 3.0000 | 0 | 2.7000 |
| 完全重调度 | 113.4900 | -27.7133 | 13 | -23.6420 |

当前权重下选择：`complete_rescheduling`。

### 6.3 最终多随机种子审计

正式输出：

```text
outputs/stage_c_final_audit_multiseed/20260616_094301
```

| 场景 | 运行次数 | 最优 Y | 平均 Y | 最优最终卸载 | 平均最终卸载 | 策略结论 |
|---|---:|---:|---:|---:|---:|---|
| `C-S1` | 5 | -28.9830 | -20.7118 | 109.6667 | 118.7680 | 全部选择完全重调度 |
| `C-SEQ1` | 5 | -23.6420 | -17.8016 | 113.4900 | 119.3127 | 全部选择完全重调度 |

`10` 次运行全部通过约束与能耗审计。

## 7. 验证范围

已验证：

- `faults[]` 支持单故障、同时故障和连续故障输入；
- 同一机器多个维修区间可规范化；
- 同时故障影响集合可合并且保留来源；
- 同时故障可生成局部右移和完全重调度方案；
- 连续故障可从当前计划继续，不回滚历史；
- AGV 运输可随机器时间变化联动调整；
- 完全重调度可处理多个维修区间和多个中断承诺；
- 局部右移和完全重调度均可计算 `tD、SD、Y`；
- 可运行场景完成多随机种子审计。

尚未覆盖：

- `C-S2`：同时故障且中断规则为从头加工；
- `C-SEQ2`：后一故障发生时前一机器仍在维修；
- 不同故障事件使用不同中断规则的混合场景；
- 更大种群、更长代数或更多实例的统计实验。

## 8. 代码入口地图

| 模块 | 主要代码 |
|---|---|
| 故障事件 | [normalize_stage_c_fault_events.m](../src/fault/normalize_stage_c_fault_events.m) |
| 维修区间 | [build_stage_c_machine_unavailability.m](../src/fault/build_stage_c_machine_unavailability.m) |
| 事件组状态 | [extract_stage_c_event_group_state.m](../src/state/extract_stage_c_event_group_state.m) |
| 同时故障筛选 | [screen_stage_c_simultaneous_fault_scenarios.m](../src/screening/screen_stage_c_simultaneous_fault_scenarios.m) |
| 影响传播 | [identify_stage_c_simultaneous_affected_operations.m](../src/impact/identify_stage_c_simultaneous_affected_operations.m) |
| AGV 影响 | [analyze_stage_c_simultaneous_agv_impact.m](../src/impact/analyze_stage_c_simultaneous_agv_impact.m) |
| 局部右移 | [build_stage_c_simultaneous_machine_right_shift.m](../src/rescheduling/build_stage_c_simultaneous_machine_right_shift.m) |
| AGV 联动右移 | [build_stage_c_simultaneous_agv_linked_right_shift.m](../src/rescheduling/build_stage_c_simultaneous_agv_linked_right_shift.m) |
| 冻结问题 | [build_stage_c_simultaneous_frozen_problem.m](../src/rescheduling/build_stage_c_simultaneous_frozen_problem.m) |
| 解码器 | [decode_stage_c_simultaneous_complete_reschedule.m](../src/rescheduling/decode_stage_c_simultaneous_complete_reschedule.m) |
| 搜索器 | [search_stage_c_simultaneous_complete_reschedule.m](../src/rescheduling/search_stage_c_simultaneous_complete_reschedule.m) |
| 评价与组合 | [evaluate_stage_c_rescheduling_plan.m](../src/evaluation/evaluate_stage_c_rescheduling_plan.m)、[select_stage_c_combined_strategy.m](../src/evaluation/select_stage_c_combined_strategy.m) |
| 候选审计 | [audit_stage_c_rescheduling_candidate.m](../src/evaluation/audit_stage_c_rescheduling_candidate.m) |
| 连续故障计划版本 | [initialize_stage_c_plan_history.m](../src/state/initialize_stage_c_plan_history.m)、[append_stage_c_plan_version.m](../src/state/append_stage_c_plan_version.m)、[resolve_stage_c_active_plan.m](../src/state/resolve_stage_c_active_plan.m) |
| 最终多种子入口 | [run_stage_c_final_audit_multiseed.m](../scripts/run_stage_c_final_audit_multiseed.m) |

## 9. 测试入口

阶段 C 的测试从第 1 步到第 17.2 步逐步推进。常用入口：

- [统一故障事件测试](../tests/test_stage_c_fault_events.m)
- [机器不可用区间测试](../tests/test_stage_c_machine_unavailability.m)
- [同时故障影响传播测试](../tests/test_stage_c_simultaneous_impact_analysis.m)
- [同时故障 AGV 联动测试](../tests/test_stage_c_simultaneous_agv_linked_right_shift.m)
- [同时故障完全重调度解码测试](../tests/test_stage_c_simultaneous_complete_reschedule_decode.m)
- [连续故障当前状态测试](../tests/test_stage_c_next_fault_state.m)
- [连续故障组合评价测试](../tests/test_stage_c_sequential_combination_contract.m)
- [最终审计矩阵测试](../tests/test_stage_c_final_audit_matrix_config.m)
- [最终多种子配置测试](../tests/test_stage_c_final_audit_multiseed_config.m)

## 10. 阶段结论

阶段 C 已经把机器故障动态重调度从“单机器故障”扩展到“多机器同时故障”和
“连续故障”的可运行程序链路。

在当前已实现并正式审计的 `C-S1` 和 `C-SEQ1` 场景中，完全重调度在默认
`0.9/0.1` 权重下稳定优于局部右移。但该结论只覆盖当前原数据、当前故障
筛选场景和当前搜索预算，不能外推到尚未实现的 `C-S2`、`C-SEQ2` 或更大
规模实验。
