# 阶段 B-R 第 10 步：正式搜索配置与结果保存入口

## 目标

为从头加工规则下的完全重调度建立单随机种子正式搜索配置和结果保存入口。

本步只完成静态实现和配置测试。配置测试不会运行搜索、不会创建输出目录。

## 正式搜索配置

```text
种群规模：10
最大代数：100
交叉概率：0.8
变异概率：0.2
锦标赛规模：2
连续无改善停止：10 代
最长运行时间：30 秒
改善容差：1e-9
随机种子：42
```

搜索不强制跑满 `100` 代，满足连续无改善或时间上限时提前停止。

## 输出目录

正式运行时，每次创建独立目录：

```text
outputs/stage_br_complete_reschedule_search/YYYYMMDD_HHMMSS/
```

如果同一秒目录已存在，自动增加编号，不覆盖已有结果。

## 保存内容

- `result.mat`：场景、配置、搜索种群和 Pareto 候选；
- `pareto_objectives.csv`：最终卸载时间与总能耗；
- `search_history.csv`：每代最小目标和 Pareto 数量；
- `run_summary.txt`：参数、故障、停止原因及目标摘要。

运行摘要还记录：

- 从头加工标志；
- 进度不保留标志；
- 故障前损失加工时间；
- 完整重加工时间；
- 实际机器总加工时间。

## 运行边界

- `is_formal_search = true`；
- `is_full_experiment = false`；
- 本入口会运行 MATLAB 搜索并生成输出，执行前必须得到确认。

## 代码入口

- 配置：
  [`stage_br_complete_search_config.m`](../configs/stage_br_complete_search_config.m)
- 正式运行：
  [`run_stage_br_complete_search.m`](../scripts/run_stage_br_complete_search.m)
- 配置测试：
  [`test_stage_br_complete_search_config.m`](../tests/test_stage_br_complete_search_config.m)

## 当前测试

以下测试只检查配置和入口，不运行搜索：

```matlab
run(fullfile(pwd,'tests','test_stage_br_complete_search_config.m'))
```

配置测试通过后，正式搜索仍需单独确认。
