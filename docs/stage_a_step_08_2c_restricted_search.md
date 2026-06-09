# 阶段 A 第 8.2c 步：候选评价与受限 NSGA-II

## 1. 目标

将第 8.2a 解码器和第 8.2b 搜索算子连接为受限 NSGA-II 主循环，并使用轻量、可复现配置验证搜索契约。

本步不运行完整实验。

## 2. 当前评价目标

当前解码器尚未重建充电、电量和最终卸载运输，因此不能直接使用原项目的“包含最终卸载的完工时间 + 总能耗”目标。

本步只采用当前能够完整计算的两个最小化目标：

1. `machine_operation_makespan`：全部机器工序的最大完成时刻；
2. `machine_assignment_changes`：未开工工序相对原计划发生机器变化的数量。

第二个目标对应论文序列偏差 `SD` 的机器变化核心。第一个目标不等同于包含最终卸载的完整完工时间，代码中明确保留该区别。

## 3. 主循环

受限主循环执行：

1. 第 8.2b 受限种群初始化；
2. 第 8.2a 动态解码；
3. 双目标候选评价；
4. 非支配排序；
5. 拥挤距离；
6. 锦标赛选择；
7. 受限 IPOX、MPX 和变异；
8. 父子代合并与精英保留。

全部决策只覆盖未开工工序。

## 4. 轻量契约配置

测试入口固定使用：

```text
种群规模：6
迭代代数：2
交叉概率：0.8
变异概率：0.2
锦标赛规模：2
随机种子：原基线 seed
```

该配置只验证主循环和数据契约，不用于研究结论。

## 5. 新增文件

- `src/rescheduling/evaluate_stage_a_reschedule_candidate.m`
- `src/rescheduling/search_stage_a_complete_reschedule.m`
- `scripts/run_stage_a_restricted_search_contract.m`
- `tests/test_stage_a_restricted_search_contract.m`
- `docs/stage_a_step_08_2c_restricted_search.md`

## 6. 测试范围

- 最终种群规模正确；
- 每个候选都通过冻结解码器约束验证；
- 非支配前沿非空；
- 排名与拥挤距离可以支持精英保留；
- 搜索历史长度正确；
- 同一原基线随机种子得到相同目标结果；
- 明确标记未评价能耗和最终卸载。

## 7. MATLAB 测试

```matlab
run(fullfile(pwd, 'tests', ...
    'test_stage_a_restricted_search_contract.m'))
```

预期输出：

```text
test_stage_a_restricted_search_contract passed
```

## 8. 后续工作

轻量搜索契约通过后，需要先补充：

- 最终卸载运输；
- AGV 电量、充电和能耗；
- 完整完工时间与能耗评价。

之后才能运行正式完全重调度实验，并进入 `tD`、`SD`、`Y` 与组合选择。
