# 项目冻结边界与证据索引

## 1. 用途

这份文件把 DFJSP 项目收成一个导师可直接阅读的冻结入口。

它回答四个问题：

1. 最终范围是什么；
2. 哪些内容不再改主线；
3. 最后该看哪些文件；
4. 最终可以引用哪些结果。

## 2. 冻结边界

### 2.1 最终范围

当前项目的最终范围就是：

- FJSP-AGV 机器故障动态重调度；
- 单机器故障、加工中故障、从头加工、同时故障、连续故障；
- 同时故障补充场景 `C-S2`；
- 连续故障补充场景 `C-SEQ2`；
- 局部右移、完全重调度、AGV 联动、组合选择、约束审计和多种子验证。

### 2.2 不再改主线

以下内容不再作为主线继续扩展：

- `raw_code/`；
- 已闭合的 `src/` 主链路；
- 机器故障以外的新长期主线；
- 把正式搜索、多随机种子长实验、30 秒搜索入口继续往外扩；
- 把历史路线图重新写回成当前待办。

### 2.3 历史材料

以下材料保留为历史记录或过程说明：

- `docs/machine_fault_rescheduling_plan.md`
- `docs/uncovered_scenarios_plan.md`
- 各阶段工作记录和阶段总结文档

它们可以帮助理解项目怎么走到今天，但不再代表当前的主线任务。

## 3. 证据索引

导师优先看的文件建议按这个顺序：

| 入口 | 它说明什么 |
|---|---|
| [项目总收口](project_final_summary.md) | 项目层面的总结论、边界和结果口径 |
| [项目最终收口计划](project_final_freeze_plan.md) | 当前仓库如何从主线完成收成冻结版 |
| [项目最终收口 Checklist](project_final_checklist.md) | 最后验收是否已经封版 |
| [结论证据与读数指南](conclusion_evidence_guide.md) | 各项指标怎么读、结论从哪里来 |
| [阶段 C 最终总结与代码导读](stage_c_final_summary_and_code_guide.md) | 同时故障、连续故障、C-S2、C-SEQ2 的最终结果 |
| [未覆盖场景补充计划](uncovered_scenarios_plan.md) | 历史补充路线，当前已补齐后的背景材料 |

### 3.1 最终可引用的输出

当前最适合引用的输出集中在阶段 C 最终审计目录：

- `outputs/stage_c_final_audit_multiseed/20260616_094301/run_summary.txt`
- `outputs/stage_c_final_audit_multiseed/20260616_094301/multiseed_summary.csv`
- `outputs/stage_c_final_audit_multiseed/20260616_094301/scenario_summary.csv`
- `outputs/stage_c_final_audit_multiseed/20260616_094301/result.mat`

如果要讲主结论，优先看：

- 阶段 A 的正式结果；
- 阶段 B 的正式结果；
- 阶段 B-R 的正式结果；
- 阶段 C 的正式结果；
- `C-S2` 与 `C-SEQ2` 的补充结果。

## 4. baseline 封口

baseline 不是所有输出的默认名，而是对照线。

### 4.1 baseline 对比什么

当前 baseline 主要对比两类东西：

1. 原始基线和当前重构实现是否同口径；
2. 局部右移和完全重调度在同一故障场景下的差异。

### 4.2 主结论是什么

当前可以封口的结论是：

- 主线已经闭合；
- C-S2 与 C-SEQ2 已补齐；
- `tD、SD、Y` 提供了可解释的组合选择接口；
- 完全重调度在当前原数据和默认权重下通常更优，但不是全局最优证明。

### 4.3 不能推出什么

当前不能推出：

- 全局最优；
- 所有数据集都泛化成立；
- 所有种子下结论完全一致；
- 所有未来扩展方向都应该继续并入当前仓库主线。

## 5. 最终交付物

当前最后该看的文件建议是：

1. [项目总收口](project_final_summary.md)
2. [项目冻结边界与证据索引](project_freeze_and_evidence_index.md)
3. [项目最终收口计划](project_final_freeze_plan.md)
4. [项目最终收口 Checklist](project_final_checklist.md)
5. [结论证据与读数指南](conclusion_evidence_guide.md)
6. [阶段 C 最终总结与代码导读](stage_c_final_summary_and_code_guide.md)

## 6. 一句话结论

这个仓库现在最合适的状态是：主线完成、补充场景补齐、证据齐全、结论可引用、后续不再改主线。
