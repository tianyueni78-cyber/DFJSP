# C-S2 第 11 步：组合评价与策略选择

## 目标

在“同时故障 + 从头加工规则”下，比较：

- 局部右移方案；
- 完全重调度 Pareto 候选方案。

比较指标沿用论文组合评价：

```text
tD = candidate_makespan - baseline_makespan
SD = 机器分配变化数量
Y  = 0.9 * tD + 0.1 * SD
```

`Y` 越小，方案越优。

## C-S2 专用审计

C-S2 不能直接使用 C-S1 的中断审计。原因是：

- C-S1：故障前加工段有效，修复后加工剩余时间；
- C-S2：故障前加工段作废，修复后完整重加工。

因此本步新增 `audit_stage_cs2_rescheduling_candidate.m`，专门检查：

- 每个中断工序都有两段机器加工记录；
- 第一段是 `lost_processing_before_fault`；
- 第二段是 `restart_after_repair`；
- `restart_from_zero=true`；
- `progress_preserved=false`；
- 损失加工时间和完整重加工时间均计入机器能耗；
- 维修区间、最终卸载和能耗审计全部通过。

## 代码入口

- `scripts/run_stage_cs2_combination_selection.m`
- `scripts/run_stage_cs2_combination_contract.m`
- `tests/test_stage_cs2_combination_contract.m`
- `src/evaluation/audit_stage_cs2_rescheduling_candidate.m`

## 轻量测试命令

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_cs2_combination_contract.m'))
```

## 正式结果组合命令

使用已经生成的正式搜索结果：

```matlab
cd('D:\CODEX\机器故障')
addpath(fullfile(pwd,'scripts'))

data = load(fullfile(pwd,'outputs', ...
    'stage_cs2_complete_reschedule_search', ...
    '20260616_150249','result.mat'));

stage11 = run_stage_cs2_combination_selection(data.scenario);

stage11.combined_selection.selected_strategy
stage11.combined_selection.selected_metrics
stage11.combined_selection.right_shift_metrics
stage11.combined_selection.complete_reschedule_metrics
stage11.all_constraint_audits_validated
stage11.all_energy_audits_complete
```

## 当前正式搜索结果记录

C-S2 第 10 步正式搜索已运行一次：

- 输出目录：`outputs/stage_cs2_complete_reschedule_search/20260616_150249`
- 停止原因：`time_limit`
- 完成代数：`94`
- 运行时间：约 `30.2440` 秒
- 去重 Pareto 数：`3`
- Pareto 目标：
  - `final_unload_makespan=122.1`，`total_energy=1821.8`
  - `final_unload_makespan=126.0`，`total_energy=1774.9`
  - `final_unload_makespan=124.3`，`total_energy=1800.5`

## 完成标准

- 能计算局部右移与完全重调度的 `tD、SD、Y`；
- C-S2 专用从头加工审计通过；
- 维修区间、最终卸载、能耗审计通过；
- 能从正式搜索结果选择最终策略。
