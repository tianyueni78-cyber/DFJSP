# 阶段 A 第 8.2a 步：完全重调度冻结解码器

## 1. 目标

在第 8.1 步冻结边界上，解码一组仅针对未开工工序的调度决策，生成完整机器工序记录和故障后的 AGV 运输记录。

本步只实现解码，不运行种群搜索。

## 2. 决策内容

解码器接收：

- 未开工工序的作业序列；
- 每道未开工工序的候选机器编号索引；
- AGV 分配；
- 空载速度挡位；
- 负载速度挡位。

含义与原项目 `OS + MS + AS + SS` 编码一致，但编码长度仅覆盖未开工工序。

## 3. 动态解码

每次从作业序列读取该工件下一道未开工工序，然后：

1. 读取候选机器和原数据加工时间；
2. 读取 AGV 及空载、负载速度；
3. 从第 8.1 步的 AGV 位置安排空载移动；
4. 等待工件可搬运后执行负载运输；
5. 等待目标机器、工件和运输全部就绪；
6. 安排工序并更新工件、机器和 AGV 状态。

故障机器最早可用时刻已由第 8.1 步限制为维修结束时刻。

## 4. 基线种子

轻量测试使用原正常计划染色体中属于未开工工序的决策作为输入种子：

```text
baseline.chrom -> 未开工 OS/MS/AS/SS
```

它不是人工生成数据，也不是优化结果，只用于验证动态解码契约。

## 5. 新增文件

- `src/rescheduling/decode_stage_a_complete_reschedule.m`
- `src/rescheduling/build_stage_a_baseline_seed_decision.m`
- `scripts/run_stage_a_complete_reschedule_decode.m`
- `tests/test_stage_a_complete_reschedule_decode.m`
- `docs/stage_a_step_08_2a_complete_decoder.md`

## 6. 验证范围

- 冻结工序不变；
- 每道未开工工序恰好解码一次；
- 新机器属于原候选机器集合；
- 加工时间来自原 `jobInfo`；
- 机器不冲突；
- 工件工艺顺序正确；
- AGV 运输不冲突；
- 运输到达不晚于加工开始。

## 7. 当前未处理

- NSGA-II 种群初始化、交叉和变异；
- 充电与能量可行性重建；
- 最后一道工序到卸载站的运输；
- `tD`、`SD` 和 `Y`；
- 局部右移与完全重调度选择。

以上内容将在解码契约通过后继续分步实现。

## 8. MATLAB 测试

```matlab
run(fullfile(pwd, 'tests', ...
    'test_stage_a_complete_reschedule_decode.m'))
```

预期输出：

```text
test_stage_a_complete_reschedule_decode passed
```
