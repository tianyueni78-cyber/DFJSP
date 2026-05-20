# 复现步骤说明

这个文件夹按“以后真正复现时的操作顺序”整理说明。

它不是聊天记录，也不是代码流水账，而是回答：

```text
我现在做到哪一步了？
这一步拆出了什么？
封装成了什么？
我应该怎么检查？
这一步对后续复现有什么用？
```

## 当前步骤

如果你只是想知道“现在在 MATLAB 里怎么跑”，先看：

```text
matlab_command_cheatsheet.md
00_how_to_run_current_stage.md
```

其中：

```text
matlab_command_cheatsheet.md 只放命令，方便复制到 MATLAB
00_how_to_run_current_stage.md 解释这些命令为什么这么跑
```

| 步骤 | 说明文档 | 当前状态 |
|---|---|---|
| 当前运行入口 | [现在这套封装怎么跑](00_how_to_run_current_stage.md) | 面向初学者的操作入口 |
| 第 1 步 | [数据读取封装](01_data_reading.md) | 已完成第一版 |
| 第 2 步 | [fitness/sorting 最小调用链](02_fitness_sorting_call_chain.md) | 已完成拆解，封装任务已转入第 3 步 |
| 第 3 步 | [单条染色体评价入口](03_single_chromosome_evaluation.md) | 已完成封装，已补正式测试 |
| 第 4 步 | [单条评价运行脚本](04_run_single_evaluation_script.md) | 已完成串联脚本，已由你手动跑通 |
| 第 5 步 | [小种群短迭代](05_run_small_nsga2.md) | 已由你本地跑通，正式测试也已跑通 |
| 第 6 步 | [配置化 small_nsga2](06_config_small_nsga2.md) | 已新增配置入口，已由你本地跑通 |
| 第 7 步 | [数据与配置扩展准备](07_data_config_extension.md) | 已建立扩展前检查说明，步骤检查已由你本地跑通 |
| 第 8 步 | [配置入口测试](08_config_entry_test.md) | 已由你本地跑通 |
| 第 9 步 | [小幅放大参数运行](09_medium_nsga2_run.md) | 已由你本地跑通 |
| 第 10 步 | [运行入口分层整理](10_reproduction_entry_layers.md) | 已建立复现总入口说明 |
| 第 11 步 | [阶段总结与下一阶段路线](11_stage_summary_next_routes.md) | 已总结当前阶段，后续选择路线 A |
| 第 12 步 | [outputs 输出结构整理](12_outputs_structure.md) | 已建立输出目录规则 |

## 后续会怎么加

后面不是随便新增文档，而是每完成一个明确的“拆解 -> 封装 -> 检查”闭环，再补一页。

建议顺序是：

```text
1. 数据读取
2. 参数整理
3. 单个染色体评价
4. 小种群短迭代
5. 配置化运行入口
6. 换数据/改参数运行
7. 数据与配置扩展准备
8. 配置入口测试
9. 小幅放大参数运行
10. 运行入口分层整理
11. 阶段总结与下一阶段路线
12. outputs 输出结构整理
13. 路线 A：继续工程化
```

当前已经完成：

```text
第 1 步：数据读取拆解、封装、测试。
第 2 步：fitness/sorting 调用链拆解。
第 3 步：evaluate_chromosome 封装，并新增正式测试 test_evaluate_chromosome.m。
第 4 步：run_single_evaluation 串联脚本，并已由你手动跑通。
```

当前已经跑通：

```text
第 5 步：小种群短迭代。
```

本次输出摘要：

```text
pop = 10
max_gen = 2
paretoSolutionCount = 3
bestMakespan = 155.886667
bestTotalEnergy = 1890.048000
outputDir = D:\CODEX\code_refactor_project\outputs\small_nsga2\20260519_222017
```

`tests/test_small_nsga2.m` 已由你本地跑通：

```text
test_small_nsga2 passed: paretoSolutionCount=3, bestMakespan=155.886667, bestTotalEnergy=1890.048000
```

