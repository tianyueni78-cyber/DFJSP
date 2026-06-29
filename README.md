# FJSP-AGV 机器故障动态重调度

本仓库已经完成主线与补充场景收口。README 只保留最终入口，历史阶段材料请在证据索引中继续阅读。

## 最终入口

| 入口 | 内容 |
|---|---|
| [项目总收口](docs/project_final_summary.md) | 总体成果、能力边界和最终结论 |
| [项目最终收口计划](docs/project_final_freeze_plan.md) | 从主线完成到冻结交付的收口顺序 |
| [项目冻结边界与证据索引](docs/project_freeze_and_evidence_index.md) | 最终范围、证据入口、可引用输出和封版边界 |
| [项目最终收口 Checklist](docs/project_final_checklist.md) | 最后验收清单 |
| [阶段 C 最终总结与代码导读](docs/stage_c_final_summary_and_code_guide.md) | 阶段 C、C-S2、C-SEQ2 的最终结果 |
| [结论证据与读数指南](docs/conclusion_evidence_guide.md) | 指标读法、结论来源和审计口径 |

## 项目范围

本项目研究 FJSP-AGV 机器故障动态重调度，最终覆盖：

- 单机器故障；
- 加工中故障；
- 从头加工；
- 多机器同时故障；
- 连续故障；
- 同时故障补充场景 `C-S2`；
- 连续故障补充场景 `C-SEQ2`。

## 当前状态

- 主线已完成；
- 补充场景已补齐；
- 证据已收口；
- 结论已封版；
- 后续不再改主线。

## 历史材料

阶段性工作记录、补充计划和过程说明仍然保留，但只作为历史材料和复现背景，不再作为当前待办。

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

本步明确 `C-S1`、`C-SEQ1`、`C-S2` 和 `C-SEQ2` 都已纳入最终收口。

阶段 C 第 17.2 步已完成：

- [最终审计多随机种子入口](docs/stage_c_step_17_2_final_audit_multiseed_entry.md)
- `configs/stage_c_final_audit_multiseed_config.m`
- `scripts/run_stage_c_final_audit_multiseed.m`
- `tests/test_stage_c_final_audit_multiseed_config.m`

本步把 `C-S1`、`C-SEQ1`、`C-S2` 和 `C-SEQ2` 一并纳入最终收口语义。正式
结果目录为 `outputs/stage_c_final_audit_multiseed/20260616_094301`。
四个场景的最终结论已在阶段 C 总结中汇总，不再把 `C-S2` 和 `C-SEQ2`
排除在外。

阶段 C 第 18 步已完成静态整理：

- [阶段 C 最终总结与代码导读](docs/stage_c_final_summary_and_code_guide.md)

本步把多故障事件模型、维修区间、影响传播、编码解码、局部右移、完全重调度、
组合选择、正式结果、能力边界和代码入口统一整理成阶段 C 收口文档。

总项目收口文档已完成静态整理：

- [项目总收口](docs/project_final_summary.md)

该文档将阶段 A、B、B-R、C 的目标、路线、算法、正式结果、验证结论、能力
边界和后续建议合并为一份总汇报入口。

已补充结论证据和历史补充场景记录：

- [结论证据与读数指南](docs/conclusion_evidence_guide.md)
- [未覆盖场景补充计划](docs/uncovered_scenarios_plan.md)

前者说明结论应看 `tD`、`SD`、`Y`、最终卸载、能耗、策略选择和审计标志；
后者保留了 `C-S2`、`C-SEQ2` 当时的补齐过程，现作为历史过程记录。

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

C-S2 第 12 步五随机种子正式结果：

- 输出目录：`outputs/stage_cs2_step_12_robustness/20260616_203807`
- `5/5` 次选择 `complete_rescheduling`
- 平均 `tD=-26.2106`
- 平均 `SD=22.6`
- 平均 `Y=-21.3296`
- 最好 `Y=-27.793`，最差 `Y=-15.925`

结论：C-S2 同时故障从头加工规则下，当前算例中完全重调度结论在五随机种子下稳定。

C-SEQ2 第 1 步已完成静态实现：

- [C-SEQ2 第 1 步：维修区间重叠的连续故障事件](docs/stage_cseq2_step_01_overlapping_fault_state.md)
- `src/screening/screen_stage_cseq2_overlapping_next_fault_event.m`
- `scripts/run_stage_cseq2_overlapping_fault_state.m`
- `tests/test_stage_cseq2_overlapping_fault_state.m`

