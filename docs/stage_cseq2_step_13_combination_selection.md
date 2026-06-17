# C-SEQ2 第 13 步：组合选择

## 目标

比较 C-SEQ2 局部右移方案和完全重调度方案，使用统一的重调度评价指标选择
最终策略。

评价指标：

- `tD`：候选最终卸载完工时间与当前计划完工时间的差；
- `SD`：工序机器分配变化数量；
- `Y = 0.9 * tD + 0.1 * SD`。

## 代码入口

- `scripts/run_stage_cseq2_combination_selection.m`
- `tests/test_stage_cseq2_combination_contract.m`

## 测试命令

```matlab
run(fullfile(pwd,'tests','test_stage_cseq2_combination_contract.m'))
```

## 完成标准

- 局部右移方案完成机器、AGV、维修和能耗审计；
- 完全重调度 Pareto 方案完成机器、AGV、维修和能耗审计；
- 所有候选均计算 `tD`、`SD` 和 `Y`；
- 选择 `Y` 最小的策略；
- 契约测试使用轻量搜索结果，不重复正式搜索。
