# C-S2 第 9 步：从头加工受限搜索契约

## 目标

在 C-S2 第 8 步算子可用后，接入候选评价函数和受限 NSGA-II 搜索框架，
验证 C-S2 完全重调度链路可以完成“小规模搜索闭环”。

本步只运行轻量契约，不是正式实验。

## 评价目标

每个候选方案评价两个目标：

- `final_unload_makespan`：所有工件最终卸载完成时间；
- `total_energy`：机器能耗与 AGV 能耗之和。

同时记录：

- 中断工序数量；
- 维修区间数量；
- `restart_from_zero = true`；
- `lost_processing_time`；
- `total_machine_processing_time`。

## 搜索契约

轻量配置为：

- 种群规模：6；
- 最大代数：2；
- 交叉概率：0.8；
- 变异概率：0.2；
- 锦标赛规模：2。

测试还覆盖两个自适应停止分支：

- 连续若干代 Pareto 无改善；
- 时间上限。

## 代码入口

- 候选评价：`src/rescheduling/evaluate_stage_cs2_reschedule_candidate.m`
- 轻量搜索：`src/rescheduling/search_stage_cs2_complete_reschedule.m`
- 阶段入口：`scripts/run_stage_cs2_restricted_search_contract.m`
- 契约测试：`tests/test_stage_cs2_restricted_search_contract.m`

## 完成标准

- 搜索返回非空 Pareto 前沿；
- Pareto 前沿去重；
- 所有候选通过 C-S2 解码器；
- 所有候选完成最终卸载与能耗评价；
- 从头加工规则和损失加工时间被保留；
- 不生成正式实验输出。

## 运行方式

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_cs2_restricted_search_contract.m'))
```
