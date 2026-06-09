# 阶段 A 完全重调度确认运行（10×20）

## 1. 目的

在完整正式实验前，使用已通过契约测试的完全重调度搜索器进行一次中等规模确认运行，检查运行时间、Pareto 解数量、完整双目标和结果保存流程。

本次不是最终研究实验，不用于形成多次独立运行的统计结论。

## 2. 已确认参数

```text
种群规模：10
迭代代数：20
交叉概率：0.8
变异概率：0.2
锦标赛规模：2
连续无改善停止代数：10
最长运行时间：30 秒
改善判断容差：1e-9
随机种子：42
```

参数参考原项目入口中使用的 `pop=10`、`max_gen=20`、`p_cross=0.8` 和 `p_mutation=0.2`。新搜索器不会采用原 `INSGA_II.m` 内部强制覆盖为 150 的行为。

## 3. 评价目标

```text
final_unload_makespan
total_energy
```

即最终卸载最大完工时间和机器与 AGV 总能耗。

## 4. 自适应停止与 Pareto 去重

每代先按两个目标值对 Pareto 前沿去重。改善不是只看某一个目标，而是判断当前非支配目标集合中是否出现了一个不被历史 Pareto 档案弱支配的新目标点。

搜索在以下任一条件满足时停止：

1. 达到最大迭代代数 `20`；
2. 连续 `10` 代没有 Pareto 改善；
3. 搜索运行达到 `30` 秒。

结果记录实际完成代数、停止原因和去重后的 Pareto 前沿。

## 5. 输出规则

每次运行创建独立时间戳目录：

```text
outputs/stage_a_complete_reschedule_confirmation/YYYYMMDD_HHMMSS/
```

目录内保存：

- `result.mat`：完整场景、搜索结果和配置；
- `pareto_objectives.csv`：Pareto 解的两个目标值；
- `search_history.csv`：每代最小目标值和 Pareto 数量；
- `run_summary.txt`：参数、运行时间和最小目标摘要。

已有目录不会被覆盖。

## 6. MATLAB 运行

先检查配置：

```matlab
run(fullfile(pwd, 'tests', ...
    'test_stage_a_confirmation_search_config.m'))
```

测试通过后启动确认运行：

```matlab
addpath(fullfile(pwd, 'scripts'))
scenario = run_stage_a_confirmation_search();
```

运行结束后 MATLAB 会打印结果目录。

## 7. 当前边界

- 只运行一次固定种子的 10×20 搜索；
- 不执行 50×100 的正式实验；
- 不执行多随机种子统计；
- 不计算 `tD`、`SD` 和组合指标 `Y`；
- 不覆盖任何既有输出。