本步只选择后一故障发生在历史维修尚未结束时的连续故障场景，不传播影响、不修改调度、不运行搜索。

C-SEQ2 第 2 步已完成静态实现：

- [C-SEQ2 第 2 步：重叠维修不可用上下文](docs/stage_cseq2_step_02_unavailability_context.md)
- `src/fault/build_stage_cseq2_overlapping_unavailability_context.m`
- `scripts/run_stage_cseq2_unavailability_context.m`
- `tests/test_stage_cseq2_unavailability_context.m`

本步只合并历史维修和新维修区间，不传播影响、不修改调度、不运行搜索。

C-SEQ2 第 3 步已完成静态实现：

- [C-SEQ2 第 3 步：传播新故障影响并保留历史维修约束](docs/stage_cseq2_step_03_impact_context.md)
- `src/impact/build_stage_cseq2_impact_context.m`
- `scripts/run_stage_cseq2_impact_context.m`
- `tests/test_stage_cseq2_impact_context.m`

本步只传播新故障影响并保留累计维修不可用上下文，不写入机器时间表、不调整 AGV、不运行搜索。

C-SEQ2 第 4 步已完成静态实现：

- [C-SEQ2 第 4 步：局部右移机器候选](docs/stage_cseq2_step_04_machine_right_shift.md)
- `scripts/run_stage_cseq2_machine_right_shift.m`
- `tests/test_stage_cseq2_machine_right_shift.m`

本步只生成机器侧局部右移候选，保留历史维修和新维修不可用区间，不调整 AGV、不运行搜索。

C-SEQ2 第 5 步已完成静态实现：

- [C-SEQ2 第 5 步：AGV 影响分析](docs/stage_cseq2_step_05_agv_impact_analysis.md)
- `scripts/run_stage_cseq2_agv_impact_analysis.m`
- `tests/test_stage_cseq2_agv_impact_analysis.m`

本步只识别受影响 AGV 运输任务，不修改 AGV 表、不运行搜索。

C-SEQ2 第 6 步已完成静态实现：

- [C-SEQ2 第 6 步：AGV 与机器联动右移](docs/stage_cseq2_step_06_agv_linked_right_shift.md)
- `scripts/run_stage_cseq2_agv_linked_right_shift.m`
- `tests/test_stage_cseq2_agv_linked_right_shift.m`

本步生成完整局部右移候选，调整受影响 AGV 运输并反馈机器开工时间，不运行搜索。

C-SEQ2 第 7 步已完成静态实现：

- [C-SEQ2 第 7 步：完全重调度冻结问题](docs/stage_cseq2_step_07_frozen_problem.md)
- `scripts/run_stage_cseq2_frozen_problem.m`
- `tests/test_stage_cseq2_frozen_problem.m`

本步在 C-SEQ2 机器 + AGV 联动右移候选之后，建立完全重调度的冻结边界；历史维修作为累计不可用上下文保留，新故障作为本轮完全重调度事件处理。本步不解码、不搜索、不生成正式实验输出。

C-SEQ2 第 8 步已完成静态实现：

- [C-SEQ2 第 8 步：完全重调度解码器](docs/stage_cseq2_step_08_complete_decoder.md)
- `scripts/run_stage_cseq2_complete_reschedule_decode.m`
- `tests/test_stage_cseq2_complete_reschedule_decode.m`

本步在 C-SEQ2 冻结边界基础上解码一个基线种子完全重调度候选，保留历史维修累计不可用上下文，并审计新故障维修与累计维修区间。本步不运行种群搜索。

C-SEQ2 第 9 步已完成静态实现：

- [C-SEQ2 第 9 步：受限重调度算子契约](docs/stage_cseq2_step_09_reschedule_operators.md)
- `scripts/run_stage_cseq2_reschedule_operators.m`
- `tests/test_stage_cseq2_reschedule_operators.m`

本步在 C-SEQ2 冻结边界基础上生成受限种群并执行一次交叉、变异，验证编码范围和抽样解码可行性。本步不评价适应度、不运行 NSGA-II 主循环。

C-SEQ2 第 10 步已完成静态实现：

- [C-SEQ2 第 10 步：受限 NSGA-II 轻量搜索契约](docs/stage_cseq2_step_10_restricted_search_contract.md)
- `scripts/run_stage_cseq2_restricted_search_contract.m`
- `tests/test_stage_cseq2_restricted_search_contract.m`

