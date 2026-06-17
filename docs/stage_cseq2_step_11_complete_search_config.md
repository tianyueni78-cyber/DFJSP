# C-SEQ2 第 11 步：正式搜索配置与结果保存入口

## 目标

建立 C-SEQ2 正式完全重调度搜索入口，为后续单随机种子正式实验做准备。

本步只验证入口和配置：

- 种群规模 10；
- 最大迭代 100 代；
- 连续 10 代 Pareto 无改善停止；
- 30 秒时间上限停止；
- 结果保存到 `outputs/stage_cseq2_complete_reschedule_search/`；
- 运行前仍需要单独确认。

## 代码入口

- `configs/stage_cseq2_complete_search_config.m`
- `scripts/run_stage_cseq2_complete_search.m`
- `tests/test_stage_cseq2_complete_search_config.m`

## 测试命令

```matlab
run(fullfile(pwd,'tests','test_stage_cseq2_complete_search_config.m'))
```

## 完成标准

- 配置值与阶段 C/C-S2 正式搜索保持一致；
- 输出目录使用相对项目根路径；
- 正式搜索入口存在；
- 配置测试不运行搜索、不生成输出。
