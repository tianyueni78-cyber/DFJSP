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
| 看 MATLAB 现在怎么跑 | `docs/07_reproduction/reproduction_steps/00_how_to_run_current_stage.md` | 当前运行说明 |
| 改小种群运行的数据和参数 | `configs/small_nsga2_config.m` | 配置入口 |
| 跑一次小种群 NSGA-II | `scripts/run_small_nsga2.m` | 配置化运行脚本 |
| 跑一次单条染色体评价 | `scripts/run_single_evaluation.m` | 单条方案评价脚本 |
| 看每个文件夹是干什么的 | `docs/00_system_overview/repository_file_guide.md` | 文件导览 |

## 2. 配置入口在哪里

当前配置入口是：

```text
configs/small_nsga2_config.m
```

你在 MATLAB 或编辑器里打开这个文件，就能看到当前小种群运行用的：

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

## 4. 测试入口在哪里

这些是“小检查”，不是完整论文实验。

| 检查什么 | 运行什么 |
|---|---|
| `.fjs` 能不能读 | `run('tests/test_read_fjsp.m')` |
| 机器 Excel 能不能读 | `run('tests/test_read_machine_data.m')` |
| AGV Excel 能不能读 | `run('tests/test_read_agv_data.m')` |
| 1 条染色体能不能评价 | `run('tests/test_evaluate_chromosome.m')` |
| 小种群 NSGA-II 能不能跑 2 代 | `run('tests/test_small_nsga2.m')` |

推荐顺序：

```matlab
cd D:\CODEX\code_refactor_project

run('tests/test_read_fjsp.m')
run('tests/test_read_machine_data.m')
run('tests/test_read_agv_data.m')
run('tests/test_evaluate_chromosome.m')
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

`outputs/` 是运行产物，不提交到 GitHub。

## 8. 一句话记忆

```text
想改怎么跑 -> 打开 configs/
想真的跑 -> 打开 scripts/
想检查有没有坏 -> 打开 tests/
想看原论文代码 -> 打开 raw_code/
想看解释和路线 -> 打开 docs/
想找结果 -> 打开 outputs/
```
