# FJSP-AGV 机器故障动态重调度

本仓库用于在现有 FJSP-AGV 正常调度代码基础上，研究机器故障发生后的动态重调度问题。

## 项目目标

建立一个支持一个或多个机器故障事件的 FJSP-AGV 动态重调度程序，实现：

- 部分右移重调度；
- 未开工工序完全重调度；
- 基于完工时间偏差和序列偏差的组合选择；
- 工序调整后的 AGV 运输联动；
- 单机器故障、同时故障和连续故障场景。

单机器故障仅作为第一个验证场景，不是最终能力边界。

## 项目入口

| 入口 | 内容 |
|---|---|
| [实施计划](docs/machine_fault_rescheduling_plan.md) | 总体工作流程、阶段划分、验收标准和当前执行边界 |
| [问题定义](docs/problem_definition.md) | 机器故障动态重调度的问题范围与基本假设 |
| [研究架构](docs/research_architecture.md) | 模块划分、调度策略和 AGV 联动设计 |
| [阶段 A 结构与代码导读](docs/stage_a_structure_and_code_guide.md) | 数学模型、编码、解码、算法、测试及可点击源码入口 |
| [阶段 A 最终总结](docs/stage_a_final_summary.md) | 阶段 A 成果、正式结果、验证结论、适用边界及阶段 B 交接 |
| [阶段 B 最终总结](docs/stage_b_final_summary.md) | 加工中故障成果、正式结果、验证结论、适用边界及下一步路线 |
| [阶段 C 最终总结与代码导读](docs/stage_c_final_summary_and_code_guide.md) | 多机器同时故障、连续故障、最终审计结果和代码入口 |
| [项目总收口](docs/project_final_summary.md) | 阶段 A、B、B-R、C 的总体成果、结论、限制和后续建议 |
| [结论证据与读数指南](docs/conclusion_evidence_guide.md) | 汇报结论从哪些指标和值得出，如何读取结果 |
| [未覆盖场景补充计划](docs/uncovered_scenarios_plan.md) | C-S2 和 C-SEQ2 的补充路线、优先级和完成标准 |
| [C-S2 第 1 步：从头加工中断承诺](docs/stage_cs2_step_01_restart_commitments.md) | 同时故障下为多个中断工序建立损失加工段和完整重加工段 |
| [阶段 B-R 第 1 步：从头加工规则](docs/stage_br_step_01_restart_rule.md) | 进度作废，修复后原机器完整重加工 |
| [阶段 B-R 第 2 步：影响传播](docs/stage_br_step_02_impact_propagation.md) | 从完整重加工完成时间传播工件和机器后继影响 |
| [阶段 B-R 第 3 步：机器局部右移](docs/stage_br_step_03_machine_right_shift.md) | 写入损失加工段、完整重加工段和受影响工序时间 |
| [阶段 B-R 第 4 步：AGV 影响分析](docs/stage_br_step_04_agv_impact_analysis.md) | 识别完整重加工后失效及待复核的运输任务 |
| [阶段 B-R 第 5 步：AGV 与机器联动](docs/stage_br_step_05_agv_linked_right_shift.md) | 调整运输并把延迟反馈到机器工序，保留损失段和完整重加工段 |
| [阶段 B-R 第 6 步：完全重调度冻结问题](docs/stage_br_step_06_frozen_problem.md) | 冻结历史任务和从头加工承诺，释放未开工任务 |
| [阶段 B-R 第 7 步：完全重调度解码器](docs/stage_br_step_07_complete_decoder.md) | 解码未开工任务并保留损失段、完整重加工段和能耗语义 |
| [阶段 B-R 第 8 步：受限种群算子](docs/stage_br_step_08_reschedule_operators.md) | 初始化、交叉和变异未开工任务决策，并逐个解码验证 |
| [阶段 B-R 第 9 步：轻量搜索契约](docs/stage_br_step_09_restricted_search.md) | 双目标评价、NSGA-II 主循环、Pareto 去重与自适应停止 |
| [阶段 B-R 第 10 步：正式搜索入口](docs/stage_br_step_10_formal_search_entry.md) | 单种子正式预算、独立结果目录和保存文件 |
| [阶段 B-R 第 11 步：组合策略选择](docs/stage_br_step_11_combination_selection.md) | 计算局部右移与完全重调度的 tD、SD、Y 并选择策略 |
| [阶段 B 第 1 步：加工中故障状态](docs/stage_b_step_01_processing_fault_state.md) | 定义加工中故障事件，识别在制工序并计算已加工与剩余加工时间 |
| [阶段 B 第 2 步：暂停后续加工](docs/stage_b_step_02_resume_rule.md) | 保留已加工进度，维修结束后在原机器继续剩余加工时间 |
| [阶段 B 第 3 步：延迟影响传播](docs/stage_b_step_03_impact_propagation.md) | 从中断工序新完成时间沿工件和机器后继生成局部影响集合 |
| [阶段 B 第 11 步：正式搜索结果](docs/stage_b_step_11_formal_search_entry.md) | 单随机种子正式搜索配置、输出及 47 代停止结果 |
| [阶段 B 第 12 步：评价与组合选择](docs/stage_b_step_12_combination_selection.md) | 计算局部右移与完全重调度的 tD、SD、Y 并选择最终策略 |
| [阶段 B 第 13 步：稳健性与约束审计](docs/stage_b_step_13_robustness_audit.md) | 权重敏感性、多随机种子入口及两段加工最终审计 |
| [阶段 A 第 1 步：正常调度基线](docs/stage_a_step_01_normal_baseline.md) | 为什么先建立正常计划、具体实现、输入输出和验证状态 |
| [阶段 A 第 2 步：工序完成时故障事件](docs/stage_a_step_02_completion_fault_event.md) | 故障事件字段、完成时刻选择、校验规则和测试状态 |
| [阶段 A 第 3 步：故障时刻状态快照](docs/stage_a_step_03_state_snapshot.md) | 已完成、进行中和未开始的工序及 AGV 运输分类 |
| [阶段 A 第 4 步：维修区间与影响识别](docs/stage_a_step_04_impact_identification.md) | 直接维修冲突及工件、机器后继传播范围 |
| [阶段 A 第 5 步：机器部分右移方案](docs/stage_a_step_05_machine_right_shift.md) | 将受影响时间写入机器候选表并验证机器和工艺约束 |
| [阶段 A 第 6 步：AGV 运输影响分析](docs/stage_a_step_06_agv_impact_analysis.md) | 检查机器时间变化是否使原运输约束失效 |
| [阶段 A 第 7 步：AGV 与机器联动右移](docs/stage_a_step_07_agv_linked_right_shift.md) | 正式调整 AGV 时间，并将运输延迟反馈到机器工序 |
| [阶段 A 第 8.1 步：故障冻结问题](docs/stage_a_step_08_1_frozen_problem.md) | 冻结已完成和在制任务，释放未开工工序与运输决策 |
| [阶段 A 第 8.2a 步：完全重调度解码器](docs/stage_a_step_08_2a_complete_decoder.md) | 解码未开工工序的顺序、机器、AGV 和速度决策 |
| [阶段 A 第 8.2b 步：受限搜索算子](docs/stage_a_step_08_2b_restricted_operators.md) | 为未开工工序建立初始化、IPOX/MPX 交叉和受限变异 |
| [阶段 A 第 8.2c 步：受限 NSGA-II](docs/stage_a_step_08_2c_restricted_search.md) | 使用最终卸载完工时间与总能耗验证轻量搜索主循环 |
| [阶段 A 第 8.2d 步：最终卸载与完整能耗](docs/stage_a_step_08_2d_energy_and_unload.md) | 恢复最终卸载、AGV 电量与充电、机器和 AGV 完整能耗 |
| [阶段 A 完全重调度确认运行](docs/stage_a_confirmation_search.md) | 种群 10、最大 100 代及自适应停止规则 |
| [阶段 A 第 9 步：评价指标与组合选择](docs/stage_a_combination_selection.md) | 计算右移与完全重调度候选的 tD、SD、Y 并选择最终方案 |
| [阶段 A 第 10 步：同等预算正常基线搜索](docs/normal_baseline_search.md) | 仅用原数据优化故障前正常计划，修正故障前后搜索预算不公平 |
| [阶段 A 第 11 步：优化基线故障重定位](docs/stage_a_step_11_optimized_fault_screening.md) | 验证 J5-O1 是否仍有效，失效时从优化基线动态选择有效场景 |
| [阶段 A 第 12 步：重调度链重建](docs/stage_a_step_12_rebuilt_chain.md) | 使用优化基线和 J8-O1 故障重建右移、AGV 联动与冻结问题 |
| [阶段 A 第 13 步：完全重调度与组合评价](docs/stage_a_step_13_search_and_selection.md) | 对 53 道未开工工序搜索并公平比较右移与完全重调度 |
| [阶段 A 第 14 步：稳健性与约束审计](docs/stage_a_step_14_robustness_audit.md) | 多种子、权重敏感性及最终候选约束审计 |
| [阶段 A 有效故障场景筛选](docs/stage_a_fault_scenario_screening.md) | 基于原机器时间表筛选维修时长 5 下会产生真实影响的故障位置 |
| [原始代码](raw_code/) | 原项目完整只读快照，是后续修改和对照的基础 |

