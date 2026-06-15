# 阶段 B-R 第 1 步：从头加工恢复规则

## 目标

在与阶段 B 完全相同的正常基线和加工中故障事件上，只改变中断工序恢复
规则：

> 故障前已经完成的加工进度作废；机器修复后，中断工序在原机器重新加工
> 完整原加工时间。

本步不传播后续工序、不调整 AGV、不运行搜索。

## 保持不变

- 原问题数据；
- 正常调度基线；
- 中断工序 `J5-O1`；
- 故障机器 `M5`；
- 故障时刻 `4.5`；
- 维修区间 `[4.5,9.5)`；
- 禁止迁移到其他机器。

## 时间与能耗含义

故障前加工段已经实际占用机器并消耗能量，但不再贡献工序完成进度：

```text
有效完成加工时间 = 修复后的完整重加工时间
总机器加工时间 = 故障前损失加工时间 + 完整重加工时间
```

因此后续能耗比较必须保留损失加工能耗，不能把故障前加工段直接删除。

## 输出计划

`restart_plan` 包含：

- `lost_processing_segment`：故障前已加工但作废的加工段；
- `lost_processing_time`：损失加工时间；
- `repair_interval`：维修不可用区间；
- `restart_segment`：修复后完整重加工段；
- `effective_completion_processing_time`：完成工序所需的有效重加工时间；
- `total_machine_processing_time`：损失加工与完整重加工之和；
- 新完成时间和相对原计划的延迟。

## 代码入口

- 规则构建：
  [`build_stage_br_restart_operation_plan.m`](../src/rescheduling/build_stage_br_restart_operation_plan.m)
- 运行入口：
  [`run_stage_br_restart_rule.m`](../scripts/run_stage_br_restart_rule.m)
- 轻量测试：
  [`test_stage_br_restart_rule.m`](../tests/test_stage_br_restart_rule.m)

## 轻量测试

```matlab
run(fullfile(pwd,'tests','test_stage_br_restart_rule.m'))
```

测试只使用原基线数据，不生成正式输出。

## 下一步

测试通过后进入阶段 B-R 第 2 步：将完整重加工后的新完成时间沿同工件和
同机器后续工序传播，形成从头加工规则下的局部影响集合。
