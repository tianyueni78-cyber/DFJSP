# 阶段 A 第 13 步：完全重调度搜索与组合评价

## 1. 目标

在第 12 步正式冻结问题上，对 `53` 道未开工工序运行同等预算的完全重调度
搜索，再与 AGV 联动部分右移方案统一计算 `tD`、`SD` 和 `Y`。

## 2. 正式输入

```text
正常基线完工时间：112.72
故障：J8-O1 / M2 / tf=12 / tr=5
冻结工序：5
可重调度工序：53
```

## 3. 搜索预算

与第 10 步正常基线搜索一致：

- 种群 `10`；
- 最大 `100` 代；
- 交叉概率 `0.8`；
- 变异概率 `0.2`；
- 连续 `10` 代无 Pareto 改善停止；
- 最长 `30` 秒；
- 随机种子 `42`。

## 4. 评价与选择

完全重调度目标：

```text
最终卸载最大完工时间
机器与 AGV 总能耗
```

组合指标：

```text
tD = 候选最终卸载完工时间 - 正常基线完工时间
SD = 未开工工序机器分配变化数
Y = 0.9 * tD + 0.1 * SD
```

候选包括一个 AGV 联动部分右移方案和全部去重完全重调度 Pareto 方案。

## 5. 代码修改

新增：

- `configs/stage_a_step_13_config.m`
- `scripts/run_stage_a_step_13_contract.m`
- `scripts/run_stage_a_step_13_search_and_selection.m`
- `tests/test_stage_a_step_13_contract.m`

不修改完全重调度搜索、候选解码、能耗计算和组合评价核心算法。

## 6. 测试与正式运行

轻量契约测试：

```matlab
run(fullfile(pwd, 'tests', ...
    'test_stage_a_step_13_contract.m'))
```

正式运行会生成新输出目录：

```matlab
stage13 = run_stage_a_step_13_search_and_selection(stage12);
```

输出包括：

- `result.mat`
- `pareto_objectives.csv`
- `search_history.csv`
- `combination_evaluations.csv`
- `run_summary.txt`

## 7. 路径依赖修正

首次契约测试暴露出第 13 步入口遗漏 `src/scheduling/` 路径，导致完全重调度
解码器无法找到原运输时间函数：

```text
spare_transfer_time_compute
```

现已在轻量入口和正式入口中统一加入 `src/scheduling/`，并在契约测试中
检查依赖文件存在。入口内部在搜索前检查函数可见，入口结束后恢复原 MATLAB
路径，因此测试不再错误要求该函数在入口返回后仍永久可见。没有修改运输
时间函数或解码算法。
