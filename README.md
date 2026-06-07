# Code Refactor Project

> 最新入口：GitHub 默认 `main` 已包含全部更新。第一次了解项目请看 [复现步骤说明](docs/07_reproduction/reproduction_steps/README.md)；准备迁移新项目时，请直接打开 [新项目套用与复现入口顺序](docs/07_reproduction/reproduction_steps/10_reproduction_entry_layers.md)。

面向论文复现的调度算法整理项目。当前重点是把原始 MATLAB 代码逐步拆成清晰的数据层、调度解码层、算法层和实验复现层。

## Knowledge Base

- [知识地图工作表](docs/00_system_overview/knowledge_map_workplan.md)
- [项目入口地图：我想做一件事时该打开哪里](docs/00_system_overview/entrypoint_map.md)
- [项目文件导览：每个板块是干什么的](docs/00_system_overview/repository_file_guide.md)
- [项目易读版：这套代码到底在做什么](docs/00_system_overview/beginner_reading_guide.md)
- [系统五层认知结构](docs/00_system_overview/system_layer_architecture.md)
- [数据层认知地图](docs/02_data_flow/data_layer_map.md)
- [搜索层：基础搜索机制](docs/03_algorithm/search_layer_overview.md)
- [调度解码层：sorting.m 的系统作用](docs/04_decoding/decoding_layer_overview.md)
  - [编码-解码应用理解总览](docs/04_decoding/encoding_decoding_application_overview.md)
  - [编码层结构笔记：chrom 是怎么生成和变化的](docs/04_decoding/encoding_layer_structure_note.md)
- [评价层：调度方案如何被评价](docs/05_evaluation/evaluation_layer_overview.md)
- [实验流程：dif_main.m 和 same_main.m 在跑什么](docs/06_experiments/experiment_flow.md)
- [复现步骤说明](docs/07_reproduction/reproduction_steps/README.md)
  - [MATLAB 复现命令清单](docs/07_reproduction/reproduction_steps/matlab_command_cheatsheet.md)
  - [现在这套封装怎么跑](docs/07_reproduction/reproduction_steps/00_how_to_run_current_stage.md)
  - [第 1 步：数据读取封装](docs/07_reproduction/reproduction_steps/01_data_reading.md)
  - [第 2 步：fitness/sorting 最小调用链](docs/07_reproduction/reproduction_steps/02_fitness_sorting_call_chain.md)
  - [第 3 步：单条染色体评价入口](docs/07_reproduction/reproduction_steps/03_single_chromosome_evaluation.md)
  - [第 4 步：单条评价运行脚本](docs/07_reproduction/reproduction_steps/04_run_single_evaluation_script.md)
  - [第 5 步：小种群短迭代](docs/07_reproduction/reproduction_steps/05_run_small_nsga2.md)
  - [第 6 步：配置化 small_nsga2](docs/07_reproduction/reproduction_steps/06_config_small_nsga2.md)
  - [第 7 步：数据与配置扩展准备](docs/07_reproduction/reproduction_steps/07_data_config_extension.md)
  - [第 8 步：配置入口测试](docs/07_reproduction/reproduction_steps/08_config_entry_test.md)
  - [第 9 步：小幅放大参数运行](docs/07_reproduction/reproduction_steps/09_medium_nsga2_run.md)
  - [第 10 步：运行入口分层整理](docs/07_reproduction/reproduction_steps/10_reproduction_entry_layers.md)
  - [第 11 步：阶段总结与下一阶段路线](docs/07_reproduction/reproduction_steps/11_stage_summary_next_routes.md)
  - [第 12 步：outputs 输出结构整理](docs/07_reproduction/reproduction_steps/12_outputs_structure.md)
  - [第 13 步：运行日志与参数记录设计](docs/07_reproduction/reproduction_steps/13_run_log_and_parameter_record.md)
  - [第 14 步：正式实验入口设计](docs/07_reproduction/reproduction_steps/14_formal_experiment_entry_design.md)
  - [第 15 步：正式实验配置设计](docs/07_reproduction/reproduction_steps/15_formal_config_design.md)
  - [第 17 步：指标入口设计](docs/07_reproduction/reproduction_steps/17_metrics_entry_design.md)