后续形成新的设计说明、实验记录和阶段工作表时，继续在本 README 中增加入口。

## 研究路线

项目不是一次同时实现所有故障类型，而是按三个研究阶段推进：

1. **阶段 A：工序完成时单机器故障**  
   先复现论文主流程，验证部分右移、完全重调度、AGV 联动和组合选择，暂时避开在制工序中断问题。
2. **阶段 B：加工中单机器故障**  
   增加在制工序状态、剩余加工时间和修复后续加工规则，使程序支持任意时刻单机器故障。
3. **阶段 C：多机器故障**  
   在单机器逻辑稳定后，扩展到多台机器同时故障和多个故障连续发生。

每个阶段内部都遵循“定义场景、提取状态、生成局部方案、生成完全重调度方案、联动 AGV、评价选择、验证约束”的共同流程。详细步骤见[实施计划](docs/machine_fault_rescheduling_plan.md)。

## 调度思路

本项目同时保留局部优化与全局优化思路：

1. 部分右移重调度：只传播并修复故障造成的直接和间接影响，属于局部调整。
2. 完全重调度：冻结已完成或不可改变的任务，对剩余任务重新优化。
3. 组合策略：分别生成两类方案，使用评价指标选择表现更好的方案。

原项目中的 AGV 单任务约束、空载与负载运输时间、运输到达后才能加工等约束保持不变。

## 当前状态

