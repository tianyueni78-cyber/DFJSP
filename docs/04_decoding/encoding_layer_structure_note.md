# 编码层结构笔记：chrom 是怎么生成和变化的

## 1. 这份笔记解决什么问题

这份笔记只回答编码层问题：

```text
算法搜索的 chrom 到底长什么样？
它是怎么生成的？
交叉和变异时哪些部分会变？
每一段的取值范围由什么决定？
```

它不分析 `sorting.m`，不分析 `fitness.m`，也不解释完整实验流程。

## 2. 编码层在五层结构中的位置

当前系统核心分为五层：

```text
Data -> Encoding -> Decoding -> Evaluation -> Search
```

编码层位于数据层之后、解码层之前。

数据层提供：

```text
jobNum
operaVec
candidateMachine
AGVNum
AGVSpeed
```

编码层把这些信息变成算法可以搜索的染色体：

```text
chrom = [OS, MS, AS, SS]
```

## 3. 编码层主代码对应哪些文件

当前编码层主代码主要对应两个原始函数：

| 文件 | 作用 | 当前封装状态 |
|---|---|---|
| `raw_code/NSGA-II/init.m` | 生成初始 `chrom` 种群 | 仍使用原始函数，尚未封装到 `src/encoding/` |
| `raw_code/NSGA-II/variation.m` | 在搜索过程中对 `chrom` 做交叉和变异，生成新的 `chrom` | 仍由原始 `NSGA2.m` 内部调用，尚未封装 |

当前已经确认的编码层主结构是：

```text
chrom = [OS(n), MS(n), AS(n), SS(2n)]
总长度 = 5n
init.m 负责生成初始 chrom
variation.m 负责交叉/变异后生成新 chrom
```

这里的 `n` 是：

```text
n = operaNum = sum(operaVec)
```

所以当前编码层状态可以概括为：

```text
主代码结构已经拆清楚。
编码层函数还没有正式封装。
后续要把 split / validate / generate 入口放到 src/encoding/。
```

## 4. chrom 的真实结构

设：

```text
n = operaNum = sum(operaVec)
```

那么一条核心染色体长度是：

```text
5 * n
```

结构为：

| 段 | 位置 | 长度 | 含义 |
|---|---|---:|---|
| OS | `1 : n` | `n` | 工件顺序 |
| MS | `n+1 : 2n` | `n` | 候选机器选择 |
| AS | `2n+1 : 3n` | `n` | AGV 选择 |
| SS | `3n+1 : 5n` | `2n` | 速度档选择 |

所以：

```text
chrom = OS(n) + MS(n) + AS(n) + SS(2n)
```

## 5. 四段编码分别起什么作用

编码层的四段不是四条独立算法，而是同一条调度决策的四个侧面。

| 编码段 | 它决定什么 | 它保证什么 | 它不保证什么 |
|---|---|---|---|
| `OS` | 工件出现顺序，也就是“下一步优先调度哪个工件的下一道工序” | 每个工件出现次数等于该工件工序数 | 不直接给出每道工序的开始/结束时间 |
| `MS` | 每道工序在候选机器列表里选第几个机器 | 不会选出候选机器范围之外的索引 | 不保证机器时间不冲突 |
| `AS` | 每道工序由哪辆 AGV 搬运 | AGV 编号在 `1...AGVNum` 内 | 不保证 AGV 当前有空，也不保证运输时间可行 |
| `SS` | 每道工序对应两个速度档选择 | 速度档在 `1...length(AGVSpeed)` 内 | 不直接说明这两个速度分别用于哪个运输阶段 |

因此，编码层只保证“决策表达合法”。它不负责把方案排成真实时间轴。

真实调度约束，例如：

```text
前一道工序完成后，后一道工序才能开始
机器同一时间只能加工一个任务
AGV 需要先去取工件，再把工件送到目标机器
工件加工完成后才能被送往下一位置
AGV 电量不足时可能需要充电
```