- [数据层复现风险](docs/07_reproduction/data_reproduction_risks.md)
- [复现与封装路线：遇到问题时怎么办](docs/08_engineering/refactor_roadmap.md)

## Current Principle

- 不修改 `raw_code/`
- 小步重构
- 所有实验输出进入 `outputs/`
- 优先保证数据流清晰和实验可复现
## 2026-05-25 编码层入口

当前编码层第一版正式封装已经完成。回 GitHub 找编码层时，优先看：

| 我想做什么 | 打开哪里 |
|---|---|
| 理解 `chrom = [OS, MS, AS, SS]` 的结构 | [encoding_layer_structure_note.md](docs/04_decoding/encoding_layer_structure_note.md) |
| 看每个编码层函数的用途 | [repository_file_guide.md](docs/00_system_overview/repository_file_guide.md) |
| 跑编码层完整 smoke test | `run('tests/test_encoding_layer.m')` |
| 跑编码层异常输入测试 | `run('tests/test_encoding_invalid_cases.m')` |
| 跑编码层 demo 入口 | `run('scripts/run_encoding_smoke.m')` |
| 看 NSGA-II 如何接入新编码层 | [nsga2_encoding_integration_plan.md](docs/03_algorithm/nsga2_encoding_integration_plan.md) |

编码层现在可以独立完成：

```text
读 sample 数据
-> 生成初始 population
-> 验证 population
-> 生成 offspring
-> 再次验证 offspring
```

它不依赖 `raw_code/NSGA-II/init.m`，不依赖 `raw_code/NSGA-II/variation.m`，也不调用 `sorting.m`、`fitness.m` 或 `NSGA2.m`。

## 2026-05-25 搜索层接入入口

新编码层已经有一个旁路搜索接入入口，不修改 `raw_code`：

| 我想做什么 | 运行什么 |
|---|---|
| 跑使用新编码层的小规模 NSGA-II | `run('scripts/run_small_nsga2_refactored.m')` |
| 只测试搜索接入结果结构，不生成 outputs | `run('tests/test_small_nsga2_refactored_encoding.m')` |

注意：这是搜索层接入测试，会调用评价链路里的 `fitness.m` 和 `sorting.m`。它不同于纯编码层 smoke test。

### 2026-05-25 运行记录

`scripts/run_small_nsga2_refactored.m` 已经由用户在 MATLAB 中跑通：

```text
pop = 10
max_gen = 2
paretoSolutionCount = 1
bestMakespan = 138.456667
bestTotalEnergy = 1936.654667
outputDir = outputs/small_nsga2_refactored/20260525_192659
```

这说明新编码层已经接入小规模 NSGA-II 搜索流程。完整项目仍未全部封装完成，后续重点是 `sorting.m` 解码层、`fitness.m` 评价层和完整指标。

## 2026-05-25 解码层入口

当前解码层已经完成 D1-D8 的第一轮拆解、封装和测试。回 GitHub 找解码层时，优先看：

| 我想做什么 | 打开或运行什么 |
|---|---|
| 理解 `sorting.m` 如何把 `chrom` 变成调度过程 | [decoding_layer_structure_note.md](docs/04_decoding/decoding_layer_structure_note.md) |
| 看解码层函数在哪里 | `src/decoding/decode_chromosome.m`, `src/decoding/decode_population.m` |
| 跑解码层正常 smoke test | `run('tests/test_decoding_layer.m')` |
| 跑解码层异常输入测试 | `run('tests/test_decoding_invalid_cases.m')` |
| 对比新封装和原始 `sorting.m` 输出是否一致 | `run('tests/test_decoding_compare_sorting.m')` |

当前已由用户在 MATLAB 中跑通：

```text
test_decoding_layer passed: population=3, operations=55, AGVNum=3
test_decoding_invalid_cases passed
test_decoding_compare_sorting passed: fields matched=5
```

解码层仍然不负责计算 `makespan` / `totalEnergy`，这些属于后续评价层 `fitness.m` 的拆解范围。
## 2026-05-29 Independent 主线更新

项目现在已经补上第 21-25 步 independent 主线。也就是说，当前已经不只是 raw wrapper，而是有第一版脱离 raw `sorting.m` / `fitness.m` / `NSGA2.m` 的 independent 链路。

新增复现步骤说明：