- 已建立独立机器故障项目；
- 已保存原始代码只读快照；
- 已完成机器故障动态重调度工作流程和分阶段计划；
- 阶段 A 第 1 步已完成，正常调度入口通过 MATLAB 契约测试；
- 阶段 A 第 2 步已完成并通过 MATLAB 测试；
- 阶段 A 第 3 步状态快照已通过 MATLAB 测试；
- 阶段 A 第 4 步影响范围识别已通过 MATLAB 测试；
- 阶段 A 第 5 步机器部分右移已通过 MATLAB 测试；
- 阶段 A 第 6 步 AGV 影响分析已通过 MATLAB 测试；
- 有效故障场景筛选已通过 MATLAB 测试，共得到 26 个原数据候选；
- 已确认原基线候选第 1 名 `J5-O1 / M5 / tf=6 / tr=5` 为有效故障场景；
- 阶段 A 第 7 步 AGV 与机器联动右移已通过 MATLAB 测试；
- 阶段 A 第 8.1 步故障冻结问题已通过 MATLAB 测试；
- 阶段 A 第 8.2a 步完全重调度冻结解码器已通过 MATLAB 测试；
- 阶段 A 第 8.2b 步受限种群初始化、交叉和变异已通过 MATLAB 测试；
- 阶段 A 第 8.2c 步候选评价与受限 NSGA-II 主循环已通过 MATLAB 轻量契约测试；
- 阶段 A 第 8.2d 步最终卸载、AGV 电量/充电和完整能耗已完成并通过 MATLAB 契约测试；
- 完全重调度 10×20 确认运行已执行三次，固定种子结果一致；最新一次去重后得到 3 个 Pareto 目标点，并在第 20 代因达到原最大代数停止；
- 自适应确认运行最大代数已提高到 `100`，仍保留连续 `10` 代无改善或 `30` 秒停止；
- 最大 100 代自适应确认运行在第 94 代因连续 10 代无 Pareto 改善停止，用时约 13.58 秒，去重后得到 1 个 Pareto 候选；
- 阶段 A 第 9 步的 `tD`、`SD`、`Y` 评价与组合选择代码已完成静态检查，MATLAB 契约测试已通过；
- 已完成 Pareto 目标去重及“连续无改善/时间上限/最大代数”自适应终止代码并通过 MATLAB 回归测试；
- 已完成首次 `tD`、`SD`、`Y` 组合计算，但发现故障前随机基线与故障后优化方案比较不公平；该结果暂不作为研究结论；
- 阶段 A 第 10 步轻量契约测试和正式同等预算正常基线搜索均已完成；
- 正常基线搜索在第 `44` 代因连续 `10` 代无 Pareto 改善停止，用时约 `3.62` 秒，得到 `3` 个去重 Pareto 候选；
- 按“最小完工时间、并列时最小能耗”选择的优化正常基线为：完工时间 `112.72`、总能耗 `1861.3223`；
- 原随机正常基线完工时间为 `144.2033`，因此旧组合结果 `tD=-44.23`、`Y=-36.007` 已失去比较基准，不作为研究结论；
- 阶段 A 第 11 步契约测试和优化基线正式筛选均已完成；
- 优化基线上 `J5-O1` 改为 `M1 / tf=40`，但 `tr=5` 不产生直接维修冲突，因此旧故障场景失效；
- 优化基线共筛得 `36` 个有效候选，正式选择排名第 1 的 `J8-O1 / M2 / tf=12 / tr=5`；
- 新故障场景预计影响 `7` 道工序，最大预计延迟为 `5`；
- 阶段 A 第 12 步契约测试和正式优化基线链路均已通过；
- 正式场景中直接受影响工序 `2` 道，传播后共影响 `7` 道；
- AGV 联动分析标记 `53` 个受影响运输任务，确认需要调整；
- AGV 联动右移后的机器完工时间仍为 `112.72`，故障延迟被计划余量吸收；
- 故障时刻冻结工序 `5` 道，可完全重调度工序 `53` 道；
- 阶段 A 第 13 步轻量搜索与组合评价契约测试已通过；
- 第 13 步正式搜索在第 `97` 代因连续无改善停止，用时约 `16.31` 秒，得到 `4` 个去重 Pareto 候选；
- 部分右移最终卸载完工时间为 `116.72`，`tD=4`、`SD=0`、`Y=3.6`；
- 当前权重下选择完全重调度：最终卸载完工时间 `108.6533`、`tD=-4.0667`、`SD=30`、`Y=-0.66`；
- 阶段 A 第 14 步分析、审计、多种子入口和轻量契约测试已完成静态实现；
- 第 14 步正式权重分析表明：`omega1=0` 至 `0.7` 选择部分右移，
  `omega1=0.8` 至 `1.0` 选择完全重调度；
- 全部候选通过调度约束和能耗审计；部分右移机器能耗约 `1407.7`、
  AGV 能耗 `474.4667`、总能耗约 `1882.1`；
- `all_constraint_audits_validated=true`，
  `all_energy_audits_complete=true`；
- 第 14 步多随机种子正式实验已完成，`5` 次运行全部验证通过；
- 种子 `22、42、55` 选择完全重调度，种子 `11、33` 选择部分右移；
- 当前预算下最终策略对随机种子不完全稳定，因此应保留组合选择，不能
  只凭单个随机种子固定采用完全重调度；
