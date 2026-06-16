# 阶段 C 第 16.1 步：连续故障完全重调度冻结问题

## 本步目标

在第 15 步连续故障局部右移与 AGV 联动通过后，先建立完全重调度的边界：

1. 冻结下一故障时刻前已完成、正常在制和故障在制工序；
2. 保存“保留进度、修复后续加工”的中断承诺；
3. 释放下一故障时刻未开工工序；
4. 划分已完成、在制和未开始 AGV 运输；
5. 建立工件、机器和 AGV 的释放边界。

## 代码入口

- 运行入口：`scripts/run_stage_c_sequential_frozen_problem.m`
- 测试：`tests/test_stage_c_sequential_frozen_problem.m`
- 复用构件：`src/rescheduling/build_stage_c_simultaneous_frozen_problem.m`

## 当前边界

本步只建立冻结问题，不解码完全重调度候选、不运行 NSGA-II 搜索、不执行
组合选择。