第 5 步目前不是重写或封装 `NSGA2.m`，而是用 `scripts/run_small_nsga2.m` 把原始基础 NSGA-II 串起来跑小规模闭环。

第 6 步开始把目标从“完整论文实验”校准为“可复用运行骨架”：以后优先通过 `configs/small_nsga2_config.m` 换数据和改参数。

第 6 步也已由你本地跑通：

```text
pop = 10
max_gen = 2
paretoSolutionCount = 3
bestMakespan = 155.886667
bestTotalEnergy = 1890.048000
outputDir = D:\CODEX\code_refactor_project\outputs\small_nsga2\20260520_112624
```

第 7 步开始整理扩大规模前的操作逻辑：

```text
新数据放哪里
配置改哪里
参数怎么逐步放大
每一步怎么检查
结果去 outputs 哪里找
```

第 7 步建议的检查流程也已由你在 MATLAB 中跑通：

```text
读取检查 -> 单条评价检查 -> 小种群检查 -> 配置化运行
```

第 8 步新增配置入口测试：

```text
tests/test_small_nsga2_config.m
```

它只检查配置文件、路径和参数，不运行完整 NSGA-II。

第 8 步已由你在 MATLAB 中跑通：

```text
test_small_nsga2_config passed: pop=10, max_gen=2, seed=42
```

第 9 步新增 medium 档位：

```text
configs/medium_nsga2_config.m
scripts/run_medium_nsga2.m
```

它用于检查 `pop=20, max_gen=5` 的轻微放大运行，不是完整论文实验。

第 9 步已由你在 MATLAB 中跑通：

```text
pop = 20
max_gen = 5
paretoSolutionCount = 4
bestMakespan = 135.743333
bestTotalEnergy = 1824.221333
outputDir = D:\CODEX\code_refactor_project\outputs\medium_nsga2\20260520_125615
```

第 10 步把当前入口整理成三层：

```text
检查入口：tests/
运行入口：scripts/run_single_evaluation.m、run_small_nsga2.m、run_medium_nsga2.m
未来正式实验入口：后续再整理
```

第 11 步总结当前阶段：

```text
当前已完成“可复用小规模运行骨架”。
后续路线选择 A：继续工程化。
下一步建议：整理 outputs 输出结构。
```

第 12 步已经整理输出规则：

```text
single -> outputs/single_evaluation/时间戳/
small  -> outputs/small_nsga2/时间戳/
medium -> outputs/medium_nsga2/时间戳/
outputs/ 不提交 GitHub
```

第 13 步已经建立运行日志与参数记录规则：

```text
说明文档：13_run_log_and_parameter_record.md

summary.txt 看结果摘要
result.mat 给 MATLAB 后续分析
run_info.txt 记录这次怎么跑出来
log.txt 后续用于排查运行过程
outputDir 是回看一次运行的关键线索
```

当前工程进度更新为：

```text
数据读取
-> 单条染色体评价
-> small/medium NSGA-II
-> 配置化入口
-> outputs 输出结构
-> 运行日志与参数记录规则
```

第 14 步已经整理正式实验入口设计：

```text
说明文档：14_formal_experiment_entry_design.md

tests 是检查
single 是单条评价
small 是快速体检
medium 是轻微放大
formal 是未来正式复现
metrics 是未来结果分析
```

当前还没有实现 `run_formal_nsga2.m` 和 `run_metrics.m`。  
这一步只是先把入口关系分清，避免后面把搜索、指标、画图和日志都塞进一个脚本里。

第 15 步已经整理正式实验配置设计：

```text
说明文档：15_formal_config_design.md

formal 配置应该包含：
experiment
paths
dataset
random
algorithm
energy
output
```

当前已经选择 B，并新增：

```text
configs/formal_nsga2_config.m
```

它只是 formal 配置入口，还不是正式运行脚本。  
当前仍然没有实现 `scripts/run_formal_nsga2.m`。

随后新增 formal 配置测试：

```text
tests/test_formal_nsga2_config.m
```

这个测试只检查 formal 配置能不能读取、字段是否完整，不运行 NSGA-II。