这些不由编码层直接完成，而是交给后续解码层 `sorting.m` 处理。编码层给出“选择”，解码层负责判断这些选择如何落成可执行调度。

## 6. 编码层的整体流程

编码层相关流程可以先理解成：

```text
数据层提供结构信息
-> init.m 生成初始 chrom
-> NSGA2.m 把 chrom 送去评价
-> variation.m 在搜索过程中产生新的 chrom
-> 新 chrom 再被送去评价和筛选
```

其中数据层提供：

```text
jobNum
operaVec
candidateMachine
AGVNum
AGVSpeed
```

这些数据决定了编码的长度和边界：

```text
operaVec 决定 OS/MS/AS/SS 的长度
candidateMachine 决定 MS 的上界
AGVNum 决定 AS 的上界
AGVSpeed 决定 SS 的上界
```

## 7. init.m 做了什么

`init.m` 负责生成初始种群。

生成流程是：

```text
1. 根据 operaVec 生成 OS 的工件编号池
2. 打乱 OS，得到工序调度顺序
3. 为每道工序随机选择一个候选机器索引，得到 MS
4. 为每道工序随机选择 AGV，得到 AS
5. 为每道工序生成两个速度档选择，得到 SS
6. 拼成 chrom = [OS, MS, AS, SS]
```

其中：

```text
OS 来自工件编号的随机排列
MS 来自每道工序候选机器数量
AS 来自 AGVNum
SS 来自 speedNum
```

## 8. NSGA2.m 怎么使用 chrom

`NSGA2.m` 中确认：

```text
dim = 5 * operaNum
```

前 `dim` 列是真正编码。

算法运行时，会在后面追加：

```text
目标值
非支配排序信息
拥挤度等搜索辅助信息
```

但这些追加列不属于编码层核心结构。

真正送去评价时，仍然只取：

```text
chrom(:, 1:dim)
```

## 9. variation.m 怎么处理 chrom

`variation.m` 把染色体分成两大部分：

```text
OS = chrom(1:n)
RS = chrom(n+1:5n)
```

其中：

```text
RS = [MS, AS, SS]
```

也就是说：

```text
RS 长度 = 4n
MS 长度 = n
AS 长度 = n
SS 长度 = 2n
```

交叉时：

```text
OS 使用 IPOX 方式交叉
RS 使用 MPX 方式交叉
```

变异时：

```text
OS：交换两个位置
RS：随机选一些位置，按对应上界重新取值
```

这里可以理解为：

```text
OS 维护工序顺序这种“排列型结构”
RS 维护机器、AGV、速度这些“整数选择型结构”
```

所以 `variation.m` 不是随便改数字，而是在不同结构上用不同方式变化：

| 部分 | 为什么单独处理 | 变化方式 |
|---|---|---|
| `OS` | 必须保持每个工件出现次数不变 | 交叉时按工件集合交换；变异时交换两个位置 |
| `RS = [MS, AS, SS]` | 每个位置都有自己的整数上界 | 交叉时按位置混合；变异时按 `UP` 重新取值 |

## 10. MS / AS / SS 的上界

`variation.m` 构造了一个 `UP`，用于限制 RS 变异后的取值范围。

`UP` 的结构是：

```text
MS 上界：每道工序候选机器数量
AS 上界：AGVNum
SS 上界：length(AGVSpeed)
```

因此：

| 段 | 下界 | 上界 |
|---|---:|---|
| MS | 1 | `length(candidateMachine{job, operation})` |
| AS | 1 | `AGVNum` |
| SS | 1 | `length(AGVSpeed)` |

下界没有显式写成 `LOW`，因为代码用 `randperm(UP(k), 1)`，天然表示从 `1...UP(k)` 中取一个整数。

## 11. 编码层和解码层的边界

这一点很重要：编码层不是完整调度方案，它只是“调度决策表达”。

例如：

