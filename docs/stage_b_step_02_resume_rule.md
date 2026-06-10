# 阶段 B 第 2 步：暂停后在原机器续加工

## 1. 已确定规则

阶段 B 第一版采用：

> 故障发生时立即暂停中断工序，保留故障前已经完成的加工进度；故障机器
> 修复后，中断工序在原机器上继续加工剩余时间。

明确不采用：

- 已加工部分作废并从头加工；
- 将中断工序迁移到其他机器；
- 维修期间继续累计加工时间。

## 2. 时间结构

```text
原开始 ── 已加工段 ── 故障
                       │ 维修区间，不加工
                       └──────── 修复结束 ── 剩余加工段 ── 新完成
```

计算关系：

```text
续加工开始时间 = 维修结束时间
续加工结束时间 = 维修结束时间 + 剩余加工时间
总有效加工时间 = 已加工时间 + 剩余加工时间
新完成时间延迟 = 维修时长
```

## 3. 本步实现

- `src/rescheduling/build_stage_b_resume_operation_plan.m`
- `scripts/run_stage_b_resume_rule.m`
- `tests/test_stage_b_resume_rule.m`

输出的恢复计划包括：

- 故障前已加工段；
- 维修不可用区间；
- 修复后剩余加工段；
- 新完成时间和延迟；
- 进度保留、禁止从头加工、禁止迁移的规则标志。

故障事件继续保存客观事实，仍保留
`fault.interruption_rule='unresolved'`；最终采用的规则单独记录在
`scenario.resolved_interruption_rule` 和 `resume_plan.rule` 中，避免用决策
覆盖原始事件。

## 4. 当前边界

本步只处理被中断工序本身：

- 不传播到同工件后续工序；
- 不传播到同机器后续工序；
- 不调整 AGV；
- 不执行完全重调度搜索。

这些工作属于阶段 B 后续步骤。

## 5. 轻量测试

```matlab
run(fullfile(pwd,'tests','test_stage_b_resume_rule.m'))
```

预期输出：

```text
test_stage_b_resume_rule passed
```
