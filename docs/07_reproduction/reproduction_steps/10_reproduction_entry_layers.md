# 第 10 步：运行入口分层整理

## 1. 这一步解决什么

现在项目已经有很多入口：

```text
tests/
scripts/run_single_evaluation.m
scripts/run_small_nsga2.m
scripts/run_medium_nsga2.m
scripts/run_formal_nsga2.m
configs/small_nsga2_config.m
configs/medium_nsga2_config.m
configs/formal_nsga2_config.m
outputs/
```

第 10 步不新增代码，也不运行 MATLAB。

它只做一件事：

```text
把这些入口分层，告诉你以后复现时应该先看哪里、跑哪个。
```

## 2. 复现入口分成三层

### 第一层：检查入口

作用：

```text
判断环境、数据、配置有没有坏。
```

这些不是正式实验，而是体检。

| 场景 | 运行 |
|---|---|
| 检查 `.fjs` | `run('tests/test_read_fjsp.m')` |
| 检查机器 Excel | `run('tests/test_read_machine_data.m')` |
| 检查 AGV Excel | `run('tests/test_read_agv_data.m')` |
| 检查配置入口 | `run('tests/test_small_nsga2_config.m')` |
| 检查单条染色体评价 | `run('tests/test_evaluate_chromosome.m')` |
| 检查小种群搜索闭环 | `run('tests/test_small_nsga2.m')` |

建议在这些情况先跑检查入口：

```text
刚拉仓库
刚换电脑
刚换数据
刚改配置
脚本突然报错
```

### 第二层：运行入口

作用：

```text
真正跑一次当前已经封装好的小规模流程。
```

| 档位 | 入口 | 参数 | 用途 |
|---|---|---|---|
| single | `run('scripts/run_single_evaluation.m')` | 1 条染色体 | 看单条方案能否评价 |
| small | `run('scripts/run_small_nsga2.m')` | `pop=10, max_gen=2` | 快速确认搜索流程没坏 |
| medium | `run('scripts/run_medium_nsga2.m')` | `pop=20, max_gen=5` | 轻微放大检查 |
| formal | `run('scripts/run_formal_nsga2.m')` | `pop=30, max_gen=10` | formal NSGA-II 第一版运行骨架 |

这些输出会进入：

```text
outputs/single_evaluation/时间戳/
outputs/small_nsga2/时间戳/
outputs/medium_nsga2/时间戳/
outputs/formal_nsga2/时间戳/
```

### 第三层：指标和后续正式实验扩展入口

作用：

```text
以后读取 formal 结果，计算指标，再扩展到对比实验、消融实验和图表。
```

当前已经完成指标入口设计，但还没有实现代码。

当前缺口：

```text
scripts/run_metrics.m
完整算法对比
完整消融实验
HV / IGD / Spacing / C-metric
Pareto 图
甘特图
能耗图
```

现在不急着做这一层。

原因是：

```text
先把 small / medium 跑稳，
再整理正式实验入口，
不然一上来跑大实验，报错时很难知道问题在哪。
```

## 3. 我以后到底该跑哪个

不用每次都从头跑所有东西。

按你的场景选入口：

| 你现在想做什么 | 建议入口 |
|---|---|
| 第一次拉仓库，想确认能不能用 | 先跑读取测试 + 配置测试 |
| 刚换 `.fjs` 或 Excel | 先跑读取测试，再跑配置测试 |
| 刚改 `pop/max_gen/seed` | 先跑配置测试 |
| 想确认算法链路没坏 | 跑 `scripts/run_small_nsga2.m` |
| 想比 small 稍微大一点 | 跑 `scripts/run_medium_nsga2.m` |
| 想看 1 条方案怎么被评价 | 跑 `scripts/run_single_evaluation.m` |
| 想跑 formal 第一版 | 跑 `scripts/run_formal_nsga2.m` |
| 想计算指标 | 当前只完成设计，后续实现 `scripts/run_metrics.m` |

## 4. 最推荐的默认顺序

如果你隔了一段时间回来，不知道从哪开始，按这个顺序：

```matlab
cd D:\CODEX\code_refactor_project

run('tests/test_small_nsga2_config.m')
run('scripts/run_small_nsga2.m')
```

如果这两步都正常，说明：

```text
配置能读
小规模搜索能跑
outputs 能写
```

然后你再决定要不要跑：

```matlab
run('scripts/run_medium_nsga2.m')
run('scripts/run_formal_nsga2.m')
```

## 5. 当前已经跑通到哪里

当前已经跑通：

```text
single evaluation
small NSGA-II:  pop=10, max_gen=2
medium NSGA-II: pop=20, max_gen=5
formal NSGA-II: pop=30, max_gen=10
```

其中 formal 档位已经跑通，最近一次记录为：

```text
outputs/formal_nsga2/20260520_224558
```

当前还没有整理：

```text
完整评价指标
完整论文对比实验
完整图表输出
```

## 6. 一句话记忆

```text
tests 是体检，
configs 是参数说明书，
scripts 是运行按钮，
outputs 是结果抽屉，
docs 是回头找路的地图。
```