- 阶段 A 最终总结已完成，单机器工序完成时故障主流程正式收口；
- 阶段 B 第 1 步事件、状态提取和轻量测试已完成静态实现，尚未运行 MATLAB；
- 阶段 B 第 1 步 MATLAB 轻量测试已通过；
- 阶段 B 第 2 步已确定第一版采用暂停后原机器续加工，并完成静态实现；
- 阶段 B 第 2 步 MATLAB 轻量测试已通过；
- 阶段 B 第 3 步局部影响传播代码、测试和文档已完成，MATLAB 轻量测试已通过；
- 阶段 B 第 4 步机器局部右移候选已通过 MATLAB 轻量测试；
- 阶段 B 第 5 步 AGV 运输影响分析已通过 MATLAB 轻量测试；
- 阶段 B 第 6 步 AGV 与机器联动局部右移已通过 MATLAB 轻量测试；
- 阶段 B 第 7 步完全重调度冻结问题已通过 MATLAB 轻量测试；
- 阶段 B 第 8 步两段加工完全重调度解码器已通过 MATLAB 轻量测试；
- 阶段 B 第 9 步受限种群初始化、交叉和变异已通过 MATLAB 轻量测试；
- 阶段 B 第 10 步候选评价与受限 NSGA-II 契约已通过 MATLAB 轻量测试；
- 阶段 B 第 11 步正式搜索已完成：第 `47` 代因连续无改善停止，用时约
  `11.4701` 秒，得到 `1` 个去重 Pareto 候选；
- 阶段 B 第 12 步轻量契约测试及正式组合计算已通过；
- 局部右移最终卸载时间 `144.2033`、`tD=0`、`SD=0`、`Y=0`；
- 完全重调度最终卸载时间 `96.1633`、`tD=-48.04`、`SD=36`、
  `Y=-39.636`，当前权重下选择完全重调度；
- 阶段 B 第 13 步轻量测试、正式权重敏感性和最终约束/能耗审计已通过；
- 权重 `0` 至 `0.4` 选择局部右移，权重 `0.5` 至 `1.0` 选择完全重调度；
- 两类候选均通过两段加工、维修区间、最终卸载和能耗闭合审计；
- 局部右移总能耗约 `2066.5`，完全重调度总能耗约 `1702.6`；
- 阶段 B 第 13 步五个随机种子正式实验已完成，五次均选择完全重调度；
- 多种子最终卸载时间约为 `93.333` 至 `121.710`，说明策略选择稳定，但
  搜索解质量仍存在随机波动；
- 阶段 B 最终总结已完成，加工中单机器故障主流程正式收口；
- 阶段 B-R 第 1 步从头加工恢复计划、轻量测试和说明文档已完成静态实现；
- 阶段 B-R 第 2 步影响传播代码、测试和文档已完成静态实现；
- 阶段 B-R 第 3 步机器局部右移代码、测试和文档已完成静态实现；
- 阶段 B-R 第 4 步 AGV 影响分析代码、测试和文档已完成静态实现；
- 阶段 B-R 第 1 至第 4 步 MATLAB 轻量测试均已通过；
- 阶段 B-R 第 5 步 AGV 与机器联动代码、测试和文档已完成静态实现，
  尚未运行 MATLAB；
- 阶段 B-R 第 5 步 MATLAB 轻量测试已通过；
- 阶段 B-R 第 6 步完全重调度冻结问题代码、测试和文档已完成静态实现，
  尚未运行 MATLAB；
- 阶段 B-R 第 6 步 MATLAB 轻量测试已通过；
- 阶段 B-R 第 7 步完全重调度解码器代码、测试和文档已完成静态实现，
  尚未运行 MATLAB；
- 阶段 B-R 第 7 步 MATLAB 轻量测试已通过；
- 阶段 B-R 第 8 步受限种群初始化、交叉和变异入口、测试及文档已完成
  静态实现，尚未运行 MATLAB；
- 阶段 B-R 第 8 步 MATLAB 轻量测试已通过；
- 阶段 B-R 第 9 步候选评价、受限 NSGA-II 轻量搜索、测试及文档已完成
  静态实现，尚未运行 MATLAB；
- 阶段 B-R 第 9 步 MATLAB 轻量测试已通过；
- 阶段 B-R 第 10 步正式搜索配置、保存入口、测试及文档已完成静态实现，
  尚未运行配置测试或正式搜索；
- 阶段 B-R 第 10 步配置测试和单随机种子正式搜索已完成；正式搜索在第
  `47` 代因连续无改善停止，用时约 `13.5523` 秒，得到 `1` 个 Pareto 候选；
- 阶段 B-R 第 11 步组合评价、选择入口、轻量测试和文档已完成静态实现，
  轻量测试和正式组合计算均已通过；
- 局部右移最终卸载时间 `144.2033`、`tD=0`、`SD=0`、`Y=0`；
- 从头加工完全重调度最终卸载时间 `96.1633`、`tD=-48.04`、`SD=36`、
  `Y=-39.636`，当前权重下选择完全重调度；
- 阶段 B-R 第 12 步权重敏感性、最终约束/能耗审计、多随机种子入口和
  轻量测试已完成，正式权重分析和最终审计已通过；
- 局部右移总能耗约 `2074.3`，完全重调度总能耗约 `1710.4`；两类候选均
  满足从头加工承诺、维修区间、最终卸载和能耗闭合；
- 阶段 B-R 五随机种子实验已完成，五次均选择完全重调度；最终卸载时间
  范围为 `96.163` 至 `113.100`；
- [阶段 B-R 最终总结](docs/stage_br_final_summary.md) 已完成，阶段 B-R 正式
  收口；
