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

## 3. chrom 的真实结构

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

## 4. init.m 做了什么

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

## 5. NSGA2.m 怎么使用 chrom

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

## 6. variation.m 怎么处理 chrom

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

## 7. MS / AS / SS 的上界

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

## 8. 当前仍未确认的点

`SS` 长度是 `2 * operaNum`。

从命名和长度看，它应该表示每道工序两个速度档选择。很可能对应空载运输速度和负载运输速度。

但具体两个速度分别用于哪个运输阶段，需要等解码层读取 `sorting.m` 时确认。

## 9. 编码层下一步封装依据

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
