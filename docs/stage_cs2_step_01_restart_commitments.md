# C-S2 第 1 步：同时故障下从头加工中断承诺

## 目标

在 Stage C 同时故障场景中，将中断规则从 `resume_remaining` 扩展为
`restart_from_zero`。本步只定义多个中断工序的从头加工承诺，不传播影响、
不修改机器时间表、不调整 AGV、不运行搜索。

## 本步解决的问题

`C-S1` 已验证：

```text
同时故障 + 保留进度 + 修复后继续剩余加工
```

`C-S2` 要补充：

```text
同时故障 + 故障前进度作废 + 修复后完整重加工
```

因此每个被故障直接中断的工序都需要记录：

- 故障前损失加工段；
- 修复后完整重加工段；
- 故障前进度不保留；
- 中断工序不迁移机器；
- 后续步骤需要把损失加工和完整重加工都计入机器工作能耗。

## 代码入口

- 承诺构造：`src/rescheduling/build_stage_c_simultaneous_restart_commitments.m`
- 阶段入口：`scripts/run_stage_cs2_restart_commitments.m`
- 契约测试：`tests/test_stage_cs2_restart_commitments.m`

## 关键字段

每个承诺包含：

| 字段 | 含义 |
|---|---|
| `rule` | 固定为 `restart_from_zero` |
| `lost_processing_segment` | 故障前已经加工但作废的时间段 |
| `lost_processing_time` | 作废加工时间 |
| `restart_segment` | 修复后完整重加工时间段 |
| `effective_completion_processing_time` | 对完工有效的加工时间，等于原完整工时 |
| `total_machine_processing_time` | 损失加工时间 + 完整重加工时间 |
| `restart_from_zero` | `true` |
| `progress_preserved` | `false` |

## 完成标准

- 每个同时故障事件对应一个直接中断工序；
- 每个中断工序生成一个从头加工承诺；
- `restart_from_zero=true`；
- `progress_preserved=false`；
- `lost_processing_segment` 不贡献完工；
- `restart_segment` 贡献完工；
- 本步不修改原机器表和 AGV 表；
- 测试通过后进入 C-S2 第 2 步：从从头加工承诺传播影响。

## 运行方式

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_cs2_restart_commitments.m'))
```
