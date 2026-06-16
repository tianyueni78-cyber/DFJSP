# 阶段 C 第 17.2 步：最终审计多随机种子入口

## 目标

为阶段 C 最终审计矩阵中已经实现的两个可运行场景建立统一的多随机种子正式实验入口：

- `C-S1`：两台机器同时故障，保留进度继续加工；
- `C-SEQ1`：两次故障先后发生且维修不重叠，保留进度继续加工。

`C-S2` 和 `C-SEQ2` 仍是计划项，不在本次多随机种子入口中运行。

## 本步完成的内容

- 新增 `stage_c_final_audit_multiseed_config`，统一种子、种群规模、迭代上限和自适应停止规则；
- 新增 `run_stage_c_final_audit_multiseed`，按场景和随机种子循环运行正式搜索；
- 对每次运行执行组合选择，记录 `tD`、`SD`、`Y`、策略选择、Pareto 数量、停止原因和审计结果；
- 输出 `result.mat`、`multiseed_summary.csv`、`scenario_summary.csv` 和 `run_summary.txt`；
- 新增配置契约测试，确认入口存在且只覆盖已实现场景。

## 代码入口

- 配置：`configs/stage_c_final_audit_multiseed_config.m`
- 正式运行入口：`scripts/run_stage_c_final_audit_multiseed.m`
- 契约测试：`tests/test_stage_c_final_audit_multiseed_config.m`

## 运行方式

先运行轻量配置测试：

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_c_final_audit_multiseed_config.m'))
```

确认后再运行正式多随机种子实验：

```matlab
cd('D:\CODEX\机器故障')
addpath(fullfile(pwd,'scripts'))
result = run_stage_c_final_audit_multiseed();
```

## 当前状态

入口已建立，正式实验尚未运行。

正式运行属于输出生成和多随机种子实验，应在确认后执行。
