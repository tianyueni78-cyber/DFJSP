# 全部轻量契约测试入口

这个入口把仓库里已经存在的轻量 contract / config / audit 测试串成一条一键验证链，适合在改动后快速确认“代码链路还通不通”。

## 它验证什么

- 阶段 A 的基础读取、编码和小样本 NSGA-II 链路。
- 阶段 B 的小搜索链路。
- 阶段 B-R 的独立解码与评价是否和原始实现保持一致。
- 阶段 C 的独立搜索链路。
- 阶段 C-S2 的独立配置契约与正式入口预检。
- 阶段 C-SEQ2 的多随机种子汇总脚本结构预检。

## 阶段对应

| 阶段 | 测试文件 |
| --- | --- |
| A | `tests/test_small_nsga2_config.m`, `tests/test_small_nsga2.m` |
| B | `tests/test_search_small_loop.m` |
| B-R | `tests/test_decoding_independent_compare_sorting.m`, `tests/test_evaluation_independent_compare_raw.m` |
| C | `tests/test_search_independent_compare_raw.m` |
| C-S2 | `tests/test_independent_experiment_configs.m`, `tests/test_independent_formal_preflight.m` |
| C-SEQ2 | `tests/test_independent_multiseed_summary_dryrun.m` |

## 它不验证什么

- 不跑正式长实验。
- 不跑正式搜索规模、正式多随机种子实验、正式结果统计。
- 不跑 30 秒搜索入口或任何时间预算驱动的正式搜索入口。
- 不跑会生成正式 `outputs/` 的实验入口。
- 不替代性能评估、论文级对比或统计结论。

## 纳入的测试

- `tests/test_small_nsga2_config.m`
- `tests/test_small_nsga2.m`
- `tests/test_search_small_loop.m`
- `tests/test_decoding_independent_compare_sorting.m`
- `tests/test_evaluation_independent_compare_raw.m`
- `tests/test_search_independent_compare_raw.m`
- `tests/test_independent_experiment_configs.m`
- `tests/test_independent_formal_preflight.m`
- `tests/test_independent_multiseed_summary_dryrun.m`

## 没有纳入的正式实验

- `scripts/run_formal_nsga2.m`
- `scripts/run_independent_formal_nsga2.m`
- `scripts/run_medium_nsga2.m`
- `scripts/run_independent_medium_nsga2.m`
- `scripts/run_independent_multiseed_summary.m`
- 任何正式、长时、批量、多随机种子的实验入口

## 如何运行

在仓库根目录执行：

```powershell
matlab -batch "addpath('scripts'); run_all_contract_tests()"
```

如果你已经在 MATLAB 里，也可以直接运行：

```matlab
addpath('scripts');
run_all_contract_tests()
```

该入口通过 `mfilename` 自动定位仓库根目录，不依赖当前 PowerShell 目录。

## 为什么叫“轻量契约测试”

“轻量”指的是它们只做快速验证，尽量不碰正式实验产物，也不追求大规模搜索结果。

“契约”指的是它们检查代码之间的接口和行为边界，例如配置字段、输入输出结构、独立实现与原实现的一致性、脚本是否按预期组织。

所以它是在快速确认代码链路，而不是在说明这个项目的代码规模小。

## 和正式实验的关系

这组测试是正式实验之前的门槛，不是正式实验本身。

- 正式实验负责产出结果、汇总指标和可展示的对比数据。
- 多随机种子实验负责统计稳定性和分布。
- 结果统计负责把实验产物整理成可读结论。

这份一键入口只负责确认这些流程的“代码骨架”没有断，便于在正式跑实验前先做快速回归。
