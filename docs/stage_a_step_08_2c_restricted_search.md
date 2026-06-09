# 阶段 A 第 8.2c 步：候选评价与受限 NSGA-II

## 1. 目标

将第 8.2a 解码器和第 8.2b 搜索算子连接为受限 NSGA-II 主循环，并使用轻量、可复现配置验证搜索契约。

本步不运行完整实验。

## 2. 当前评价目标

第 8.2d 步补齐最终卸载与完整能耗后，本搜索采用原项目口径的两个最小化目标：

1. `final_unload_makespan`：全部工件运送到卸载站后的最大完成时刻；
2. `total_energy`：机器加工与有限空闲能耗加 AGV 运输能耗。

机器分配变化数仍保留在评价结构中，供后续计算 `SD`，但不再作为当前 NSGA-II 第二目标。

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
- 明确标记已评价能耗和最终卸载；
- 同一原基线随机种子得到相同的完整双目标结果。

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

8.2d 契约及本步回归测试通过后，才可以单独确认正式完全重调度实验规模。正式实验之后进入 `tD`、`SD`、`Y` 与组合选择。
