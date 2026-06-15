# scripts

## 当前入口

`run_normal_schedule_baseline.m`

作用：

1. 读取阶段 A 正常调度配置。
2. 读取原始算例、机器数据和 AGV 数据。
3. 使用固定随机种子生成一条正常染色体。
4. 调用 `build_normal_schedule` 生成故障前基线。
5. 在内存中返回结果。

该入口不保存 outputs、不绘图、不加入机器故障逻辑。

## 阶段 A 第 2 步入口

`run_stage_a_fault_event.m`

作用：

1. 生成正常调度基线。
2. 读取阶段 A 故障配置。
3. 根据目标工序自动确定故障机器和完成时刻。
4. 创建并校验单机器故障事件。

该入口不提取系统状态，也不执行重调度。

## 阶段 A 第 3 步入口

`run_stage_a_state_snapshot.m`

作用：

1. 使用原项目数据生成正常基线。
2. 创建阶段 A 故障事件。
3. 提取故障时刻工序和 AGV 运输状态。

该入口不修改基线，也不执行重调度。

## 阶段 A 第 4 步入口

`run_stage_a_impact_analysis.m`

作用：

1. 生成阶段 A 状态快照。
2. 建立故障机器维修不可用区间。
3. 识别直接冲突工序。
4. 沿工件与机器后继传播影响。

该入口只输出影响集合，不生成正式右移计划。

## 阶段 A 第 5 步入口

`run_stage_a_machine_right_shift.m`

作用：

1. 生成第 4 步影响集合。
2. 更新受影响工序的候选时间。
3. 重建机器时间表。
4. 验证机器和工件约束。

该入口不调整或验证 AGV 调度。

## 阶段 A 第 6 步入口

`run_stage_a_agv_impact_analysis.m`

作用：

1. 生成机器部分右移候选方案。
2. 比较原工序时间和候选工序时间。
3. 检查负载运输与加工时间约束。
4. 标记同一 AGV 需要连带复核的后续运输。

该入口不修改 AGV 时间表。

## 阶段 A 有效故障场景筛选

`run_stage_a_fault_scenario_screening.m`

作用：

1. 使用原项目数据生成正常基线。
2. 读取当前故障配置中的维修时长。
3. 遍历原机器序列的工序完成时刻。
4. 计算真实影响范围并打印候选表。

该入口不修改故障配置，也不写输出文件。

## 阶段 A 完全重调度确认运行

`run_stage_a_confirmation_search.m`

作用：

1. 读取种群 10、最大 100 代的自适应确认运行配置；
2. 构造当前阶段 A 故障冻结问题；
3. 使用完整完工时间与总能耗运行受限 NSGA-II；
4. 将完整结果、Pareto 目标、每代历史和摘要保存到新的时间戳目录；
5. 返回内存中的完整 `scenario`。

该入口会生成输出，必须在用户确认后由 MATLAB 运行。每次运行使用新目录，不覆盖已有结果。

## 阶段 A 第 9 步：评价与组合选择

`run_stage_a_combination_contract.m`

使用轻量完全重调度搜索验证 `tD`、`SD`、`Y` 和最终选择契约，不生成正式输出。

`run_stage_a_combination_selection.m`

接收已有自适应搜索 `scenario`，复用其中的去重 Pareto 候选，只重新生成确定性的部分右移方案并执行组合选择，不重复运行完全重调度搜索。

## 阶段 A 第 10 步：同等预算正常基线搜索

`run_normal_baseline_search_contract.m`

使用原数据执行 `6` 个体、`2` 代轻量搜索，只验证候选生成、评价、Pareto
去重、固定种子可复现和基线选择契约，不保存输出。

`run_normal_baseline_search.m`

使用与故障后完全重调度相同的自适应预算优化正常计划，并将 MAT 结果、
Pareto 目标、搜索历史和摘要保存到新的时间戳目录。它会生成输出，运行前
需要确认。

## 阶段 A 第 11 步：优化基线故障重定位

`run_stage_a_optimized_baseline_fault_screening.m`

接收第 10 步正式 `normalScenario`，先在优化基线上重新验证配置的 `J5-O1`
和 `tr=5`。若仍有直接影响则保留；否则从优化基线的有效候选中选择排名
第 1 的场景。该入口不修改故障配置，也不执行重调度。

## 阶段 A 第 12 步：重调度链重建

`run_stage_a_rebuilt_rescheduling_chain.m`

接收第 10 步正式 `normalScenario`，调用第 11 步确定故障后，以同一优化
基线和同一故障依次重建状态、影响、机器右移、AGV 影响、AGV 联动和冻结
问题。该入口不运行完全重调度搜索，也不执行组合评价。

