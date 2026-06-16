# C-S2 第 12 步：权重敏感性、多随机种子与最终审计

## 目标

在 C-S2 正式组合选择之后，检查结论是否稳定：

- 固定第 11 步候选集，扫描 `omega1=0:0.1:1`；
- 对局部右移和完全重调度 Pareto 候选重新做 C-S2 专用审计；
- 建立五随机种子正式实验入口，但不在契约测试中运行。

## 配置

`configs/stage_cs2_step_12_config.m` 定义：

- 种群 `10`；
- 最大 `100` 代；
- 连续 `10` 代无改善停止；
- 最长 `30` 秒；
- 随机种子 `[11,22,33,42,55]`；
- 权重扫描 `0:0.1:1`；
- 输出目录 `outputs/stage_cs2_step_12_robustness/`。

## 代码入口

- `src/evaluation/analyze_stage_cs2_weight_sensitivity.m`
- `scripts/run_stage_cs2_step_12_analysis.m`
- `scripts/run_stage_cs2_step_12_multiseed.m`
- `tests/test_stage_cs2_step_12_contract.m`

## 契约测试命令

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_cs2_step_12_contract.m'))
```

## 正式五随机种子命令

运行前需要单独确认，因为会执行 5 次正式搜索并生成输出：

```matlab
cd('D:\CODEX\机器故障')
addpath(fullfile(pwd,'scripts'))

data = load(fullfile(pwd,'outputs', ...
    'stage_cs2_complete_reschedule_search', ...
    '20260616_150249','result.mat'));

stage11 = run_stage_cs2_combination_selection(data.scenario);
stage12Multiseed = run_stage_cs2_step_12_multiseed(stage11);
```

## 完成标准

- 权重扫描覆盖 `0:0.1:1`；
- 所有候选通过 C-S2 从头加工、维修、最终卸载和能耗审计；
- 多随机种子入口可复用同一 C-S2 场景；
- 正式多随机种子运行后能输出 `multiseed_summary.csv`。