本步运行 6 个体、2 代的轻量搜索契约，验证候选评价、Pareto 去重、固定随机种子可复现、无改善停止和时间上限停止。本步不生成正式实验输出、不做组合选择。

C-SEQ2 第 11 步已完成静态实现：

- [C-SEQ2 第 11 步：正式搜索配置与结果保存入口](docs/stage_cseq2_step_11_complete_search_config.md)
- `configs/stage_cseq2_complete_search_config.m`
- `scripts/run_stage_cseq2_complete_search.m`
- `tests/test_stage_cseq2_complete_search_config.m`

本步只建立正式搜索配置和结果保存入口，不运行正式搜索。正式搜索配置为 10 个体、最多 100 代、连续 10 代无改善或 30 秒停止。

C-SEQ2 第 12 步正式搜索结果：

- [C-SEQ2 第 12 步：正式搜索运行结果](docs/stage_cseq2_step_12_formal_search_result.md)
- 输出目录：`outputs/stage_cseq2_complete_reschedule_search/20260617_165951`
- 停止原因：`time_limit`
- 实际完成代数：`74`
- 运行时间：`30.1582` 秒
- 去重后 Pareto 解数量：`1`
- Pareto 目标：最终卸载 `112.8`，总能耗 `1779.5`

下一步进入 C-SEQ2 第 13 步：组合选择，计算局部右移和完全重调度的 `tD、SD、Y`。

C-SEQ2 第 13 步已完成静态实现：

- [C-SEQ2 第 13 步：组合选择](docs/stage_cseq2_step_13_combination_selection.md)
- `scripts/run_stage_cseq2_combination_selection.m`
- `tests/test_stage_cseq2_combination_contract.m`

本步比较 C-SEQ2 局部右移方案和完全重调度方案，计算 `tD、SD、Y`，并选择 `Y` 最小的策略。契约测试使用轻量搜索结果，不重复正式搜索。

C-SEQ2 第 13 步正式组合结果：

- [C-SEQ2 第 13 步：正式组合选择结果](docs/stage_cseq2_step_13_formal_combination_result.md)
- 选中策略：`complete_rescheduling`
- 局部右移：`tD=3.0000`，`SD=0`，`Y=2.7000`
- 完全重调度：`tD=-28.3667`，`SD=17`，`Y=-23.8300`
- 约束审计：`all_constraint_audits_validated=1`
- 能耗审计：`all_energy_audits_complete=1`

结论：C-SEQ2 当前正式场景下，完全重调度优于局部右移。

C-SEQ2 第 14 步已完成静态实现：

- [C-SEQ2 第 14 步：权重敏感性、最终审计与数据来源](docs/stage_cseq2_step_14_robustness_audit.md)
- `configs/stage_cseq2_step_14_config.m`
- `scripts/run_stage_cseq2_step_14_analysis.m`
- `tests/test_stage_cseq2_step_14_contract.m`

本步确认 C-SEQ2 使用 `raw_code` 中的原始 FJSP、机器和 AGV 数据；故障事件、维修时长、随机种子和搜索预算属于实验参数，不是新造问题数据。本步不运行多随机种子正式实验。

C-SEQ2 第 14 步正式审计结果：

- 权重敏感性：`omega1=0.0` 至 `0.3` 选择 `partial_right_shift`；`omega1=0.4` 至 `1.0` 选择 `complete_rescheduling`。
- 默认权重 `omega1=0.9` 下仍选择 `complete_rescheduling`，`Y=-23.8300`。
- 约束审计：`all_constraint_audits_validated=1`
- 能耗审计：`all_energy_audits_complete=1`
- 数据来源审计：`source_data_only=1`，`synthetic_problem_data_created=0`，总工序数 `58`

结论：C-SEQ2 使用原始 `raw_code` 数据链路；没有自造工件、机器、AGV、加工时间、运输距离或能耗数据。

C-SEQ2 多随机种子最终收口：

- 输出目录：`outputs/stage_cseq2_step_14_robustness/20260617_172752`
- `5/5` 次选择 `complete_rescheduling`
- 最优 `Y=-28.9600`
- 平均 `Y=-22.9188`
- 最优最终卸载 `106.8000`
- 平均最终卸载 `113.4040`
- 数据来源：`source_data_only=1`，`synthetic_problem_data_created=0`
