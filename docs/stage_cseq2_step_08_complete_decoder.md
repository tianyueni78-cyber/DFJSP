# C-SEQ2 第 8 步：完全重调度解码器

## 目标

在 C-SEQ2 第 7 步冻结问题基础上，解码一个基线种子完全重调度候选方案。

本步只验证解码链路：

- 复用当前计划视图作为基线；
- 复用 C-SEQ2 冻结边界；
- 调用阶段 C 多中断工序解码器；
- 保留历史维修累计不可用上下文；
- 审计新故障维修区间和累计维修区间；
- 不运行种群搜索。

## 代码入口

- `scripts/run_stage_cseq2_complete_reschedule_decode.m`
- `tests/test_stage_cseq2_complete_reschedule_decode.m`

## 测试命令

```matlab
run(fullfile(pwd,'tests','test_stage_cseq2_complete_reschedule_decode.m'))
```

## 完成标准

- 冻结工序在候选方案中保持不变；
- 中断工序按“保留进度、修复后续加工”形成两段加工；
- 机器段不重叠；
- 工件工序顺序满足；
- 新故障维修区间不被加工段占用；
- 历史累计维修区间也不被加工段占用；
- AGV 最终卸载、能耗和总能耗字段完整；
- 不运行搜索。
