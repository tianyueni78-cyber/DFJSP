# C-SEQ2 第 3 步：传播新故障影响并保留历史维修约束

## 目标

在 C-SEQ2 第 2 步的累计不可用上下文基础上，传播后一故障对未开工工序的影响，
同时保留历史维修区间约束。

本步仍然不修改调度表：

- 不写入机器时间；
- 不调整 AGV；
- 不建立冻结问题；
- 不运行搜索。

## 处理逻辑

1. 使用当前计划视图和下一故障事件识别受影响工序；
2. 保留第 2 步中的累计不可用区间；
3. 记录历史维修仍处于激活状态；
4. 将受影响工序与未受影响未开工工序分开；
5. 保证所有影响来源 `event_id` 属于累计故障集合。

## 代码入口

- `src/impact/build_stage_cseq2_impact_context.m`
- `scripts/run_stage_cseq2_impact_context.m`
- `tests/test_stage_cseq2_impact_context.m`

## 测试命令

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_cseq2_impact_context.m'))
```

## 完成标准

- 新故障影响集合非空；
- 历史维修区间仍保留在累计不可用上下文中；
- 受影响工序无重复；
- 受影响与未受影响未开工工序数量守恒；
- 不修改计划、不运行搜索。
