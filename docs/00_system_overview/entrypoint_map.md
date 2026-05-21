# 项目入口地图：我想做一件事时该打开哪里

这个文档只回答一个问题：

```text
我回来找入口时，应该打开哪个文件？
```

它不是算法原理，也不是逐行代码说明。

## 1. 最常用入口

| 我想做什么 | 打开哪里 | 这是干什么的 |
|---|---|---|
| 看当前做到哪一步 | `docs/00_system_overview/knowledge_map_workplan.md` | 总进度台账 |
| 直接复制 MATLAB 命令 | `docs/07_reproduction/reproduction_steps/matlab_command_cheatsheet.md` | 命令清单 |
| 看 MATLAB 现在怎么跑 | `docs/07_reproduction/reproduction_steps/00_how_to_run_current_stage.md` | 当前运行说明 |
| 改快速检查运行的数据和参数 | `configs/small_nsga2_config.m` | small 配置入口 |
| 改轻微放大运行的数据和参数 | `configs/medium_nsga2_config.m` | medium 配置入口 |
| 看未来正式运行配置 | `configs/formal_nsga2_config.m` | formal 配置入口，由 formal 运行脚本读取 |
| 跑一次小种群 NSGA-II | `scripts/run_small_nsga2.m` | 配置化运行脚本 |
| 跑一次轻微放大 NSGA-II | `scripts/run_medium_nsga2.m` | medium 运行脚本 |
| 跑一次 formal NSGA-II | `scripts/run_formal_nsga2.m` | formal 运行脚本，当前不含指标计算 |
| 读取 formal 结果并生成最小指标摘要 | `scripts/run_metrics.m` | metrics 最小读取脚本 |
| 看未来指标入口怎么设计 | `docs/07_reproduction/reproduction_steps/17_metrics_entry_design.md` | run_metrics.m 应该读取、计算、输出什么 |
| 理解编码-解码怎么迁移到新课题 | `docs/04_decoding/encoding_decoding_application_overview.md` | 从调度对象到编码、解码、评价、搜索的应用框架 |
| 跑一次单条染色体评价 | `scripts/run_single_evaluation.m` | 单条方案评价脚本 |
| 看复现入口怎么分层 | `docs/07_reproduction/reproduction_steps/10_reproduction_entry_layers.md` | 检查/运行/未来正式实验总入口 |
| 看输出结果放哪里 | `docs/07_reproduction/reproduction_steps/12_outputs_structure.md` | outputs 输出规则 |
| 看每次运行要记录什么 | `docs/07_reproduction/reproduction_steps/13_run_log_and_parameter_record.md` | 运行日志和参数记录规则 |
| 看未来正式实验入口怎么设计 | `docs/07_reproduction/reproduction_steps/14_formal_experiment_entry_design.md` | small / medium / formal / metrics 的入口关系 |
| 看 formal 配置应该有哪些字段 | `docs/07_reproduction/reproduction_steps/15_formal_config_design.md` | 正式实验配置字段设计 |
| 看每个文件夹是干什么的 | `docs/00_system_overview/repository_file_guide.md` | 文件导览 |

## 2. 配置入口在哪里

当前有两个配置入口：

```text
configs/small_nsga2_config.m
configs/medium_nsga2_config.m
configs/formal_nsga2_config.m
```

`small_nsga2_config.m` 是快速检查档：

```text
pop=10, max_gen=2
```

`medium_nsga2_config.m` 是轻微放大档：

```text
pop=20, max_gen=5
```

`formal_nsga2_config.m` 是未来正式运行配置：

```text
pop=30, max_gen=10
```

它是 formal 配置入口，对应的 formal 运行脚本已经有了。

当前 formal 运行入口是：

```text
scripts/run_formal_nsga2.m
```

你在 MATLAB 或编辑器里打开配置文件，就能看到当前运行用的：

```text
.fjs 路径
机器 Excel 路径
AGV Excel 路径
算法目录
输出目录
随机 seed
pop
max_gen
p_cross
p_mutation
AGV 电量和充电参数
```

以后想换数据或改参数，优先打开它。

不要优先改：

```text
scripts/run_small_nsga2.m
raw_code/
src/
```

## 3. 运行入口在哪里

当前最推荐的运行入口是：

```text
scripts/run_small_nsga2.m
```

在 MATLAB 里运行：

```matlab
cd D:\CODEX\code_refactor_project
run('scripts/run_small_nsga2.m')
```

它会做：

```text
读取 configs/small_nsga2_config.m
-> 读取 .fjs / 机器 Excel / AGV Excel
-> 调用原始 NSGA-II
-> 输出 makespan、totalEnergy、Pareto 摘要
-> 保存到 outputs/small_nsga2/时间戳
```

轻微放大运行入口是：

```text
scripts/run_medium_nsga2.m
```

在 MATLAB 里运行：