## 阶段 A 第 13 步：完全重调度与组合评价

`run_stage_a_step_13_contract.m`

执行 `6` 个体、`2` 代轻量搜索并验证组合评价，不保存输出。

`run_stage_a_step_13_search_and_selection.m`

接收正式 `stage12`，对新冻结问题执行同等预算自适应搜索，再直接使用
`stage12.linked_right_shift` 完成组合评价，避免旧入口重新生成随机基线。
每次正式运行保存到新的时间戳目录。

## 阶段 A 第 14 步：稳健性与约束审计

`run_stage_a_step_14_analysis.m` 复用已有第 13 步候选进行权重敏感性和约束
审计，不重复搜索。

`run_stage_a_step_14_multiseed.m` 使用多个随机种子重复正式搜索，属于长实验，
运行前需要确认。

## 阶段 B 第 1 步

`run_stage_b_processing_fault_state.m`

从现有正常基线创建加工中故障事件，识别故障机器上的在制工序，并计算
已加工时间和剩余加工时间。可传入正式优化基线；无参数调用仅用于轻量
契约测试。该入口不执行右移、完全重调度或搜索。

## 阶段 B 第 2 步

`run_stage_b_resume_rule.m`

在第 1 步状态上确定“保留进度、维修结束后在原机器续加工”规则，并生成
中断工序恢复计划。该入口不传播后续工序，也不执行搜索。

## 阶段 B 第 3 步

`run_stage_b_impact_analysis.m`

以中断工序的新完成时间为根节点，沿工件后继和机器后继计算局部影响集合。
只生成预计时间，不写回机器时间表，不调整 AGV，不执行搜索。

## 阶段 B 第 4 步

`run_stage_b_machine_right_shift.m`

复用第 1 至第 3 步结果，把中断工序恢复计划和受影响工序预计时间写入机器
候选计划。该入口不调整 AGV，也不执行搜索。

## 阶段 B 第 5 步

`run_stage_b_agv_impact_analysis.m`

复用第 4 步机器候选，识别直接违反加工衔接约束的运输及同一 AGV 后续待
复核任务。该入口只分析，不调整运输时间。

## 阶段 B 第 6 步

`run_stage_b_agv_linked_right_shift.m`

正式联动调整 AGV 和机器时间，保留原分配、路线、任务顺序和持续时间，直到
全部运输、机器、工件及维修约束同时满足。

## 阶段 B 第 7 步

`run_stage_b_frozen_problem.m`

建立加工中故障的完全重调度冻结问题，输出固定任务、可重调度工序及机器、
工件和 AGV 边界。本入口不解码候选，也不运行搜索。

## 阶段 B 第 8 步

`run_stage_b_complete_reschedule_decode.m`

使用原基线染色体未开工后缀构造一个种子，并调用阶段 B 专用解码器。该入口
只验证单候选解码，不运行种群搜索或生成输出文件。

## 阶段 B 第 9 步

`run_stage_b_reschedule_operators.m`

固定原基线随机种子，建立 `6` 个受限个体并执行一次交叉和变异。该入口不
计算适应度、不选择下一代、不保存输出。

## 阶段 B 第 10 步

`run_stage_b_restricted_search_contract.m`

运行 `6` 个体、`2` 代的确定性轻量搜索，验证完整搜索契约。它不保存输出，
也不作为正式实验结果。

## 阶段 B 第 11 步

`run_stage_b_complete_search.m`

执行阶段 B 单随机种子正式搜索，并在独立时间戳目录保存 MAT、Pareto CSV、
搜索历史和运行摘要。该入口会生成输出，运行前必须确认。

## 阶段 B 第 12 步

`run_stage_b_combination_selection.m`

加载既有正式搜索场景后，从同一基线重建局部右移候选，验证基线、故障和
中断工序一致，再计算 `tD`、`SD`、`Y` 并选择最终策略。该入口不重新搜索，
也不生成输出文件。

`run_stage_b_combination_contract.m`

使用既有 `6×2` 轻量搜索检查完整组合评价链，不保存结果。

## 阶段 B 第 13 步

`run_stage_b_step_13_analysis.m`

复用既有候选执行权重敏感性、两段加工约束审计和能耗审计，不重复搜索，
不生成输出。

`run_stage_b_step_13_multiseed.m`

对五个随机种子运行同等预算正式搜索，保存 MAT 和汇总 CSV。该入口属于
长实验并生成输出，运行前必须确认。

## 阶段 B-R 第 1 步

`run_stage_br_restart_rule.m`

复用阶段 B 的同一加工中故障状态，生成“进度作废、原机器完整重加工”的
恢复计划。本入口不调整机器后继、AGV 或运行搜索。