- 用户已允许基于原数据生成优化候选方案；不允许新增问题数据或修改 `raw_code/`。

## 下一步执行边界

下一步进入阶段 C：多机器故障。阶段 C 将分别研究同时故障和连续故障，
开始实施前先拆分阶段目标和工作步骤。

阶段 C 的详细地图已经制定：

- [阶段 C：多机器故障详细计划](docs/stage_c_plan.md)

阶段 C 分为共享多故障基础、同时故障、连续故障和最终验证四个工作段，共
`18` 步。下一步只执行第 1 步：定义并校验统一 `faults[]` 输入。

阶段 C 第 1 步已完成静态实现：

- [统一多故障事件输入](docs/stage_c_step_01_fault_events.md)
- `src/fault/normalize_stage_c_fault_events.m`
- `tests/test_stage_c_fault_events.m`

下一步先运行第 1 步轻量契约测试；当前未运行 MATLAB。

阶段 C 第 1 步轻量测试已通过。第 2 步已完成静态实现：

- [机器维修不可用区间](docs/stage_c_step_02_machine_unavailability.md)
- `src/fault/build_stage_c_machine_unavailability.m`
- `tests/test_stage_c_machine_unavailability.m`

下一步先运行第 2 步轻量契约测试；当前未接入调度算法。

阶段 C 第 2 步轻量测试已通过。第 3 步已完成静态实现：

- [多故障事件组状态快照](docs/stage_c_step_03_event_group_state.md)
- `src/state/extract_stage_c_event_group_state.m`
- `tests/test_stage_c_event_group_state.m`

测试使用原项目正常基线动态选取同时在制机器，不生成新的生产问题数据。
下一步先运行第 3 步轻量契约测试。

阶段 C 第 3 步轻量测试已通过，`C-0` 共享基础完成。第 4 步已完成静态实现：

- [同时故障场景筛选](docs/stage_c_step_04_simultaneous_fault_scenario.md)
- `configs/stage_c_simultaneous_fault_config.m`
- `src/screening/screen_stage_c_simultaneous_fault_scenarios.m`
- `scripts/run_stage_c_simultaneous_fault_scenario.m`
- `tests/test_stage_c_simultaneous_fault_scenario.m`

本步只选择和验证场景，不传播影响、不修改调度。下一步先运行轻量测试。

阶段 C 第 4 步轻量测试已通过。第 5 步已完成静态实现：

- [同时故障影响传播与合并](docs/stage_c_step_05_simultaneous_impact.md)
- `src/impact/identify_stage_c_simultaneous_affected_operations.m`
- `scripts/run_stage_c_simultaneous_impact_analysis.m`
- `tests/test_stage_c_simultaneous_impact_analysis.m`

本步只计算并合并预计延迟，不回写机器或 AGV 时间表。下一步先运行测试。

阶段 C 第 5 步轻量测试已通过。第 6 步已完成静态实现：

- [同时故障机器局部右移](docs/stage_c_step_06_simultaneous_machine_right_shift.md)
- `src/rescheduling/build_stage_c_simultaneous_machine_right_shift.m`
- `scripts/run_stage_c_simultaneous_machine_right_shift.m`
- `tests/test_stage_c_simultaneous_machine_right_shift.m`

本步正式生成机器候选表，两个中断工序按保留进度规则恢复；AGV 时间表保持
原样，尚未进行运输联动验证。下一步先运行第 6 步轻量测试。

阶段 C 第 6 步轻量测试已通过。第 7 步已完成静态实现：

- [同时故障 AGV 影响分析](docs/stage_c_step_07_simultaneous_agv_impact.md)
- `src/impact/analyze_stage_c_simultaneous_agv_impact.m`
- `scripts/run_stage_c_simultaneous_agv_impact_analysis.m`
- `tests/test_stage_c_simultaneous_agv_impact_analysis.m`

本步只识别直接失效运输和同一 AGV 后续待复核运输，不修改 AGV 或机器
时间表。下一步先运行第 7 步轻量测试。

阶段 C 第 7 步轻量测试已通过。第 8 步已完成静态实现：

- [同时故障 AGV 与机器联动局部右移](docs/stage_c_step_08_simultaneous_agv_linked_right_shift.md)
- `src/rescheduling/build_stage_c_simultaneous_agv_linked_right_shift.m`
- `scripts/run_stage_c_simultaneous_agv_linked_right_shift.m`
- `tests/test_stage_c_simultaneous_agv_linked_right_shift.m`

本步正式调整 AGV 时间，并把运输延迟反馈至机器工序；机器和 AGV 分配、
路线、顺序及持续时间保持不变。下一步先运行第 8 步轻量测试。

阶段 C 第 8 步轻量测试已通过。第 9 步已完成静态实现：

- [同时故障完全重调度冻结问题](docs/stage_c_step_09_simultaneous_frozen_problem.md)
- `src/rescheduling/build_stage_c_simultaneous_frozen_problem.m`
- `scripts/run_stage_c_simultaneous_frozen_problem.m`
- `tests/test_stage_c_simultaneous_frozen_problem.m`

本步冻结已完成、正常在制和两个故障在制承诺，只释放未开工任务；不运行
搜索。阶段 C 第 9 步轻量测试已通过。

阶段 C 第 10.1 步已完成静态实现：

- [同时故障完全重调度解码器](docs/stage_c_step_10a_simultaneous_complete_decoder.md)
- `src/rescheduling/decode_stage_c_simultaneous_complete_reschedule.m`
- `scripts/run_stage_c_simultaneous_complete_reschedule_decode.m`
- `tests/test_stage_c_simultaneous_complete_reschedule_decode.m`

