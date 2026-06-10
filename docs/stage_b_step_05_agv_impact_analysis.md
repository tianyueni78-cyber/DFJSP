# 阶段 B 第 5 步：AGV 运输影响分析

## 本步目标

读取第 4 步机器局部右移候选和原 AGV 时间表，识别因加工中故障及机器时间
变化而需要调整的运输任务。

本步只分析，不修改 AGV 时间、路线、分配、充电或能耗记录。

## 检查的直接约束

对每个负载运输检查：

1. 是否在前一道工序新完成时间之前出发；
2. 是否在目标工序新开始时间之后才到达；
3. 最终卸载是否在工件最后工序新完成时间之前开始。

加工中断工序的新完成时间采用“修复后续加工完成时间”，因此其后继运输
不能继续使用故障前的原出发时刻。

## 同一 AGV 顺序传播

一个运输任务直接失效后：

- 与它配对的空载、负载运输需要共同复核；
- 同一 AGV 在该任务之后的运输也需要复核；
- 这些任务标记为 `agv_sequence_review`，但本步不重新排程。

## 输出分类

- `directly_affected_transports`：直接违反运输与加工衔接约束；
- `affected_transports`：直接违反项及同一 AGV 后续复核项；
- `unaffected_transports`：当前仍满足约束的运输；
- `requires_agv_adjustment`：下一步是否需要正式调整 AGV。

## 代码入口

- 分析函数：
  [`analyze_stage_b_agv_impact.m`](../src/impact/analyze_stage_b_agv_impact.m)
- 运行入口：
  [`run_stage_b_agv_impact_analysis.m`](../scripts/run_stage_b_agv_impact_analysis.m)
- 轻量测试：
  [`test_stage_b_agv_impact_analysis.m`](../tests/test_stage_b_agv_impact_analysis.m)

## MATLAB 轻量测试

```matlab
cd('项目根目录')
run(fullfile(pwd,'tests','test_stage_b_agv_impact_analysis.m'))
```

测试使用原项目数据和第 4 步候选，不生成替代问题数据。