## 阶段 B-R 第 2 步

`run_stage_br_impact_analysis.m`

从完整重加工完成时间传播工件和机器后继延迟，只生成预计时间和影响集合，
不写回机器时间表、不调整 AGV、不运行搜索。

## 阶段 B-R 第 3 步

`run_stage_br_machine_right_shift.m`

把第 2 步预计时间写入机器候选，并保留损失加工段和完整重加工段。本入口
复制原 AGV 时间表但不调整或验证 AGV。

## 阶段 B-R 第 4 步

`run_stage_br_agv_impact_analysis.m`

读取机器候选和原 AGV 时间表，识别需要调整或复核的运输任务。本入口只
分析，不修改 AGV。

## 阶段 B-R 第 5 步

`run_stage_br_agv_linked_right_shift.m`

从第 4 步场景生成 AGV 与机器联动局部右移候选，验证运输、机器、工序、
维修区间以及从头加工两段承诺，不运行完全重调度搜索。

## 阶段 B-R 第 6 步

`run_stage_br_frozen_problem.m`

沿用第 5 步场景建立完全重调度冻结问题，只划分冻结任务、释放任务和资源
边界，不解码候选、不运行搜索。

## 阶段 B-R 第 7 步

`run_stage_br_complete_reschedule_decode.m`

从原基线染色体提取未开工任务决策并解码一个完整候选，不运行种群搜索，
不生成正式输出。

## 阶段 B-R 第 8 步

`run_stage_br_reschedule_operators.m`

使用固定随机种子生成 `6` 个父代并执行一次交叉和变异，只建立算子契约，
不评价适应度、不运行代循环。

## 阶段 B-R 第 9 步

`run_stage_br_restricted_search_contract.m`

运行种群 `6`、最大 `2` 代的确定性轻量搜索，只验证完整搜索链，不保存
结果，不作为正式实验。

## 阶段 B-R 第 10 步

`run_stage_br_complete_search.m`

执行单随机种子正式搜索，并保存 MAT、Pareto CSV、搜索历史和运行摘要。
该入口会生成输出，运行前必须确认。

## 阶段 B-R 第 11 步

`run_stage_br_combination_selection.m`

复用已完成搜索场景，从同一基线重建 B-R 局部右移候选并执行组合选择，
不重新搜索、不生成输出。

`run_stage_br_combination_contract.m`

使用 `6×2` 轻量搜索验证组合评价链。

## 阶段 B-R 第 12 步

`run_stage_br_step_12_analysis.m`

复用第 11 步候选执行权重敏感性和最终约束/能耗审计，不重新运行搜索，
不生成输出。

`run_stage_br_step_12_multiseed.m`

使用五个随机种子运行正式 B-R 搜索并保存 MAT 与 CSV。该入口会生成输出，
运行前必须单独确认。

## 阶段 C 第 4 步

`run_stage_c_simultaneous_fault_scenario.m`

从原正常基线筛选并建立两台机器同时故障场景，连接事件规范化、维修区间和
状态快照。本入口不传播影响、不修改计划、不生成输出。

## 阶段 C 第 5 步

`run_stage_c_simultaneous_impact_analysis.m`

在第 4 步场景上分别传播两个故障根并合并影响集合，只计算预计时间，验证
原机器表和 AGV 表保持不变。

## 阶段 C 第 6 步

`run_stage_c_simultaneous_machine_right_shift.m`

把第 5 步预计时间写入机器候选表，并为两个故障在制工序建立保留进度的两段
加工承诺。本入口不调整 AGV 时间表。

## 阶段 C 第 7 步

`run_stage_c_simultaneous_agv_impact_analysis.m`

读取第 6 步机器候选表，识别直接失效运输和同一 AGV 后续待复核运输。本
入口不修改机器表或 AGV 表。

## 阶段 C 第 8 步

`run_stage_c_simultaneous_agv_linked_right_shift.m`

正式调整 AGV 时间并将延迟反馈至机器工序，直到运输和加工约束收敛，同时
保持两个中断工序承诺与所有维修区间。

## 阶段 C 第 9 步

`run_stage_c_simultaneous_frozen_problem.m`

建立同时故障完全重调度的冻结与释放边界，保存多个中断承诺、维修区间和
资源释放状态。本入口不解码候选、不运行搜索。

## 阶段 C 第 10.1 步

`run_stage_c_simultaneous_complete_reschedule_decode.m`

从原基线染色体提取故障时刻后的未开工决策，解码一个同时故障完全重调度
候选，并恢复多个中断工序承诺。本入口不运行种群搜索、不生成输出。
