# 知识地图工作表

## 当前总目标

用这篇 FJSP-AGV 论文代码作为样本，建立一套自己能看懂、后期能复用、以后能迁移到相近智能调度项目的运行骨架和知识地图。

这不是为了展示，也不是为了堆文档。每个模块都要服务三个问题：

1. 我能不能看懂这套代码在干什么？
2. 我以后能不能复用这套结构来放数据、改参数、跑小实验和排查问题？
3. 我换一篇智能调度论文时，能不能复用这套理解方法？

## 使用方式

这个文件是**总进度台账**，不是临时任务单。

以后回头看它时，重点看三件事：

1. 哪些认知模块已经有第一版。
2. 每个模块对应哪些文档。
3. 哪些内容属于后续按需要深化，而不是当前必须继续扩写。

## 第一轮模块完成台账

| 编号 | 模块 | 主要回答 | 当前状态 | 对应文档 | 后续可选深化 |
|---|---|---|---|---|---|
| 1 | 项目总览 | 这套代码整体在干什么？我该怎么读？ | 第一版完成 | `beginner_reading_guide.md`、`system_layer_architecture.md` | 按你的真实困惑改得更顺口 |
| 2 | 数据来源 | `.fjs`、Excel、距离、能耗参数从哪来？ | 第一版完成 | `data_layer_map.md` | 补字段级说明：变量长什么样 |
| 3 | 染色体编码 | `OS / MS / AS / SS` 分别表达什么决策？ | 应用理解总览已补 | `search_layer_overview.md`、`decoding_layer_overview.md`、`encoding_decoding_application_overview.md` | 后续可补一个最小染色体例子 |
| 4 | 解码过程 | `sorting.m` 怎么把染色体变成真实调度？ | 应用理解总览已补，代码主流程第一版完成 | `decoding_layer_overview.md`、`encoding_decoding_application_overview.md` | 补 `curJob`、`jobOpera`、时间轴变量流向 |
| 5 | 评价机制 | `fitness.m` 怎么计算完工时间和能耗？ | 第一版完成 | `evaluation_layer_overview.md` | 补机器能耗、AGV 能耗的数字例子 |
| 6 | 搜索基础 | 算法怎么生成、评价、筛选新方案？ | 第一版完成 | `search_layer_overview.md` | 后续再单独分析 VNS、Q-learning、反向学习 |
| 7 | 实验流程 | `dif_main.m`、`same_main.m` 到底跑了什么实验？ | 第一版完成 | `experiment_flow.md` | 补 HV、IGD、Spacing、C-metric 的函数细节 |
| 8 | 复现与封装路线 | 后期怎么分块、处理数据、封装才不容易报错？ | 第一版完成 | `data_reproduction_risks.md`、`refactor_roadmap.md` | 进入代码封装时继续细化成任务清单 |

## 第一轮完成情况

当前第一轮目标已经基本完成：8 个基础模块都有第一版或可用入口。

现在这套知识地图已经能回答：

- 这个项目研究什么调度问题？
- 数据从哪里来，进入哪些变量？
- 一个调度方案为什么能表示成染色体？
- `sorting.m` 为什么是核心解码器？
- `fitness.m` 为什么决定方案好坏？
- 算法为什么是在搜索染色体，而不是直接操作工厂？
- 一键运行脚本到底做了哪些实验，输出了哪些图和指标？
- 以后要封装和复现，最容易出错的点在哪里？

## 五层结构当前进度表

这张表回答一个更直接的问题：

```text
五层结构现在分别走到哪了？
```

