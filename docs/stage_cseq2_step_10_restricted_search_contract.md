# C-SEQ2 第 10 步：受限 NSGA-II 轻量搜索契约

## 目标

在 C-SEQ2 冻结问题基础上，运行一个小规模受限 NSGA-II 搜索契约，确认候选
评价、非支配排序、Pareto 去重和自适应停止条件可以工作。

本步只运行轻量契约：

- 种群规模 6；
- 迭代 2 代；
- 评价目标为最终卸载完工时间和总能耗；
- 保留 C-SEQ2 的累计维修上下文；
- 不保存正式实验输出；
- 不进行组合选择。

## 代码入口

- `scripts/run_stage_cseq2_restricted_search_contract.m`
- `tests/test_stage_cseq2_restricted_search_contract.m`

## 测试命令

```matlab
run(fullfile(pwd,'tests','test_stage_cseq2_restricted_search_contract.m'))
```

## 完成标准

- 搜索结果通过候选约束与能耗评价；
- Pareto 前沿去重；
- 固定随机种子下评价结果可复现；
- 能触发连续无改善停止分支；
- 能触发时间上限停止分支；
- 本步不是正式长实验。