```matlab
cd D:\CODEX\code_refactor_project
run('scripts/run_medium_nsga2.m')
```

它会读取：

```text
configs/medium_nsga2_config.m
```

并保存到：

```text
outputs/medium_nsga2/时间戳
```

## 4. 测试入口在哪里

这些是“小检查”，不是完整论文实验。

| 检查什么 | 运行什么 |
|---|---|
| `.fjs` 能不能读 | `run('tests/test_read_fjsp.m')` |
| 机器 Excel 能不能读 | `run('tests/test_read_machine_data.m')` |
| AGV Excel 能不能读 | `run('tests/test_read_agv_data.m')` |
| 1 条染色体能不能评价 | `run('tests/test_evaluate_chromosome.m')` |
| 小种群 NSGA-II 能不能跑 2 代 | `run('tests/test_small_nsga2.m')` |
| 配置入口是否完整有效 | `run('tests/test_small_nsga2_config.m')` |
| formal 配置是否完整有效 | `run('tests/test_formal_nsga2_config.m')` |

推荐顺序：

```matlab
cd D:\CODEX\code_refactor_project

run('tests/test_read_fjsp.m')
run('tests/test_read_machine_data.m')
run('tests/test_read_agv_data.m')
run('tests/test_evaluate_chromosome.m')
run('tests/test_small_nsga2_config.m')
run('tests/test_small_nsga2.m')
```

## 5. 新封装函数入口在哪里

这些函数不是直接点运行的主入口，它们是脚本和测试会调用的“零件”。

| 函数 | 作用 |
|---|---|
| `src/data/read_fjsp.m` | 读取 `.fjs`，返回 `problem` |
| `src/data/read_machine_data.m` | 读取机器距离和机器能耗 |
| `src/data/read_agv_data.m` | 读取 AGV 数量、速度和能耗 |
| `src/evaluation/evaluate_chromosome.m` | 给 1 条染色体算 makespan 和 totalEnergy |

你平时不用直接点它们运行。

它们的作用是让上层脚本能更清楚地串起来：

```text
读数据 -> 生成染色体 -> 评价 -> 输出
```

## 6. 原始代码入口在哪里

原始代码都在：

```text
raw_code/
```

当前原则是：

```text
只读，不主动改。
```

常见入口：

| 文件 | 作用 |
|---|---|
| `raw_code/dif_main.m` | 原始对比实验主脚本 |
| `raw_code/same_main.m` | 原始消融或同类实验主脚本 |
| `raw_code/NSGA-II/NSGA2.m` | 基础 NSGA-II 主函数 |
| `raw_code/NSGA-II/init.m` | 生成初始种群 |
| `raw_code/NSGA-II/sorting.m` | 把染色体解码成调度过程 |
| `raw_code/NSGA-II/fitness.m` | 计算目标值 |

现在我们的新脚本主要是调用：

```text
raw_code/NSGA-II
```

还没有扩展到完整对比实验。

## 7. 输出去哪里找

当前所有新脚本输出都应该进入：

```text
outputs/
```

小种群运行输出在：

```text
outputs/small_nsga2/时间戳/
```

单条评价输出在：

```text
outputs/single_evaluation/时间戳/
```

medium 小幅放大输出在：

```text
outputs/medium_nsga2/时间戳/
```

formal 运行输出在：

```text
outputs/formal_nsga2/时间戳/
```

metrics 最小摘要输出在：

```text
outputs/formal_nsga2/时间戳/metrics/
```

`outputs/` 是运行产物，不提交到 GitHub。

更完整的输出规则看：

```text
docs/07_reproduction/reproduction_steps/12_outputs_structure.md
```

每次运行应该记录哪些参数、日志和结果摘要，看：

```text
docs/07_reproduction/reproduction_steps/13_run_log_and_parameter_record.md
```

## 8. 一句话记忆

```text
想改怎么跑 -> 打开 configs/
想真的跑 -> 打开 scripts/
想检查有没有坏 -> 打开 tests/
想看原论文代码 -> 打开 raw_code/
想看解释和路线 -> 打开 docs/
想找结果 -> 打开 outputs/
```

最后复现时不用每次跑所有小配置。小配置是体检工具；真正要跑哪个入口，取决于你这次是快速检查、轻微放大，还是未来的正式实验。

更完整的复现入口分层看：

```text
docs/07_reproduction/reproduction_steps/10_reproduction_entry_layers.md
```

未来正式实验入口和指标入口的设计看：

```text
docs/07_reproduction/reproduction_steps/14_formal_experiment_entry_design.md
```

未来 formal 配置字段设计看：

```text
docs/07_reproduction/reproduction_steps/15_formal_config_design.md
```

未来指标入口设计看：

```text
docs/07_reproduction/reproduction_steps/17_metrics_entry_design.md
```

编码-解码应用理解看：

```text
docs/04_decoding/encoding_decoding_application_overview.md
```
