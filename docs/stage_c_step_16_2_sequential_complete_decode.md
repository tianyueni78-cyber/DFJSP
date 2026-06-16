# 阶段 C 第 16.2 步：连续故障完全重调度解码器

## 本步目标

在第 16.1 步冻结问题基础上，解码一个完全重调度候选：

1. 使用当前计划视图和冻结问题生成一个基线种子决策；
2. 复用阶段 A 完全重调度核心安排未开工工序与 AGV；
3. 恢复连续故障中断工序的两段加工承诺；
4. 重建机器表并重新计算机器能耗；
5. 验证冻结工序、中断承诺、维修区间、工件顺序和能耗闭合。

阶段 A 核心解码器内部要求 `isFaultFreeBaseline=true`。第 16.2 步不会修改
当前计划数据，而是在 Stage C 适配器内部构造一个临时兼容视图，让核心解码器
继续使用当前计划的机器表、AGV 表和冻结边界。

## 代码入口

- 运行入口：`scripts/run_stage_c_sequential_complete_reschedule_decode.m`
- 测试：`tests/test_stage_c_sequential_complete_reschedule_decode.m`
- 复用构件：`src/rescheduling/decode_stage_c_simultaneous_complete_reschedule.m`

## 当前边界

本步只解码一个轻量候选，不初始化种群、不运行 NSGA-II 搜索、不执行组合
选择。
