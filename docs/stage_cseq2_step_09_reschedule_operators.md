# C-SEQ2 第 9 步：受限重调度算子契约

## 目标

在 C-SEQ2 第 7 步冻结问题基础上，接入完全重调度搜索前的受限编码算子。

本步只验证算子链路：

- 生成基线种子染色体；
- 初始化一个小规模受限种群；
- 执行一次交叉和变异；
- 检查 OS、MS、AS、速度选择均在合法范围；
- 抽样解码一个子代，确认仍满足 C-SEQ2 解码约束；
- 不评价适应度，不运行 NSGA-II 主循环。

## 代码入口

- `scripts/run_stage_cseq2_reschedule_operators.m`
- `tests/test_stage_cseq2_reschedule_operators.m`

## 测试命令

```matlab
run(fullfile(pwd,'tests','test_stage_cseq2_reschedule_operators.m'))
```

## 完成标准

- 两次固定随机种子运行得到相同种群和子代；
- 每个个体的工序序列数量与可重调度工序一致；
- 机器选择、AGV 选择、空载/负载速度选择均合法；
- 至少一个子代可以解码为通过约束的 C-SEQ2 完全重调度候选；
- 本步不运行正式搜索。