本步复用原项目编码数据解码一个轻量候选，恢复多个中断工序的两段加工承诺，
并校验全部维修区间；不运行搜索、不生成正式输出。下一步先运行第 10.1 步
轻量测试。

阶段 C 第 10.1 步轻量测试已通过。第 10.2 步已完成静态实现：

- [同时故障受限种群与遗传算子](docs/stage_c_step_10b_simultaneous_reschedule_operators.md)
- `scripts/run_stage_c_simultaneous_reschedule_operators.m`
- `tests/test_stage_c_simultaneous_reschedule_operators.m`

本步复用现有受限初始化、交叉和变异，只改变未开工任务的 OS、MS、AS、SS，
并要求每个父代和子代通过多中断解码器；不评价适应度、不运行正式搜索。

阶段 C 第 10.2 步轻量测试已通过。第 10.3 步已完成静态实现：

- [候选评价与受限 NSGA-II 轻量搜索](docs/stage_c_step_10c_simultaneous_restricted_search.md)
- `src/rescheduling/evaluate_stage_c_simultaneous_reschedule_candidate.m`
- `src/rescheduling/search_stage_c_simultaneous_complete_reschedule.m`
- `scripts/run_stage_c_simultaneous_restricted_search_contract.m`
- `tests/test_stage_c_simultaneous_restricted_search_contract.m`

本步使用最终卸载时间和总能耗评价候选，保留 Pareto 去重和自适应停止。
轻量契约为 `6×2`，不保存正式结果。

阶段 C 第 10.3 步轻量测试已通过。第 10.4 步已完成静态实现：

- [正式搜索配置与结果保存入口](docs/stage_c_step_10d_formal_search_entry.md)
- `configs/stage_c_simultaneous_complete_search_config.m`
- `scripts/run_stage_c_simultaneous_complete_search.m`
- `tests/test_stage_c_simultaneous_complete_search_config.m`

正式配置为种群 `10`、最多 `100` 代、连续 `10` 代无改善或 `30` 秒停止。
本步只验证配置，不运行搜索、不创建输出目录。

阶段 C 第 10.4 步配置测试和单随机种子正式搜索已完成。第 11 步已完成静态
实现：

- [组合评价与最终审计](docs/stage_c_step_11_combination_and_audit.md)
- `src/evaluation/evaluate_stage_c_rescheduling_plan.m`
- `src/evaluation/evaluate_stage_c_right_shift_energy.m`
- `src/evaluation/select_stage_c_combined_strategy.m`
- `src/evaluation/audit_stage_c_rescheduling_candidate.m`
- `scripts/run_stage_c_combination_selection.m`
- `tests/test_stage_c_combination_contract.m`

本步比较局部右移和全部 Pareto 候选的 `tD、SD、Y`，并审计多个维修区间、
多个中断承诺、最终卸载和能耗。

阶段 C 第 11 步轻量与正式结果分析均已通过。第 12 步已完成静态实现：

- [事件回放与计划版本模型](docs/stage_c_step_12_plan_version_history.md)
- `src/state/initialize_stage_c_plan_history.m`
- `src/state/append_stage_c_plan_version.m`
- `src/state/resolve_stage_c_active_plan.m`
- `scripts/run_stage_c_plan_version_history.m`
- `tests/test_stage_c_plan_version_history.m`

本步建立 `V0 正常基线 -> V1 第一次故障后选定计划`，后续事件按时刻查询
当前生效版本，不覆盖历史；暂不处理第二次故障。

阶段 C 第 12 步轻量测试已通过。第 13 步已完成静态实现：

- [从当前计划提取下一故障状态](docs/stage_c_step_13_next_fault_state.md)
- `src/state/build_stage_c_current_plan_view.m`
- `src/screening/screen_stage_c_next_fault_event.m`
- `src/state/extract_stage_c_sequential_fault_state.m`
- `scripts/run_stage_c_next_fault_state.m`
- `tests/test_stage_c_next_fault_state.m`

本步从 `V1` 动态选择下一有效故障并提取状态，不回到正常基线、不传播影响、
不修改计划、不运行搜索。

阶段 C 第 13 步轻量测试已通过。第 14 步已完成静态实现：

- [累计维修区间与连续故障影响合并](docs/stage_c_step_14_sequential_impact_context.md)
- `src/impact/build_stage_c_sequential_impact_context.m`
- `scripts/run_stage_c_sequential_impact_context.m`
- `tests/test_stage_c_sequential_impact_context.m`

本步累计全部维修历史，传播新故障影响，并合并仍有效的历史影响及事件来源；
不写回机器或 AGV 时间表、不追加 `V2`。

阶段 C 第 15 步已完成静态实现：

- [连续故障局部右移与 AGV 联动](docs/stage_c_step_15_sequential_agv_linked_right_shift.md)
- `scripts/run_stage_c_sequential_agv_linked_right_shift.m`
- `tests/test_stage_c_sequential_agv_linked_right_shift.m`

本步从当前计划生成连续故障局部右移候选，完成 AGV 联动调整；不追加版本、
不运行搜索。

阶段 C 第 16.1 步已完成静态实现：

- [连续故障完全重调度冻结问题](docs/stage_c_step_16_1_sequential_frozen_problem.md)
- `scripts/run_stage_c_sequential_frozen_problem.m`
- `tests/test_stage_c_sequential_frozen_problem.m`