| 问题 | 编码层能回答吗 | 谁来真正处理 |
|---|---|---|
| 这道工序排在调度序列中的什么位置？ | 能，靠 `OS` | 编码层 |
| 这道工序选第几个候选机器？ | 能，靠 `MS` | 编码层 |
| 这道工序由哪辆 AGV 搬？ | 能，靠 `AS` | 编码层 |
| 这次运输用哪个速度档？ | 能，靠 `SS` | 编码层 |
| 这道工序什么时候开始加工？ | 不能 | 解码层 `sorting.m` |
| 机器是否有空闲时间可以插入？ | 不能 | 解码层 `sorting.m` |
| AGV 是否要先空载去取工件？ | 不能 | 解码层 `sorting.m` |
| 加工完之后能不能马上运输？ | 不能 | 解码层 `sorting.m` |
| 电量不够是否要充电？ | 不能 | 解码层 `sorting.m` |
| 最终 makespan 和 energy 是多少？ | 不能 | 评价层 `fitness.m` |

所以当前笔记只确认编码层结构。你提到的“做完一个工序后才能送去下一台机器”“AGV 送到一个机器之后才能继续送下一段”等，是更接近解码层的时间和资源约束，后续需要在解码层结构笔记中单独展开。

## 12. 当前仍未确认的点

`SS` 长度是 `2 * operaNum`。

从命名和长度看，它应该表示每道工序两个速度档选择。很可能对应空载运输速度和负载运输速度。

但具体两个速度分别用于哪个运输阶段，需要等解码层读取 `sorting.m` 时确认。

## 13. 编码层下一步封装依据

根据当前结构，后续编码层封装可以围绕三个能力展开：

```text
split_chromosome
validate_chromosome
generate_initial_population
```

其中：

```text
split_chromosome 负责拆出 OS / MS / AS / SS
validate_chromosome 负责检查长度和取值范围
generate_initial_population 负责统一生成初始种群
```

第一轮封装不应该改 `init.m`，而是先建立自己的入口，内部暂时调用原始 `init.m`。

## 14. 为什么先封装一条 chrom

当前已经新增的第一步封装是：

```text
src/encoding/split_chromosome.m
```

它只做一件事：

```text
把一条 chrom 向量按位置拆成 OS / MS / AS / SS。
```

这里的“只拆一条”不是说正式项目只处理一条染色体。正式搜索算法当然会处理一个种群，也就是很多条染色体。

之所以第一步先处理一条，是因为：

```text
一条 chrom 是编码层的最小单位。
种群 population 只是很多条 chrom 叠在一起。
```

所以封装顺序是：

```text
先把 1 条 chrom 的结构拆清楚
-> 再检查 1 条 chrom 是否合法
-> 再对种群里的每一条 chrom 重复这个检查
-> 最后接入初始种群生成和搜索脚本
```

换句话说：

```text
split_chromosome 处理 1 条 chrom。
后续测试或上层函数可以循环处理很多条 chrom。
```

这样做的原因是降低风险。如果一条染色体都拆不对，就不应该直接处理整个种群。

当前 `split_chromosome` 不做：

```text
不生成 chrom
不判断 chrom 是否完整合法
不调用 NSGA-II
不调用 sorting.m
不调用 fitness.m
不保存 outputs
```

这些会分给后续函数：

```text
validate_chromosome：判断 1 条 chrom 是否合法
generate_initial_population：生成多条 chrom，也就是初始种群
test_encoding_layer：用小样本检查编码层最小闭环
```

当前已经新增：

```text
src/encoding/split_chromosome.m
src/encoding/validate_chromosome.m
```

其中 `validate_chromosome.m` 只检查编码层合法性：

```text
chrom 长度是否至少包含 5n 个核心编码位
OS 中每个工件出现次数是否等于工序数
MS 是否在每道工序的候选机器范围内
AS 是否在 1...AGVNum 内
SS 是否在 1...length(AGVSpeed) 内
```

它不检查：

```text
机器时间是否冲突
AGV 时间是否冲突
工序能不能按时间执行
电量是否足够
makespan 和 energy 是多少
```

这些仍然属于后续解码层和评价层。
