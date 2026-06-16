# 阶段 C 第 16.4 步：连续故障正式搜索入口

## 本步目标

建立连续故障完全重调度正式搜索配置与结果保存入口：

1. 配置种群规模、最大代数、交叉变异概率和自适应停止参数；
2. 复用第 16.3 步轻量搜索验证过的搜索器；
3. 将正式结果保存到新的时间戳输出目录；
4. 输出 `result.mat`、Pareto 目标 CSV、搜索历史 CSV 和运行摘要；
5. 本步只检查配置和入口，不运行正式搜索。

## 正式配置

- 种群规模：`10`
- 最大代数：`100`
- 连续无改善停止：`10` 代
- 时间上限：`30` 秒
- 随机种子：`42`
- 输出目录：`outputs/stage_c_sequential_complete_reschedule_search/<timestamp>/`

## 代码入口

- 配置：`configs/stage_c_sequential_complete_search_config.m`
- 正式入口：`scripts/run_stage_c_sequential_complete_search.m`
- 配置测试：`tests/test_stage_c_sequential_complete_search_config.m`

## 当前边界

本步不运行正式搜索、不创建输出目录、不执行组合选择。正式搜索需要单独确认。