本步只建立冻结问题，不解码、不搜索、不组合选择。

阶段 C 第 16.2 步已完成静态实现：

- [连续故障完全重调度解码器](docs/stage_c_step_16_2_sequential_complete_decode.md)
- `scripts/run_stage_c_sequential_complete_reschedule_decode.m`
- `tests/test_stage_c_sequential_complete_reschedule_decode.m`

本步只解码一个轻量候选，不运行种群搜索、不组合选择。

阶段 C 第 16.3 步已完成静态实现：

- [连续故障算子与轻量搜索契约](docs/stage_c_step_16_3_sequential_search_contract.md)
- `scripts/run_stage_c_sequential_reschedule_operators.m`
- `scripts/run_stage_c_sequential_restricted_search_contract.m`
- `tests/test_stage_c_sequential_reschedule_operators.m`
- `tests/test_stage_c_sequential_restricted_search_contract.m`

本步只做算子契约和 `6×2` 轻量搜索契约，不运行正式长实验。

阶段 C 第 16.4 步已完成正式搜索：

- [连续故障正式搜索入口](docs/stage_c_step_16_4_sequential_formal_search_entry.md)
- `configs/stage_c_sequential_complete_search_config.m`
- `scripts/run_stage_c_sequential_complete_search.m`
- `tests/test_stage_c_sequential_complete_search_config.m`

正式输出目录为 `outputs/stage_c_sequential_complete_reschedule_search/20260616_092142`。

阶段 C 第 16.5 步已完成正式组合评价：

- [连续故障组合评价](docs/stage_c_step_16_5_sequential_combination_selection.md)
- `scripts/run_stage_c_sequential_combination_selection.m`
- `tests/test_stage_c_sequential_combination_contract.m`

本步比较连续故障局部右移与完全重调度候选的 `tD、SD、Y`，并审计约束和能耗。

阶段 C 第 16.6 步已完成结果总结：

- [连续故障正式结果总结](docs/stage_c_step_16_6_sequential_result_summary.md)

正式组合评价选择 `complete_rescheduling`。选定方案 `tD=-27.7133`、`SD=13`、
`Y=-23.6420`；约束审计和能耗审计均通过。

阶段 C 第 17.1 步已完成静态实现：

- [最终审计场景矩阵](docs/stage_c_step_17_1_final_audit_matrix.md)
- `configs/stage_c_final_audit_matrix_config.m`
- `tests/test_stage_c_final_audit_matrix_config.m`

本步明确 `C-S1` 和 `C-SEQ1` 已可运行，`C-S2` 和 `C-SEQ2` 仍需补实现或排除。

阶段 C 第 17.2 步已完成：

- [最终审计多随机种子入口](docs/stage_c_step_17_2_final_audit_multiseed_entry.md)
- `configs/stage_c_final_audit_multiseed_config.m`
- `scripts/run_stage_c_final_audit_multiseed.m`
- `tests/test_stage_c_final_audit_multiseed_config.m`

本步只把已实现的 `C-S1` 与 `C-SEQ1` 纳入五随机种子最终审计入口。正式
结果目录为 `outputs/stage_c_final_audit_multiseed/20260616_094301`。
两个场景共 `10` 次运行全部通过约束与能耗审计，且全部选择
`complete_rescheduling`；`C-S2` 和 `C-SEQ2` 尚未实现，不纳入本次结论。

阶段 C 第 18 步已完成静态整理：

- [阶段 C 最终总结与代码导读](docs/stage_c_final_summary_and_code_guide.md)

本步把多故障事件模型、维修区间、影响传播、编码解码、局部右移、完全重调度、
组合选择、正式结果、能力边界和代码入口统一整理成阶段 C 收口文档。

总项目收口文档已完成静态整理：

- [项目总收口](docs/project_final_summary.md)

该文档将阶段 A、B、B-R、C 的目标、路线、算法、正式结果、验证结论、能力
边界和后续建议合并为一份总汇报入口。

已补充结论证据和未覆盖场景计划：

- [结论证据与读数指南](docs/conclusion_evidence_guide.md)
- [未覆盖场景补充计划](docs/uncovered_scenarios_plan.md)

前者说明结论应看 `tD`、`SD`、`Y`、最终卸载、能耗、策略选择和审计标志；
后者明确下一步优先补 `C-S2`，再补 `C-SEQ2`。

`C-S2` 和 `C-SEQ2` 也已写入阶段 C 项目地图和总工作表，作为后续待补工作段。

C-S2 第 1 步已完成静态实现：

- [C-S2 第 1 步：从头加工中断承诺](docs/stage_cs2_step_01_restart_commitments.md)
- `src/rescheduling/build_stage_c_simultaneous_restart_commitments.m`
- `scripts/run_stage_cs2_restart_commitments.m`
- `tests/test_stage_cs2_restart_commitments.m`

C-S2 第 2 步已完成静态实现：

- [C-S2 第 2 步：从头加工影响传播](docs/stage_cs2_step_02_impact_analysis.md)
- `src/impact/identify_stage_cs2_restart_affected_operations.m`
- `scripts/run_stage_cs2_impact_analysis.m`
- `tests/test_stage_cs2_impact_analysis.m`

C-S2 第 3 步已完成静态实现：

