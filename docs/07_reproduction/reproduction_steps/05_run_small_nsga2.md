# 第 5 步：小种群短迭代

## 1. 这一步在做什么

前面已经跑通：

```text
数据 -> 1 条 chrom -> fitness/sorting -> makespan + totalEnergy
```

第 5 步把规模稍微放大：

```text
1 条 chrom
-> 10 条 chrom
-> NSGA-II 跑 2 代
```

新增脚本：

```text
scripts/run_small_nsga2.m
```

它不是完整论文实验，而是一个小型 NSGA-II 闭环检查。

## 2. 这个脚本跑什么

当前参数是：

| 参数 | 当前值 | 含义 |
|---|---:|---|
| `pop` | `10` | 种群数量 |
| `max_gen` | `2` | 迭代代数 |
| `p_cross` | `0.8` | 交叉概率 |
| `p_mutation` | `0.2` | 变异概率 |
| `rng` | `42` | 随机种子 |
| 算法目录 | `raw_code/NSGA-II` | 基础 NSGA-II 链路 |

它会执行：

```text
读 .fjs
读机器 Excel
读 AGV Excel
生成初始种群
调用 NSGA2.m
反复调用 fitness/sorting
完成 2 代选择、交叉、变异、非支配排序
保存结果到 outputs/small_nsga2/时间戳/
```

## 3. 输入、过程、输出

### 输入

| 输入 | 文件或来源 |
|---|---|
| 标准算例 | `data_sample/Mk01.fjs` |
| 机器数据 | `data_sample/机器数据.xlsx` |
| AGV 数据 | `data_sample/AGV数据.xlsx` |
| 小规模算法参数 | 脚本内临时设置 |

### 过程

```text
read_fjsp
-> read_machine_data
-> read_agv_data
-> init 生成 10 条 chrom
-> NSGA2
-> fitness/sorting 多次评价
-> non_domination
-> tournament_selection
-> variation
-> replace_chrom
```

### 输出

结果保存到：

```text
outputs/small_nsga2/时间戳/
```

里面会有：

| 文件 | 内容 |
|---|---|
| `summary.txt` | 人能快速看的摘要 |
| `small_nsga2_result.mat` | MATLAB 结果数据 |

命令行会显示：

```text
small NSGA-II finished.
pop: 10, max_gen: 2
paretoSolutionCount: ...
bestMakespan: ...
bestTotalEnergy: ...
outputDir: ...
```

## 4. 这一步在复现中有什么用

第 4 步只证明：

```text
一个方案能被评价。
```

第 5 步要证明：

```text
一个小型算法搜索过程能跑完。
```

它会检查更多环节：

```text
init 生成种群
fitness 批量评价
non_domination 非支配排序
tournament_selection 选择父代
variation 交叉变异
replace_chrom 更新种群
NSGA2 主循环
```

如果第 5 步跑通，说明：

```text
基础 NSGA-II 的最小闭环已经能工作。
```

但它仍然不是论文最终实验。

## 5. 和完整实验的区别

当前小实验：

```text
pop = 10
max_gen = 2
只跑 NSGA-II
只用 Mk01 小样本
只看能不能跑通
```

完整实验以后才会涉及：

```text
更大种群
更多迭代
多个算例
多个算法对比
消融实验
HV / IGD / Spacing / C-metric
图表输出
```

所以第 5 步是桥：

```text
单条评价
-> 小型算法闭环
-> 完整实验复现
```

## 6. 你在 MATLAB 里怎么跑

输入：

```matlab
cd D:\CODEX\code_refactor_project
run('scripts/run_small_nsga2.m')
```

如果报错，把完整红色报错贴回来。

如果跑通，把命令行输出贴回来，我再更新工作表。

