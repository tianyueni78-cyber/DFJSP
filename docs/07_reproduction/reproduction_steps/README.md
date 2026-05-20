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
00_how_to_run_current_stage.md
```

| 步骤 | 说明文档 | 当前状态 |
|---|---|---|
| 当前运行入口 | [现在这套封装怎么跑](00_how_to_run_current_stage.md) | 面向初学者的操作入口 |
| 第 1 步 | [数据读取封装](01_data_reading.md) | 已完成第一版 |
| 第 2 步 | [fitness/sorting 最小调用链](02_fitness_sorting_call_chain.md) | 已完成拆解，封装任务已转入第 3 步 |
| 第 3 步 | [单条染色体评价入口](03_single_chromosome_evaluation.md) | 已完成封装，已补正式测试 |
| 第 4 步 | [单条评价运行脚本](04_run_single_evaluation_script.md) | 已完成串联脚本，已由你手动跑通 |
| 第 5 步 | [小种群短迭代](05_run_small_nsga2.md) | 已由你本地跑通，正式测试也已跑通 |

## 后续会怎么加

后面不是随便新增文档，而是每完成一个明确的“拆解 -> 封装 -> 检查”闭环，再补一页。

建议顺序是：

```text
1. 数据读取
2. 参数整理
3. 单个染色体评价
4. 小种群短迭代
5. 完整实验复现
6. 指标与图表复现
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
