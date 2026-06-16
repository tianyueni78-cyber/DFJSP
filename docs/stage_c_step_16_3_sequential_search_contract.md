# 阶段 C 第 16.3 步：连续故障算子与轻量搜索契约

## 本步目标

在第 16.1 步冻结问题和第 16.2 步解码器通过后，接入完全重调度搜索链：

1. 从当前计划视图提取未开工工序的基线种子决策；
2. 初始化受限种群；
3. 对 OS、MS、AS、SS 决策执行交叉和变异；
4. 使用 `6×2` 轻量 NSGA-II 契约验证候选评价、Pareto 去重和自适应终止；
5. 不运行正式长实验、不生成正式输出。

## 代码入口

- 算子入口：`scripts/run_stage_c_sequential_reschedule_operators.m`
- 轻量搜索入口：`scripts/run_stage_c_sequential_restricted_search_contract.m`
- 算子测试：`tests/test_stage_c_sequential_reschedule_operators.m`
- 搜索测试：`tests/test_stage_c_sequential_restricted_search_contract.m`

算子测试会直接调用解码器验证一个子代，因此测试自身需要加入 `src/scheduling`
路径，保证 AGV 空载运输时间函数可见。

## 复用关系

本步复用阶段 A 的受限种群初始化和交叉变异，复用阶段 C 同时故障搜索器。
由于第 16.2 步已经让 Stage C 解码器支持当前计划视图和单个中断承诺，因此
搜索器可以直接用于连续故障轻量契约。
