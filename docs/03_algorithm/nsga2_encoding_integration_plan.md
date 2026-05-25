# NSGA-II 接入新编码层方案

本文只规划正式 NSGA-II 如何接入新的编码层函数，不直接修改 `raw_code/NSGA-II/NSGA2.m`。

## 1. 当前已经完成的编码层入口

当前 `src/encoding/` 已经可以独立完成：

```text
generate_initial_population
validate_population
build_rs_upper_bounds
generate_offspring
```

也就是：

```text
读 sample 数据
-> 生成初始 population
-> 验证 population
-> 生成 offspring
-> 再次验证 offspring
```

## 2. NSGA2.m 当前和编码层有关的位置

基于 `raw_code/NSGA-II/NSGA2.m` 的静态阅读，当前主函数里和编码层相关的位置有两个。

第一处是初始种群：

```matlab
%chrom = init(pop, jobNum, operaVec, candidateMachine, AGVNum, speedNum);
```

这一行在当前 `NSGA2.m` 中已经被注释。也就是说，当前 `NSGA2.m` 的初始 `chrom` 是从外部传入的。

第二处是迭代中的交叉变异：

```matlab
offspring_ = variation(p_cross, p_mutation, parent_, jobNum, operaVec, AGVNum, AGVSpeed, candidateMachine);
```

这仍然直接调用原始 `variation.m`。

## 3. 建议接入顺序

第一步：不改 `NSGA2.m`，先让运行脚本在进入 `NSGA2.m` 前使用新函数生成初始种群。

```text
run_small_nsga2 / run_formal_nsga2
-> read_fjsp / read_agv_data
-> generate_initial_population
-> NSGA2(..., chrom, ...)
```

这个部分已经和当前 `NSGA2.m` 的接口兼容，因为 `NSGA2.m` 本来就接收外部传入的 `chrom`。

第二步：暂时不要直接改 `raw_code/NSGA-II/NSGA2.m`，而是新增一个包装版搜索入口，例如：

```text
src/search/run_nsga2_with_encoding.m
```

包装入口内部可以先继续调用原始 `NSGA2.m`，但把初始 population 生成逻辑固定为 `generate_initial_population`。

第三步：如果要替换 `variation.m`，建议不要直接改原始 `NSGA2.m`，而是复制/封装一个新搜索函数，例如：

```text
src/search/nsga2_encoding_step.m
```

或者后续形成：

```text
src/search/run_nsga2_refactored.m
```

在新函数里把：

```matlab
variation(...)
```

替换成：

```matlab
generate_offspring(parent_, problem, agvData, options)
```

## 4. 为什么不能马上直接替换 variation.m

`NSGA2.m` 里的 `parent_` 不一定只包含核心 `5n` 编码列。经过评价和非支配排序后，`chrom` 后面会追加：

```text
目标值
非支配排序等级
拥挤度
```

新的 `generate_offspring` 当前只处理前 `5n` 个核心编码列，这一点和原始 `variation.m` 一致。但正式接入时要确认：

```text
parent_ 输入是否可能带有额外列
offspring_ 输出是否只需要核心编码列
评价后目标值是否仍由 fitness 追加
non_domination / replace_chrom 的列布局是否保持不变
```

这些属于搜索层接入风险，不应该在编码层封装阶段直接改。

## 5. 建议的正式接入验收标准

正式接入前，应先满足：

```text
scripts/run_encoding_smoke.m 能跑通
tests/test_encoding_layer.m 能跑通
generate_initial_population 不依赖 raw_code/init.m
generate_offspring 不调用 sorting.m / fitness.m / NSGA2.m
offspring 全部通过 validate_population
```

正式接入时，再单独验证：

```text
small NSGA-II 仍能跑通
输出 Pareto 结构不变
目标值列位置不变
non_domination / replace_chrom 不受影响
```

## 6. 当前结论

当前阶段可以先完成：

```text
编码层 demo 入口：scripts/run_encoding_smoke.m
正式 NSGA-II 接入方案：本文档
```

是否修改 `NSGA2.m`，应等搜索层接入任务单独确认后再做。