| 五层 | 当前进度 | 已有成果 | 还没有做什么 | 下一步方向 |
|---|---|---|---|---|
| Data Layer 数据层 | 已经比较扎实 | `.fjs`、机器 Excel、AGV Excel 已拆出读取函数；已有轻量测试；small/medium/formal 都通过配置读取数据 | 还没有做字段级数据字典；新数据集批量管理还没做 | 后续换数据时再补字段说明和数据集管理规则 |
| Encoding Layer 编码层 | 已进入应用理解线 | `OS / MS / AS / SS` 的含义已说明；已新增编码-解码应用总览；当前仍使用原始 `init.m` 生成染色体 | 还没有单独封装染色体生成/合法性检查；还没有染色体小例子 | 后续可补“1 条 chrom 长什么样”的小例子 |
| Decoding Layer 解码层 | 已进入应用理解线，保持原算法 | `sorting.m` 已明确为核心解码器；已说明它如何处理工序顺序、机器、AGV、速度、电量和插空 | 没有重构 `sorting.m`；没有拆机器/AGV 时间轴子函数 | 后续按需要补变量流向图 |
| Evaluation Layer 评价层 | 基础目标值已跑通，指标入口最小读取版已跑通 | `evaluate_chromosome.m` 已封装单条评价；formal 能输出 makespan 和 totalEnergy；`run_metrics.m` 已读取 formal 结果并生成最小摘要 | `HV / IGD / Spacing / C-metric` 还没有完整实现 | 后续可按需要扩展完整指标 |
| Search Layer 搜索层 | NSGA-II 单算法骨架已跑通 | small、medium、formal 三个 NSGA-II 档位已跑通；formal 已输出到 `outputs/formal_nsga2/` | 多算法对比、消融实验、高级改进算法还没有进入 | 等指标入口稳定后，再考虑多算法对比 |

当前最关键的结论：

```text
数据层和 NSGA-II 搜索骨架已经能跑。
解码层和评价层仍依赖原始 sorting/fitness，暂时不重构。
工程化第一阶段已经闭环，当前主线转入“编码-解码应用理解”。
```

第 18 步已经新增编码-解码应用理解总览：

```text
docs/04_decoding/encoding_decoding_application_overview.md
```

它不讲逐行代码，而是回答：以后看新智能调度课题时，如何从调度对象、决策变量、编码、解码、评价、搜索这条链路理解问题。

## 第二轮深化池

第二轮不是固定顺序，而是根据你之后真正卡住的地方回头细化。

| 卡点 | 回头细化方向 |
|---|---|
| 看不懂 `OS / MS / AS / SS` | 补染色体小例子 |
| 看不懂 `sorting.m` | 补 `curJob`、`jobOpera`、`machineTable`、`AGVTable` 变量流向 |
| 看不懂 `fitness.m` | 补机器能耗、AGV 能耗、空闲能耗计算例子 |
| 不知道一键运行发生什么 | 补 `dif_main.m` 执行顺序 |
| 想开始封装代码 | 补最小稳定链路：数据读取 -> 单个染色体评价 |
| 想理解算法改进 | 分别分析 VNS、Q-learning、反向学习，不混在基础搜索里 |

## 后续更新规则

后续不是每做一步都重写这个文件，而是只在两种情况下更新：

1. 新增了一个重要知识模块。
2. 某个模块从“第一版”变成“已经可用于复现/封装”。

这样它保持为长期工作台账，而不是临时流水账。

## 当前工程进度台账

这个表记录“能跑到哪一步”，不是知识文档数量。