- [C-S2 第 3 步：从头加工机器局部右移](docs/stage_cs2_step_03_machine_right_shift.md)
- `src/rescheduling/build_stage_cs2_machine_right_shift.m`
- `scripts/run_stage_cs2_machine_right_shift.m`
- `tests/test_stage_cs2_machine_right_shift.m`

C-S2 第 4 步已完成静态实现：

- [C-S2 第 4 步：从头加工 AGV 影响分析](docs/stage_cs2_step_04_agv_impact_analysis.md)
- `src/impact/analyze_stage_cs2_agv_impact.m`
- `scripts/run_stage_cs2_agv_impact_analysis.m`
- `tests/test_stage_cs2_agv_impact_analysis.m`

C-S2 第 5 步已完成静态实现：

- [C-S2 第 5 步：从头加工 AGV 与机器联动右移](docs/stage_cs2_step_05_agv_linked_right_shift.md)
- `src/rescheduling/build_stage_cs2_agv_linked_right_shift.m`
- `scripts/run_stage_cs2_agv_linked_right_shift.m`
- `tests/test_stage_cs2_agv_linked_right_shift.m`

C-S2 第 6 步已完成静态实现：

- [C-S2 第 6 步：从头加工完全重调度冻结问题](docs/stage_cs2_step_06_frozen_problem.md)
- `src/rescheduling/build_stage_cs2_frozen_problem.m`
- `scripts/run_stage_cs2_frozen_problem.m`
- `tests/test_stage_cs2_frozen_problem.m`

C-S2 第 7 步已完成静态实现：

- [C-S2 第 7 步：从头加工完全重调度解码器](docs/stage_cs2_step_07_complete_decoder.md)
- `src/rescheduling/decode_stage_cs2_complete_reschedule.m`
- `scripts/run_stage_cs2_complete_reschedule_decode.m`
- `tests/test_stage_cs2_complete_reschedule_decode.m`

C-S2 第 8 步已完成静态实现：

- [C-S2 第 8 步：从头加工完全重调度算子契约](docs/stage_cs2_step_08_reschedule_operators.md)
- `scripts/run_stage_cs2_reschedule_operators.m`
- `tests/test_stage_cs2_reschedule_operators.m`

C-S2 第 9 步已完成静态实现：

- [C-S2 第 9 步：从头加工受限搜索契约](docs/stage_cs2_step_09_restricted_search_contract.md)
- `src/rescheduling/evaluate_stage_cs2_reschedule_candidate.m`
- `src/rescheduling/search_stage_cs2_complete_reschedule.m`
- `scripts/run_stage_cs2_restricted_search_contract.m`
- `tests/test_stage_cs2_restricted_search_contract.m`

## 目录说明

```text
raw_code/     原始代码只读快照
docs/         问题定义、研究架构和工作计划
src/          后续开发代码
configs/      故障场景和实验参数
data_sample/  最小测试数据
scripts/      分阶段运行入口
tests/        小样本和烟雾测试
outputs/      本地生成结果，不作为本次首批上传内容
```

## 工作规则

- 不修改 `raw_code/`；
- 每次只完成一个小任务；
- 不一次性重构整个项目；
- 不写死本机绝对路径；
- 运行 MATLAB、开展实验或生成正式输出前先确认；
- 机器故障代码只在本独立项目中开发。

C-S2 第 10 步已完成静态实现：

- [C-S2 第 10 步：正式搜索配置与结果保存入口](docs/stage_cs2_step_10_complete_search_config.md)
- `configs/stage_cs2_complete_search_config.m`
- `scripts/run_stage_cs2_complete_search.m`
- `tests/test_stage_cs2_complete_search_config.m`

本步只建立正式搜索配置和输出保存入口，尚未运行正式搜索、尚未生成正式结果。

C-S2 第 10 步正式搜索已运行一次：

- 输出目录：`outputs/stage_cs2_complete_reschedule_search/20260616_150249`
- 停止原因：`time_limit`
- 完成代数：`94`
- 运行时间：约 `30.2440` 秒
- 去重 Pareto 数：`3`

C-S2 第 11 步已完成静态实现：

- [C-S2 第 11 步：组合评价与策略选择](docs/stage_cs2_step_11_combination_selection.md)
- `src/evaluation/audit_stage_cs2_rescheduling_candidate.m`
- `scripts/run_stage_cs2_combination_selection.m`
- `scripts/run_stage_cs2_combination_contract.m`
- `tests/test_stage_cs2_combination_contract.m`

C-S2 第 11 步正式组合选择已完成：

- 使用结果：`outputs/stage_cs2_complete_reschedule_search/20260616_150249/result.mat`
- 选中策略：`complete_rescheduling`
- 完全重调度：最终卸载 `122.0900`，`tD=-22.1133`，`SD=23`，`Y=-17.6020`
- 局部右移：最终卸载 `144.2033`，`tD=0`，`SD=0`，`Y=0`
- 约束审计：`all_constraint_audits_validated=1`
- 能耗审计：`all_energy_audits_complete=1`

C-S2 第 12 步已完成静态实现：

- [C-S2 第 12 步：权重敏感性、多随机种子与最终审计](docs/stage_cs2_step_12_robustness_audit.md)
- `configs/stage_cs2_step_12_config.m`
- `src/evaluation/analyze_stage_cs2_weight_sensitivity.m`
- `scripts/run_stage_cs2_step_12_analysis.m`
- `scripts/run_stage_cs2_step_12_multiseed.m`
- `tests/test_stage_cs2_step_12_contract.m`

本步的契约测试只做权重扫描和审计，不运行五随机种子正式实验。
