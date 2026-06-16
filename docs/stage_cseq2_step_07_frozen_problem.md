# C-SEQ2 第 7 步：完全重调度冻结问题

## 目标

建立 C-SEQ2 完全重调度的冻结边界，为后续解码和搜索做准备。

本步只定义边界：

- 冻结已完成工序；
- 冻结正常在制工序；
- 固定新故障中断工序的两段加工承诺；
- 释放故障时刻尚未开工的工序；
- 保留历史维修累计不可用上下文；
- 不运行搜索。

## 重要边界

当前复用 Stage C 冻结核心处理“新故障”这一轮，因此 `repair_intervals` 中只包含
新故障维修区间；历史维修区间保存在 `cumulative_unavailability` 中，供后续完整
审计使用。

## 代码入口

- `scripts/run_stage_cseq2_frozen_problem.m`
- `tests/test_stage_cseq2_frozen_problem.m`

## 测试命令

```matlab
run(fullfile(pwd,'tests','test_stage_cseq2_frozen_problem.m'))
```

## 完成标准

- 冻结工序 + 可重调工序数量等于总工序数；
- 可重调工序数量等于故障时刻未开工工序数；
- 中断工序保留进度并在维修后继续加工；
- AGV 运输划分数量守恒；
- 历史维修累计不可用上下文被保留；
- 不运行搜索。
