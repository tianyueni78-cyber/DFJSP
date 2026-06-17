# C-SEQ2 第 14 步：权重敏感性、最终审计与数据来源

## 目标

对 C-SEQ2 组合选择结果进行权重敏感性分析、最终约束审计、能耗审计，并明确
数据来源。

## 数据来源说明

当前 C-SEQ2 使用的是项目原代码/原数据链路，不是重新编造的问题数据。

源数据来自：

- FJSP 算例：`raw_code/fjsp/Brandimarte_Data/Mk02.fjs`
- 机器距离与能耗：`raw_code/机器数据.xlsx`
- AGV 数量、速度与能耗：`raw_code/AGV数据.xlsx`

程序入口 `scripts/run_normal_schedule_baseline.m` 通过 `configs/normal_schedule_config.m`
读取以上文件，并生成正常调度基线。后续故障事件、状态提取、局部右移、完全
重调度搜索都建立在这条基线和当前计划视图上。

不是源数据、而是实验参数的内容包括：

- 故障事件选择；
- 维修时长；
- 随机种子；
- 种群规模、迭代次数和停止条件；
- 组合指标权重。

这些参数用于构造实验场景和搜索预算，但没有替换工件、机器、AGV、加工时间、
运输距离或能耗数据。

## 代码入口

- `configs/stage_cseq2_step_14_config.m`
- `scripts/run_stage_cseq2_step_14_analysis.m`
- `tests/test_stage_cseq2_step_14_contract.m`

## 测试命令

```matlab
run(fullfile(pwd,'tests','test_stage_cseq2_step_14_contract.m'))
```

## 完成标准

- 权重 `0:0.1:1` 的组合选择可重新计算；
- 局部右移和完全重调度均通过维修、中断、最终卸载与能耗审计；
- 数据来源审计确认使用 `raw_code` 中的原始数据；
- 不运行多随机种子正式实验。

## 正式结果

正式输入：

- `outputs/stage_cseq2_complete_reschedule_search/20260617_165951/result.mat`

权重敏感性结果：

| omega1 | selected strategy | tD | SD | Y |
| ---: | --- | ---: | ---: | ---: |
| 0.0 | partial_right_shift | 3.0000 | 0 | 0.0000 |
| 0.1 | partial_right_shift | 3.0000 | 0 | 0.3000 |
| 0.2 | partial_right_shift | 3.0000 | 0 | 0.6000 |
| 0.3 | partial_right_shift | 3.0000 | 0 | 0.9000 |
| 0.4 | complete_rescheduling | -28.3667 | 17 | -1.1467 |
| 0.5 | complete_rescheduling | -28.3667 | 17 | -5.6833 |
| 0.6 | complete_rescheduling | -28.3667 | 17 | -10.2200 |
| 0.7 | complete_rescheduling | -28.3667 | 17 | -14.7567 |
| 0.8 | complete_rescheduling | -28.3667 | 17 | -19.2933 |
| 0.9 | complete_rescheduling | -28.3667 | 17 | -23.8300 |
| 1.0 | complete_rescheduling | -28.3667 | 17 | -28.3667 |

审计结果：

- `all_constraint_audits_validated = 1`
- `all_energy_audits_complete = 1`
- `source_data_only = 1`
- `synthetic_problem_data_created = 0`
- 总工序数：`58`

结论：

当只看序列稳定性或极低完工时间权重时，局部右移因 `SD=0` 被选中；当
`omega1 >= 0.4` 时，完工时间改善占优，完全重调度被选中。默认权重
`omega1=0.9` 下，C-SEQ2 仍选择 `complete_rescheduling`。