| 阶段 | 目标 | 当前状态 | 对应文件 |
|---|---|---|---|
| 数据读取 | 文件能稳定读进 MATLAB | 已拆解、已封装、已有测试 | `src/data/read_fjsp.m`、`src/data/read_machine_data.m`、`src/data/read_agv_data.m`、`tests/test_read_*.m` |
| 单条染色体评价 | 1 条 `chrom` 能被 `fitness/sorting` 评价 | 已拆解、已封装、已补正式测试 | `src/evaluation/evaluate_chromosome.m`、`tests/test_evaluate_chromosome.m` |
| 当前串联入口 | 把数据读取、生成 chrom、评价、输出串起来 | 已有脚本，已由你手动跑通 | `scripts/run_single_evaluation.m` |
| 小种群短迭代 | 小规模 NSGA-II 闭环运行 | 已由你本地跑通，正式测试也已跑通 | `scripts/run_small_nsga2.m`、`tests/test_small_nsga2.m` |
| 配置化运行入口 | 换数据/改参数时优先改配置而不是改脚本 | 已新增配置入口，已由你本地跑通 | `configs/small_nsga2_config.m`、`scripts/run_small_nsga2.m` |
| 数据与配置扩展准备 | 扩大规模前先明确换数据、改参数、检查输出的流程 | 已建立说明，步骤检查已由你本地跑通 | `docs/07_reproduction/reproduction_steps/07_data_config_extension.md` |
| 配置入口测试 | 在运行算法前检查配置文件、路径和参数是否合理 | 已由你本地跑通 | `tests/test_small_nsga2_config.m`、`docs/07_reproduction/reproduction_steps/08_config_entry_test.md` |
| 小幅放大参数运行 | 用 medium 档位检查配置化骨架能否轻微放大 | 已由你本地跑通 | `configs/medium_nsga2_config.m`、`scripts/run_medium_nsga2.m`、`docs/07_reproduction/reproduction_steps/09_medium_nsga2_run.md` |
| 运行入口分层整理 | 把 test / small / medium / 未来正式实验入口分清楚 | 已建立复现总入口说明 | `docs/07_reproduction/reproduction_steps/10_reproduction_entry_layers.md` |
| 阶段总结与下一阶段路线 | 总结 small/medium 骨架完成度，并选择后续主线 | 已完成，后续选择路线 A | `docs/07_reproduction/reproduction_steps/11_stage_summary_next_routes.md` |
| outputs 输出结构整理 | 明确 single / small / medium 输出目录和保存内容 | 已建立输出规则 | `docs/07_reproduction/reproduction_steps/12_outputs_structure.md` |
| 运行日志与参数记录 | 明确每次运行要记录哪些参数、结果和输出目录 | 已建立记录规则 | `docs/07_reproduction/reproduction_steps/13_run_log_and_parameter_record.md` |
| formal 入口设计 | 明确 small / medium / formal / metrics 的入口关系 | 已完成设计，formal 入口已落地 | `docs/07_reproduction/reproduction_steps/14_formal_experiment_entry_design.md` |
| formal 配置 | 建立正式运行配置字段和配置文件 | 已新增配置，配置测试已跑通 | `configs/formal_nsga2_config.m`、`tests/test_formal_nsga2_config.m` |
| formal 运行 | 跑通 NSGA-II formal 第一版 | 已由你在 MATLAB 中跑通 | `scripts/run_formal_nsga2.m` |
| 指标入口最小读取版 | 读取 formal 结果，生成最小指标摘要 | 已新增脚本，等待你在 MATLAB 中运行 | `scripts/run_metrics.m`、`docs/07_reproduction/reproduction_steps/17_metrics_entry_design.md` |
| 完整论文实验 | 对比/消融/指标/图表 | 远期可选，不是当前主线 | 后续按需要整理 |

第一轮最小复现链路已经跑通。

这里的“第一轮”不是完整论文实验，而是指：

```text
数据读取
-> 单条染色体评价
-> 单条评价脚本
-> 小种群 NSGA-II 2 代短迭代
-> 配置化 small_nsga2
-> 输出到 outputs
```

这说明当前仓库已经具备一个小型、可控、可复用的运行骨架。

还没有进入的部分是：

```text
完整论文实验
完整评价指标
批量对比实验
消融实验
完整图表生成
HV / IGD / Spacing / C-metric 等指标汇总
```

这些属于后续扩展，不是第一轮最小复现链路的一部分。

第 5 步本地跑通记录：

```text
RUNNING --------> NSGA-II <-------- RUNNING
工件数：10 机器数 6 AGV数 3
GEN: 1  MIN Cmax: 155.9  MIN Energy:1890.05
GEN: 2  MIN Cmax: 155.9  MIN Energy:1890.05
运行时间：0.36357
small NSGA-II finished.
pop: 10, max_gen: 2
paretoSolutionCount: 3
bestMakespan: 155.886667
bestTotalEnergy: 1890.048000
outputDir: D:\CODEX\code_refactor_project\outputs\small_nsga2\20260519_222017
```

正式测试已由你本地跑通：

```text
RUNNING --------> NSGA-II <-------- RUNNING
工件数：10 机器数 6 AGV数 3
GEN: 1  MIN Cmax: 155.9  MIN Energy:1890.05
GEN: 2  MIN Cmax: 155.9  MIN Energy:1890.05
运行时间：0.55764
test_small_nsga2 passed: paretoSolutionCount=3, bestMakespan=155.886667, bestTotalEnergy=1890.048000
```

第 5 步已经形成：

