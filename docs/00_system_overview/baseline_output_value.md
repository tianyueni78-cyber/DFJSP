# baseline 输出说明

这个文件单独回答一个问题：仓库里的“baseline”到底是哪一类输出。

## baseline 入口

如果你要直接看 baseline 对照，先打开这些：

- [baseline 输出说明](baseline_output_value.md)
- `scripts/run_baseline_comparison_small.m`
- `tests/test_baseline_comparison_config.m`
- `tests/test_baseline_comparison_small.m`

如果你只想记一个命令，baseline 对照入口是：

```matlab
run('scripts/run_baseline_comparison_small.m')
```

## 1. baseline 不是所有输出

不是。

当前仓库里的输出大致分两类：

- **baseline 对照输出**：用原始 `raw_code/` 作为参考，和 independent 版本做对比
- **independent 正式输出**：单独跑独立实现，用于正式结果、指标和统计

所以：

- `baseline` 不是默认所有输出
- `baseline` 也不是 `formal`、`metrics`、`multiseed` 的代名词
- `baseline` 只是一条专门的对照线

## 2. 哪些算 baseline 相关

当前最明确的 baseline 相关入口是：

- `scripts/run_baseline_comparison_small.m`

相关测试是：

- `tests/test_baseline_comparison_config.m`
- `tests/test_baseline_comparison_small.m`

这条线的目标很直接：

- baseline 用原始 `raw NSGA-II`
- variant 用 independent 版本
- 两者在同一数据、同一 seed、同一小规模参数下对比

## 3. baseline 输出看什么

baseline 对照通常会产出：

- `outputs/baseline_comparison_small/<timestamp>/result.mat`
- `outputs/baseline_comparison_small/<timestamp>/summary.txt`
- `outputs/baseline_comparison_small/<timestamp>/run_info.txt`

其中最值得看的内容是：

- baseline / variant 的解集大小
- baseline / variant 的最佳 makespan
- baseline / variant 的最佳 totalEnergy
- `baselineUsedRawSearch`
- `baselineUsedRawDecoding`
- `baselineUsedRawEvaluation`

这能回答一个核心问题：

```text
independent 版本是不是在和原始 baseline 同口径对照？
```

## 4. baseline 和正式输出的关系

baseline 比较更像“验证和对照”，不是最终论文结果本体。

| 类型 | 作用 | 值不值得长期看 |
|---|---|---|
| baseline 对照 | 看 independent 是否和 raw baseline 同口径、同输入、同 seed | 值得看，但主要是对照 |
| formal 输出 | 看独立实现的正式结果 | 值得看 |
| metrics 输出 | 看指标汇总和图 | 值得看 |
| multiseed 输出 | 看稳定性和统计分布 | 值得看 |

简单说：

- **baseline** 重点在“对照是否成立”
- **formal / metrics / multiseed** 重点在“结果是否可展示、可统计”

## 5. 什么时候该看 baseline

建议优先看 baseline 的场景：

- 你改了 decoding / evaluation / search 后，想确认没有偏离原始行为
- 你想证明 independent 版本不是随便改出来的
- 你需要一条原始对照线来解释新结果

不建议把 baseline 当成唯一重点的场景：

- 你在看最终实验结果
- 你在做多 seed 统计
- 你在做指标图表整理

## 6. 最简结论

```text
baseline 不是所有输出。
baseline 只是一条原始对照线，最核心的输出是 baseline comparison small。
```
