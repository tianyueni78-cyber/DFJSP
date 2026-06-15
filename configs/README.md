# configs

## 当前配置

`normal_schedule_config.m`

配置阶段 A 正常调度基线使用的：

- 随机种子；
- FJSP 算例相对位置；
- 机器数据相对位置；
- AGV 数据相对位置；
- AGV 最大电量；
- 充电速度。

所有运行路径都从项目根目录动态组合，不写死本机绝对路径。

## 阶段 A 故障配置

`stage_a_fault_config.m`

定义：

- 触发故障的工件；
- 触发故障的工序；
- 维修时长。

故障机器和故障时刻由正常调度基线自动确定，不在配置中重复写死。

## 阶段 A 完全重调度确认运行

`stage_a_confirmation_search_config.m`

固定本次已确认的参数：

- 种群规模 `10`；
- 最大迭代代数 `100`；
- 交叉概率 `0.8`；
- 变异概率 `0.2`；
- 锦标赛规模 `2`；
- 连续 `10` 代无 Pareto 改善停止；
- 最长运行时间 `30` 秒；
- 随机种子 `42`；
- 相对输出目录 `outputs/stage_a_complete_reschedule_confirmation/`。

该配置只用于正式实验前的单次确认运行。

## 阶段 A 第 10 步：同等预算正常基线搜索

`normal_baseline_search_config.m`

直接继承阶段 A 完全重调度确认运行的搜索预算和随机种子，只修改输出目录
与正常基线选择规则。这样故障前正常计划和故障后完全重调度使用相同的：

- 种群规模；
- 最大代数；
- 交叉、变异与锦标赛参数；
- 连续无改善停止条件；
- 时间上限；
- 随机种子。

## 阶段 A 组合评价

`stage_a_combination_config.m`

定义论文第一版组合权重：

- 完工时间偏差权重 `0.9`；
- 机器分配偏差权重 `0.1`；
- 并列判断容差 `1e-9`。

## 阶段 A 第 13 步

`stage_a_step_13_config.m`

继承同等预算搜索参数，并加入组合评价权重。输出目录为：

```text
outputs/stage_a_step_13_search_and_selection/
```

## 阶段 A 第 14 步

`stage_a_step_14_config.m`

定义多随机种子 `[11,22,33,42,55]`、完工时间权重 `0:0.1:1`，并继承第 13
步搜索预算。

## 阶段 B 第 1 步

`stage_b_processing_fault_config.m`

只选择原正常基线中的工序，并设置：

- 中断比例 `0.5`；
- 维修时长 `5`；
- 中断规则 `unresolved`。

该配置不生成新的工件、机器或加工时间。

## 阶段 B 第 11 步

`stage_b_complete_search_config.m`

定义单随机种子正式搜索预算：

- 种群 `10`；
- 最大 `100` 代；
- 连续 `10` 代无改善停止；
- 最长 `30` 秒；
- 随机种子 `42`；
- 相对输出目录 `outputs/stage_b_complete_reschedule_search/`。

## 阶段 B 第 12 步

`stage_b_combination_config.m`

定义论文组合评价权重：

- 完工时间偏差权重 `0.9`；
- 机器序列偏差权重 `0.1`；
- 并列比较容差 `1e-9`。

## 阶段 B 第 13 步

`stage_b_step_13_config.m`

继承阶段 B 正式搜索预算和组合权重，并增加：

- 随机种子 `[11,22,33,42,55]`；
- 完工时间权重 `0:0.1:1`；
- 相对输出目录 `outputs/stage_b_step_13_robustness/`。

## 阶段 B-R 第 10 步

`stage_br_complete_search_config.m`

定义从头加工规则单随机种子正式搜索预算：

- 种群 `10`；
- 最大 `100` 代；
- 连续 `10` 代无改善停止；
- 最长 `30` 秒；
- 随机种子 `42`；
- 相对输出目录 `outputs/stage_br_complete_reschedule_search/`。