```text
拆解 -> 串联脚本 -> 手动运行 -> 正式测试
```

当时进入：

```text
第 6 步：配置化 small_nsga2。
```

这一步的目标不是完整论文实验，而是形成可复用运行骨架：

```text
configs 决定数据和参数
scripts 按配置运行
outputs 保存结果
```

第 6 步本地跑通记录：

```text
RUNNING --------> NSGA-II <-------- RUNNING
工件数：10 机器数 6 AGV数 3
GEN: 1  MIN Cmax: 155.9  MIN Energy:1890.05
GEN: 2  MIN Cmax: 155.9  MIN Energy:1890.05
运行时间：0.27769
small NSGA-II finished.
pop: 10, max_gen: 2
paretoSolutionCount: 3
bestMakespan: 155.886667
bestTotalEnergy: 1890.048000
outputDir: D:\CODEX\code_refactor_project\outputs\small_nsga2\20260520_112624
```

这说明当前最远进度已经变成：

```text
数据 -> 配置入口 -> 小种群 NSGA-II 2 代短迭代 -> Pareto 解集摘要 -> outputs
```

## 下一阶段建议

下一阶段不建议立刻进入完整论文实验，也不建议现在就生成图片。

更合理的顺序是：

```text
扩大规模前，先整理数据和配置
```

也就是先回答：

```text
换一个 .fjs 怎么放？
换一套机器/AGV Excel 怎么放？
pop / max_gen / seed / 能耗参数应该在哪里改？
outputs 里每次结果怎么区分？
哪些参数放大以后最容易报错？
```

因此下一阶段建议命名为：

```text
第 7 步：数据与配置扩展准备
```

它的目标不是跑大实验，而是让后面扩大规模时不乱：

```text
先让“换数据、改参数、小规模验证”变成稳定流程
再考虑完整评价指标和图表
```

小规模阶段暂时不必生成图片。现在更重要的是确认：

```text
能读数据
能生成染色体
能调用原始算法
能输出目标值
能把结果放进 outputs
能通过配置复用
```

第 7 步已经建立为复现说明页：

```text
docs/07_reproduction/reproduction_steps/07_data_config_extension.md
```

它目前不新增代码，先把以后扩大规模前的检查顺序固定下来。

第 7 步建议的检查流程已经由你在 MATLAB 中跑通：

```text
读取检查 -> 单条评价检查 -> 小种群检查 -> 配置化运行
```

配置化小种群脚本也已经重复运行通过，最近一次输出目录为：

```text
outputs/small_nsga2/20260520_115204
```

第 8 步配置入口测试已经由你在 MATLAB 中跑通：

```text
test_small_nsga2_config passed: pop=10, max_gen=2, seed=42
```

第 9 步已经建立 medium 档位：

```text
small:  pop=10, max_gen=2
medium: pop=20, max_gen=5
```

第 9 步要验证的是：

```text
配置改大一点以后，算法是否还能跑完并输出到 outputs/medium_nsga2/
```

第 9 步已经由你在 MATLAB 中跑通：

```text
pop = 20
max_gen = 5
paretoSolutionCount = 4
bestMakespan = 135.743333
bestTotalEnergy = 1824.221333
outputDir = D:\CODEX\code_refactor_project\outputs\medium_nsga2\20260520_125615
```

medium 档位之后又重复运行通过，最近一次输出目录为：

```text
outputs/medium_nsga2/20260520_132626
```

第 10 步最初把入口分成三层：

```text
检查入口：tests/
运行入口：scripts/
未来正式实验入口：当时后续再整理
```

现在这部分已经继续推进：

```text
formal 配置：configs/formal_nsga2_config.m
formal 运行：scripts/run_formal_nsga2.m
metrics 设计：docs/07_reproduction/reproduction_steps/17_metrics_entry_design.md
```

第 11 步已经完成阶段总结：

```text
当前阶段：可复用小规模运行骨架已完成
后续选择：路线 A，继续工程化
当时下一步建议：整理 outputs 输出结构
```

第 12 步已经建立输出规则：

```text
single -> outputs/single_evaluation/时间戳/
small  -> outputs/small_nsga2/时间戳/
medium -> outputs/medium_nsga2/时间戳/
outputs/ 不提交 GitHub
```

