# C-SEQ2 第 5 步：AGV 影响分析

## 目标

在 C-SEQ2 第 4 步机器侧局部右移候选基础上，识别哪些 AGV 运输任务因为机器
时间变化而失效或需要复核。

本步只分析 AGV 影响：

- 不修改 AGV 表；
- 不反馈机器开工时间；
- 不建立冻结问题；
- 不运行搜索。

## 分析内容

- 负载运输是否晚于目标工序开工；
- 负载运输是否早于前序工序完成；
- 最终卸载是否早于工件完成；
- 同一 AGV 后续任务是否需要复核；
- 历史维修累计不可用上下文是否保留。

## 代码入口

- `scripts/run_stage_cseq2_agv_impact_analysis.m`
- `tests/test_stage_cseq2_agv_impact_analysis.m`

## 测试命令

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_cseq2_agv_impact_analysis.m'))
```

## 完成标准

- AGV 影响集合与未影响集合数量守恒；
- 受影响运输无重复；
- 每个受影响运输都有原因和故障来源；
- AGV 表未修改；
- 不运行搜索。
