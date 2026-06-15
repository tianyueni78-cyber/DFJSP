# 阶段 C 第 10.1 步：同时故障完全重调度解码器

## 本步目标

在第 9 步冻结问题上，解码一个来自原始染色体的未开工工序候选，并恢复
多个加工中断工序的固定两段加工承诺。本步不运行 NSGA-II，不生成正式实验
输出。

## 代码入口

- 解码器：
  [`decode_stage_c_simultaneous_complete_reschedule.m`](../src/rescheduling/decode_stage_c_simultaneous_complete_reschedule.m)
- 轻量运行入口：
  [`run_stage_c_simultaneous_complete_reschedule_decode.m`](../scripts/run_stage_c_simultaneous_complete_reschedule_decode.m)
- 契约测试：
  [`test_stage_c_simultaneous_complete_reschedule_decode.m`](../tests/test_stage_c_simultaneous_complete_reschedule_decode.m)

## 解码流程

1. 使用阶段 A 共享解码核心安排故障时刻后未开工的工序和 AGV 任务。
2. 对每个中断工序恢复原机器、原开始时间和修复后的完成时间。
3. 将一个逻辑工序展开为“故障前已加工段”和“修复后剩余加工段”。
4. 按真实加工时长重算机器能耗，维修等待时间不计入有效加工时间。
5. 重建机器时间表，并校验全部维修区间、机器互斥、工序顺序、AGV、
   最终卸载和能耗字段。

运行入口会加入 `src/rescheduling/` 和 `src/scheduling/`。后者提供共享的
AGV 空载运输时间函数 `spare_transfer_time_compute.m`。

## 数据来源

生产问题、正常染色体、机器候选、加工时间、AGV 和能耗参数均来自原项目
基线。轻量候选由原始染色体中故障时刻后未开工部分提取，不生成新的生产
数据。

## 当前边界

- 已实现：多个中断承诺和多个维修区间的单候选解码。
- 待实现：第 10.2 步受限种群、交叉与变异。
- 待实现：第 10.3 步候选评价和受限 NSGA-II 轻量搜索。
- 未运行：MATLAB 契约测试和任何正式搜索。