第 13 步已经建立运行日志与参数记录规则：

```text
每次运行要能追溯：
用的哪个脚本
用的哪个 config
用的哪组数据
seed 和算法参数是多少
结果保存到哪个 outputDir
bestMakespan / bestTotalEnergy / paretoSolutionCount 是多少
```

对应文档：

```text
docs/07_reproduction/reproduction_steps/13_run_log_and_parameter_record.md
```

这一步仍然属于路线 A：继续工程化。它不是跑更大的实验，而是让已经跑通的 small / medium 骨架更适合以后复现和回看。

第 14 步已经整理正式实验入口设计：

```text
当前已实现：
single / small / medium / formal

已实现：
metrics 最小读取版
```

对应文档：

```text
docs/07_reproduction/reproduction_steps/14_formal_experiment_entry_design.md
```

这一步的核心作用是把“检查、运行、正式复现、指标计算”分开，后面实现代码时不要把所有事情重新塞进一个大脚本。

第 15 步已经整理正式实验配置设计：

```text
formal 配置建议包含：
experiment / paths / dataset / random / algorithm / energy / output
```

对应文档：

```text
docs/07_reproduction/reproduction_steps/15_formal_config_design.md
```

当前已经选择 B，并新增：

```text
configs/formal_nsga2_config.m
```

它目前是 formal 配置入口，已经由 `scripts/run_formal_nsga2.m` 读取。

formal 配置读取测试也已新增：

```text
tests/test_formal_nsga2_config.m
```

它只检查字段完整性，不运行 NSGA-II。

formal 运行脚本已新增：

```text
scripts/run_formal_nsga2.m
```

当前它只实现单算法 NSGA-II 的 formal 骨架，输出到：

```text
outputs/formal_nsga2/时间戳/
```

多算法对比、完整指标和图表生成仍未进入。

formal 第一版已经由你在 MATLAB 中手动跑通：

```text
script: scripts/run_formal_nsga2.m
config: configs/formal_nsga2_config.m
dataset: Mk01
seed: 42
pop: 30
max_gen: 10
paretoSolutionCount: 2
bestMakespan: 134.446667
bestTotalEnergy: 1770.988667
outputDir: outputs/formal_nsga2/20260520_224558
```

这说明当前工程已经从 small / medium 骨架推进到 formal NSGA-II 单算法入口。  
下一步不建议立刻堆更多大实验，而是先由你运行 `run_metrics.m`，确认 formal 输出结果能被读取并生成最小摘要。

第 17 步已经整理指标入口设计，并新增最小读取版：

```text
script: scripts/run_metrics.m
input: outputs/formal_nsga2/时间戳/formal_nsga2_result.mat
core data: NSGA2_Result.obj_matrix
output: outputs/formal_nsga2/时间戳/metrics/
```

对应文档：

```text
docs/07_reproduction/reproduction_steps/17_metrics_entry_design.md
```

这一步把搜索和指标计算分开：`run_formal_nsga2.m` 负责生成结果，`run_metrics.m` 负责读取结果并生成最小指标摘要。

`run_metrics.m` 已由你在 MATLAB 中手动跑通：

```text
script: scripts/run_metrics.m
sourceRunDir: outputs/formal_nsga2/20260520_224558
paretoSolutionCount: 2
bestMakespan: 134.446667
bestTotalEnergy: 1770.988667
metricsDir: outputs/formal_nsga2/20260520_224558/metrics
```

这说明第一阶段工程化闭环已经完成：

```text
配置 formal
-> 运行 formal NSGA-II
-> 保存 formal 结果
-> 读取 formal 结果
-> 生成最小 metrics 摘要
```

后续如果继续，不建议马上扩成完整论文实验。更合适的下一条主线是回到编码-解码应用理解：弄清楚一个调度问题如何从“对象和决策”变成“编码、解码、评价和搜索”。

## 2026-05-22 盘点版：五层完成度与缺口

本次盘点只回答“现在已经做到哪里、还差什么”，不制定下一步任务。

当前项目已经完成的是：**最小可复现工程闭环**。也就是说，项目已经能从配置读取数据，运行 formal NSGA-II，保存结果，再由 metrics 入口读取结果并生成最小摘要。

