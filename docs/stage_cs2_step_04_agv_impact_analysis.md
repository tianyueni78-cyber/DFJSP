# C-S2 第 4 步：从头加工 AGV 影响分析

## 目标

在 C-S2 第 3 步机器局部右移候选的基础上，检查 AGV 运输是否仍满足
工件到达与机器开工之间的约束。

本步只识别失效运输和待复核运输，不修改 AGV 时间表，不运行搜索。

## 分析对象

对每条负载运输检查：

1. 运输到达时间是否晚于目标工序新的开工时间；
2. 运输出发时间是否早于前序工序新的完工时间；
3. 最终卸载是否早于工件最后工序新的完工时间；
4. 若某条运输直接失效，则同一 AGV 后续任务进入复核集合。

## C-S2 特有信息

本步保留从头加工规则信息：

- `interruption_rule = restart_from_zero`；
- `restart_from_zero = true`；
- `progress_preserved = false`；
- `lost_processing_time`；
- 损失加工段 `lost_processing_before_fault`；
- 完整重加工段 `restart_after_repair`。

## 代码入口

- AGV 影响分析：`src/impact/analyze_stage_cs2_agv_impact.m`
- 阶段入口：`scripts/run_stage_cs2_agv_impact_analysis.m`
- 契约测试：`tests/test_stage_cs2_agv_impact_analysis.m`

## 完成标准

- 原 AGV 表不被修改；
- 能区分直接约束违规和同 AGV 后续复核；
- 受影响运输不重复；
- 每条受影响运输保留故障来源事件；
- 从头加工规则和损失加工信息保留；
- 运输集合满足“受影响 + 未受影响 = 原全部运输”。

## 运行方式

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_cs2_agv_impact_analysis.m'))
```