- [第 21 步：独立 decoding 实现](docs/07_reproduction/reproduction_steps/21_independent_decoding.md)
- [第 22 步：独立 evaluation 实现](docs/07_reproduction/reproduction_steps/22_independent_evaluation.md)
- [第 23 步：独立 NSGA-II search 实现](docs/07_reproduction/reproduction_steps/23_independent_nsga2_search.md)
- [第 24 步：raw 对照测试总验收](docs/07_reproduction/reproduction_steps/24_independent_raw_compare.md)
- [第 25 步：independent small / medium / formal 验收](docs/07_reproduction/reproduction_steps/25_independent_experiment_entries.md)

新增 independent 入口：

| 类型 | 文件 |
|---|---|
| small config | `configs/independent_small_config.m` |
| medium config | `configs/independent_medium_config.m` |
| formal config | `configs/independent_formal_config.m` |
| small runner | `scripts/run_independent_small_nsga2.m` |
| medium runner | `scripts/run_independent_medium_nsga2.m` |
| formal preflight / guarded runner | `scripts/run_independent_formal_nsga2.m` |

关键文档：

- [independent decoding 说明](docs/04_decoding/independent_decoding_guide.md)
- [independent evaluation 说明](docs/05_evaluation/independent_evaluation_guide.md)
- [independent NSGA-II search 说明](docs/03_algorithm/independent_nsga2_search_guide.md)
- [independent raw 对照验收](docs/07_reproduction/independent_raw_compare_acceptance.md)
- [independent 实验入口说明](docs/06_experiments/independent_experiment_entry_guide.md)

当前结论：

```text
raw_code 是只读 baseline。
src 已经有 independent decoding / evaluation / NSGA-II search。
scripts 已经有 independent small / medium / formal preflight。
tests 已经有 independent 验收和 raw 对照。
outputs 仍然不提交 Git。
```

## 2026-06-07 Independent 完整闭环更新

第 26-30 步已经完成，不再是待办事项：

```text
26. independent formal 已真实运行
27. independent metrics / visualization 已接入 outputs
28. baseline 对比 small 闭环已跑通
29. 多 seed 统计汇总入口已完成
30. 新项目迁移演练与模板 config 已完成
```

最近一次 independent formal 运行记录：

```text
dataset: Mk01
seed: 42
pop: 30
max_gen: 10
runTime: 7.625127
paretoSolutionCount: 4
bestMakespan: 111.853333
bestTotalEnergy: 1669.020000
usedRawSearch: 0
usedRawDecoding: 0
usedRawEvaluation: 0
```

### 我现在应该打开哪里

| 目的 | 入口 |
|---|---|
| 遇到新项目，想知道怎么往当前框架上套 | [新项目套用与复现入口顺序](docs/07_reproduction/reproduction_steps/10_reproduction_entry_layers.md) |
| 查看完整的新项目迁移方法 | [新项目迁移手册](docs/08_engineering/new_project_migration_guide.md) |
| 查看一次低碳调度新项目迁移演练 | [新项目迁移演练](docs/08_engineering/new_project_migration_rehearsal.md) |
| 新增目标函数 | [新目标函数模板](docs/08_engineering/new_objective_template.md) |
| 新增算法改进 | [新算法改进模板](docs/08_engineering/algorithm_improvement_template.md) |
| 做 baseline 对比 | [baseline 对比模板](docs/08_engineering/baseline_comparison_template.md) |
| 记录论文实验 | [论文实验记录模板](docs/08_engineering/paper_experiment_record_template.md) |
| 运行 independent small / medium / formal | [independent 实验入口说明](docs/06_experiments/independent_experiment_entry_guide.md) |
| 分析 formal 输出 | [independent 结果分析说明](docs/06_experiments/independent_result_analysis_guide.md) |
| 查看多 seed 汇总流程 | [多 seed 汇总说明](docs/06_experiments/independent_multiseed_summary_guide.md) |

当前项目可以作为类似 FJSP-AGV 论文项目的可迁移骨架。新项目仍应按照：

```text
config/data dry-run
-> encoding
-> decoding
-> evaluation
-> independent small
-> metrics / visualization
-> independent medium
-> formal preflight
-> independent formal
-> baseline / multiseed
```

逐层迁移和验收，不应直接从新数据跳到 formal。