当前还没有完成的是：**核心编码、解码、评价指标和搜索实验的完整可复用封装**。

| 层次 | 已经做到什么 | 当前状态 | 还差什么 | 对长期目标的意义 |
|---|---|---|---|---|
| Data Layer 数据层 | `.fjs`、机器 Excel、AGV Excel 已拆成读取函数；已有测试；small / medium / formal 都能通过配置读取数据 | 基本拆完，可复用 | 字段级数据字典、新数据集批量管理规则还没补 | 以后换数据、换算例，这层已经可以作为模板 |
| Encoding Layer 编码层 | 已经讲清 `OS / MS / AS / SS` 分别代表什么；有编码-解码理解文档 | 理解完成，代码封装未完成 | 还没封装染色体生成、合法性检查、染色体小例子 | 论文编码逻辑已经能讲，但以后复用代码时还不够稳 |
| Decoding Layer 解码层 | 已确认 `sorting.m` 是核心解码器；已经说明它处理机器、AGV、速度、电量、插空等约束 | 理解完成，主代码未拆 | `sorting.m` 没拆；机器时间轴、AGV 时间轴、电量更新、插空逻辑还没分模块 | 论文逻辑能讲，但可复用解码器还没做出来 |
| Evaluation Layer 评价层 | 已有 `src/evaluation/evaluate_chromosome.m`，能包装原始 `fitness.m`，输出 makespan、energy、时间轴等 | 半封装完成 | `fitness.m` 本体还没拆；完整 HV / IGD / Spacing / C-metric 还没实现 | 单条染色体评价已经可复用，但完整论文指标还没齐 |
| Search Layer 搜索层 | small / medium / formal NSGA-II 已经跑通；配置、脚本、outputs、metrics 最小摘要已形成闭环 | NSGA-II 单算法骨架已跑通 | 多算法对比、消融实验、INSGA-II 改进点、批量运行入口还没封装 | 能跑一条 formal NSGA-II 线，但还不是完整论文实验平台 |

按两个长期目标拆开看：

| 目标 | 当前完成度判断 | 已经完成 | 还差什么 |
|---|---|---|---|
| 理解论文逻辑 | 已完成第一版，约 70% - 80% | 五层结构、数据流、编码含义、解码作用、评价机制、NSGA-II 搜索骨架都已有文档 | 一条染色体小例子；`sorting.m` 变量流向；`fitness.m` 能耗计算例子；INSGA-II 改进点说明 |
| 封装可复用代码 | 已完成一部分，约 40% - 50% | 数据读取封装；单染色体评价 wrapper；small / medium / formal 运行入口；metrics 最小读取入口 | 编码模块封装；解码模块封装；评价指标模块封装；搜索算法入口标准化；实验批量运行入口；图表与论文表格输出 |

最重要的缺口：

| 优先级 | 缺口 | 当前表现 | 为什么重要 |
|---|---|---|---|
| 1 | 编码层还没封装 | 当前 `init.m` 仍来自原始 NSGA-II 目录 | 还没有自己的“染色体生成 / 合法性检查”模块 |
| 2 | 解码层还没拆 | `sorting.m` 是核心解码器，但目前只是理解清楚 | 它决定编码如何变成真实机器和 AGV 调度，是论文逻辑核心 |
| 3 | 评价层只做了 wrapper | `evaluate_chromosome.m` 调用原始 `fitness.m` | makespan、机器能耗、AGV 能耗还没有拆成清楚子模块 |
| 4 | 完整指标没做 | `run_metrics.m` 目前只是最小摘要 | HV / IGD / Spacing / C-metric 才是完整论文实验常用指标 |
| 5 | 搜索层只有 NSGA-II 单线 | formal NSGA-II 能跑，但多算法对比和消融实验还没系统整理 | 还不能支撑完整论文实验对比 |
| 6 | 图表层还没有 | 还没有独立 Pareto 图、收敛图、甘特图、论文表格入口 | 写论文时还需要可复用的图表输出流程 |

一句话总结：

```text
当前已经有“能跑的工程骨架”和“论文逻辑地图”。
还没完成的是把核心编码、解码、评价、搜索真正拆成以后可迁移复用的模块。
```
