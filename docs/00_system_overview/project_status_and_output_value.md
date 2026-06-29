# 项目当前状态与输出价值

这个文件只做一件事：把当前仓库到底到了什么阶段、哪些阶段值得看输出，压缩成一页。

## 1. 现在项目是什么情况

结论先说：

- 这已经不是“只有 raw_code 的原始代码仓库”了。
- 现在它是一个已经分层的 MATLAB 源代码项目，包含 `src/`、`configs/`、`scripts/`、`tests/` 和 `docs/`。
- `raw_code/` 仍然保留为只读 baseline，不作为主开发区。

当前可用的主线已经有了：

| 代码层 | 现状 |
|---|---|
| `src/` | 已有独立 decoding / evaluation / search / metrics / visualization 等实现 |
| `configs/` | small / medium / formal / independent / multiseed 等配置入口已建立 |
| `scripts/` | 有小规模运行、formal 运行、baseline 对比、multiseed 汇总、指标和可视化入口 |
| `tests/` | 有 smoke、invalid、contract、raw compare、preflight、dry-run 测试 |
| `docs/` | 有复现步骤、入口地图、阶段说明和运行规则 |

所以更准确地说：

- **代码项目级别**：是，已经达到。
- **论文级完整实验平台**：还没有完全到位。
- **能快速复现和回归的工程化仓库**：是，已经具备。

## 2. 按渐进阶段看，哪些是“契约测试”

这些阶段的价值主要是确认接口和链路，不是看最终实验结果。

| 阶段 | 作用 | 是否产出值得长期看的结果 |
|---|---|---|
| A | 数据读取、基础编码、最小链路确认 | 否，主要是链路契约 |
| B | 小搜索链路 smoke test | 否，主要是运行通路 |
| B-R | 独立 decoding / evaluation 和原实现对照 | 否，主要是正确性对照 |
| C | 独立 search 和原实现对照 | 否，主要是搜索链路对照 |
| C-S2 | 独立配置契约、正式入口预检 | 否，主要是正式入口门禁 |
| C-SEQ2 | multiseed 汇总脚本 dry-run | 否，主要是结构预检 |

这几步的意义是：

- 确认代码链路没断
- 确认接口没变坏
- 确认正式入口能被安全地预检
- 但它们本身不是最终结果展示

## 3. 真正“有输出再看的价值”的阶段

如果你说的是“跑完以后有文件产出，能拿来检查、对比、展示、分析”的阶段，重点是下面这些。

### 3.1 Independent formal 真正运行

对应：

- `scripts/run_independent_formal_nsga2.m`

典型输出：

- `outputs/independent_formal_nsga2/<timestamp>/result.mat`
- `outputs/independent_formal_nsga2/<timestamp>/summary.txt`
- `outputs/independent_formal_nsga2/<timestamp>/run_info.txt`

这一步最值得看，因为它是独立主线的正式结果来源。

你一般会关心：

- Pareto 解集
- `bestMakespan`
- `bestTotalEnergy`
- `runTime`
- `seed`

### 3.2 Independent metrics / visualization

对应：

- `scripts/run_independent_metrics.m`
- `scripts/run_independent_visualization.m`

它们不是重新跑算法，而是吃 `result.mat`，把结果整理成：

- 指标摘要
- 图
- 更方便对外展示的结果

这一步适合“结果解读”，不适合“验证算法有没有跑通”。

### 3.3 Baseline small comparison

对应：

- `scripts/run_baseline_comparison_small.m`

典型输出：

- `outputs/baseline_comparison_small/<timestamp>/result.mat`
- `outputs/baseline_comparison_small/<timestamp>/summary.txt`
- `outputs/baseline_comparison_small/<timestamp>/run_info.txt`

这个阶段的价值是：

- 看 raw baseline 和 independent 版本的差异
- 给论文或报告提供对照
- 也能做回归检查

### 3.4 Independent multiseed summary

对应：

- `scripts/run_independent_multiseed_summary.m`

典型输出：

- `outputs/independent_multiseed/<timestamp>/aggregate_summary.txt`
- `outputs/independent_multiseed/<timestamp>/aggregate_result.mat`
- 每个 seed 的单独输出目录

这个阶段的价值是：

- 看稳定性
- 看均值、标准差、最优/最差
- 为统计结果服务

这一步比单次 formal 更适合做“结果是否稳定”的判断。

## 4. 不太值得单独盯着看的部分

下面这些更适合当门禁，不适合当最终成果：

- `tests/run_all_contract_tests` 这一类轻量契约测试
- `test_*_preflight.m`
- `*_dryrun.m`
- `*_compare_raw.m` 里的结构一致性检查
- small / medium 的 smoke 运行

它们的作用是“先确认不会坏”，不是“拿来展示结果”。

## 5. 最简判断

如果你只想快速记住一句话：

```text
现在这个仓库已经是源代码项目级别了。
契约测试负责保底，真正值得看输出的是 formal、metrics、baseline comparison、multiseed 这四类。
```

## 6. 建议阅读顺序

如果你之后还要继续梳理，推荐顺序是：

1. `docs/00_system_overview/entrypoint_map.md`
2. `docs/07_reproduction/reproduction_steps/README.md`
3. 本文
4. `docs/run_all_contract_tests.md`

