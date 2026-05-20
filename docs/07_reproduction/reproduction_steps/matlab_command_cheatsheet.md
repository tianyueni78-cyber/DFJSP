# MATLAB 复现命令清单

这个文档只回答一个问题：

```text
我打开 MATLAB 以后，命令行里到底输入什么？
```

先进入项目目录：

```matlab
cd D:\CODEX\code_refactor_project
```

## 1. 最常用：确认项目还能跑

隔了一段时间回来，先跑这两条：

```matlab
run('tests/test_small_nsga2_config.m')
run('scripts/run_small_nsga2.m')
```

这两条的意思是：

```text
先检查配置有没有坏
再跑 small 档位
```

如果这两条正常，说明当前项目基本还活着。

## 2. 我只是想检查数据

```matlab
run('tests/test_read_fjsp.m')
run('tests/test_read_machine_data.m')
run('tests/test_read_agv_data.m')
```

这三条检查：

```text
.fjs 能不能读
机器 Excel 能不能读
AGV Excel 能不能读
```

## 3. 我想检查配置

```matlab
run('tests/test_small_nsga2_config.m')
```

正常输出：

```text
test_small_nsga2_config passed: pop=10, max_gen=2, seed=42
```

## 4. 我想跑单条染色体评价

```matlab
run('scripts/run_single_evaluation.m')
```

这条会做：

```text
读数据
生成 1 条 chrom
调用 fitness/sorting
输出 makespan 和 totalEnergy
```

结果放在：

```text
outputs/single_evaluation/时间戳/
```

MATLAB 命令行会打印：

```text
outputDir: ...
```

这个就是本次结果目录。

## 5. 我想跑 small 档位

```matlab
run('scripts/run_small_nsga2.m')
```

当前参数：

```text
pop = 10
max_gen = 2
```

结果放在：

```text
outputs/small_nsga2/时间戳/
```

MATLAB 命令行会打印：

```text
outputDir: ...
```

这个就是本次结果目录。

用途：

```text
快速确认搜索流程没有坏。
```

## 6. 我想跑 medium 档位

```matlab
run('scripts/run_medium_nsga2.m')
```

当前参数：

```text
pop = 20
max_gen = 5
```

结果放在：

```text
outputs/medium_nsga2/时间戳/
```

MATLAB 命令行会打印：

```text
outputDir: ...
```

这个就是本次结果目录。

用途：

```text
确认参数轻微放大以后还能跑。
```

## 7. 我换数据以后先跑什么

换 `.fjs`、机器 Excel 或 AGV Excel 后，建议顺序是：

```matlab
cd D:\CODEX\code_refactor_project

run('tests/test_read_fjsp.m')
run('tests/test_read_machine_data.m')
run('tests/test_read_agv_data.m')
run('tests/test_small_nsga2_config.m')
run('scripts/run_small_nsga2.m')
```

## 8. 我不用每次都跑什么

不用每次都跑全部测试。

可以这样理解：

| 场景 | 跑什么 |
|---|---|
| 平时快速确认 | 配置测试 + small |
| 换数据 | 数据测试 + 配置测试 + small |
| 想轻微放大 | medium |
| 想排查单条评价 | single evaluation |
| 想完整论文实验 | 以后等正式实验入口整理好 |

## 9. 当前还没有哪个命令

当前还没有实现的正式复现命令是：

```matlab
run('scripts/run_formal_nsga2.m')
```

当前还没有实现的指标计算命令是：

```matlab
run('scripts/run_metrics.m')
```

也就是说：

```text
正式实验入口和指标入口还没有做。
```

现在已经有的是：

```text
single
small
medium
```

入口关系看：

```text
docs/07_reproduction/reproduction_steps/14_formal_experiment_entry_design.md
```

formal 配置字段设计看：

```text
docs/07_reproduction/reproduction_steps/15_formal_config_design.md
```

当前已经有 formal 配置文件：

```text
configs/formal_nsga2_config.m
```

但它不能直接当运行命令用。现在还不能跑：

```matlab
run('scripts/run_formal_nsga2.m')
```

因为正式运行脚本还没有实现。

## 10. 跑完以后去哪找结果

看 MATLAB 命令行最后一行：

```text
outputDir: ...
```

如果跑的是 single：

```text
outputs/single_evaluation/时间戳/
```

如果跑的是 small：

```text
outputs/small_nsga2/时间戳/
```

如果跑的是 medium：

```text
outputs/medium_nsga2/时间戳/
```

`outputs/` 是本地运行结果，不提交 GitHub。

## 11. 跑完以后要记录什么

每次跑完，先看 MATLAB 命令行最后打印的：

```text
outputDir: ...
```

这个目录就是本次运行结果的位置。

现在你至少要看两个文件：

```text
summary.txt
*_result.mat
```

它们的作用是：

| 文件 | 怎么理解 |
|---|---|
| `summary.txt` | 人能直接看懂的结果摘要，例如 bestMakespan、bestTotalEnergy |
| `*_result.mat` | MATLAB 保存的结果变量，以后要画图或继续分析时用 |

以后会逐步补充：

```text
run_info.txt
log.txt
```

简单记：

```text
summary 看结果。
run_info 看这次怎么跑出来。
result.mat 给 MATLAB 继续分析。
log 用来排查问题。
```

运行记录的详细规则看：

```text
docs/07_reproduction/reproduction_steps/13_run_log_and_parameter_record.md
```
