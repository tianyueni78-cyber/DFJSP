# 阶段 B-R 第 4 步：AGV 运输影响分析

## 目标

读取第 3 步机器候选和原 AGV 时间表，识别因完整重加工及后续机器时间变化
而失效或需要复核的运输任务。

本步只分析，不修改 AGV 时间、路线、分配、充电或能耗。

## 直接检查

对每个负载运输检查：

1. 是否在前一道工序新完成时间之前出发；
2. 是否在目标工序新开始时间之后才到达；
3. 最终卸载是否在工件最后工序新完成时间之前开始。

中断工序后的运输必须等待完整重加工完成，故障前损失加工不贡献工件完成
进度。

## 同一 AGV 后续复核

当一个运输任务直接违反约束时：

- 同一运输组的空载与负载活动共同复核；
- 同一 AGV 后续任务标记为顺序复核；
- 每个受影响任务保留直接违反或顺序传播原因。

## 实现方式

运输约束检查与阶段 B 相同，因此本步通过适配器复用已验证的
`analyze_stage_b_agv_impact` 核心。适配器仅转换机器候选接口，并在输出中
恢复以下 B-R 语义：

- `restart_from_zero = true`
- `progress_preserved = false`
- `lost_processing_time`
- 完整重加工时间和完成时刻

阶段 B 稳定代码不修改。

## 输出

- 发生时间变化的工序；
- 直接失效运输；
- 同一 AGV 后续待复核运输；
- 受影响和未受影响运输集合；
- `requires_agv_adjustment`；
- 损失加工与完整重加工根节点信息。

## 代码入口

- 分析函数：
  [`analyze_stage_br_agv_impact.m`](../src/impact/analyze_stage_br_agv_impact.m)
- 运行入口：
  [`run_stage_br_agv_impact_analysis.m`](../scripts/run_stage_br_agv_impact_analysis.m)
- 轻量测试：
  [`test_stage_br_agv_impact_analysis.m`](../tests/test_stage_br_agv_impact_analysis.m)

## 轻量测试

```matlab
run(fullfile(pwd,'tests','test_stage_br_agv_impact_analysis.m'))
```

## 下一步

测试通过后进入阶段 B-R 第 5 步：正式调整受影响 AGV 运输，并将运输延迟
反馈到机器工序。
