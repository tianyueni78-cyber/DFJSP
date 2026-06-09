# 阶段 A 第 8.2b 步：未开工工序受限搜索算子

## 1. 目标

为第 8.2a 步的冻结解码器提供种群初始化、交叉和变异算子。所有算子只操作故障时刻未开工工序。

本步不计算适应度，不运行 NSGA-II 迭代。

## 2. 与原项目的关系

保留原 `init.m` 和 `variation.m` 的编码含义：

- `OS`：作业序列；
- `MS`：候选机器索引；
- `AS`：AGV 分配；
- `SS`：空载与负载速度挡位。

保留的算子思想：

- OS 使用 IPOX 交叉；
- MS、AS、SS 使用 MPX 交叉；
- OS 使用不同作业位置互换变异；
- MS、AS、SS 使用多点随机变异。

不同之处是编码长度和范围只覆盖 `frozen.reschedulable_operations`。

## 3. 初始化

种群第一个个体固定为原正常计划染色体的未开工后缀，作为原数据种子。

其余个体：

- 作业数量来自真实未开工工序集合；
- 机器索引来自各工序原候选机器数量；
- AGV 编号来自原 AGV 数量；
- 速度挡位来自原 AGV 速度档位。

随机个体是优化算法的候选解，不是新增实验数据。随机过程由外部 `rng` 控制。

## 4. 边界处理

- 只有一个个体时允许自复制；
- 所有父代相同时不会无限寻找不同父代；
- 未开工工序只涉及一个作业时，OS 交叉和互换变异保持原序列；
- 每次变异后的机器、AGV 和速度值仍在原范围内。

## 5. 新增文件

- `src/rescheduling/initialize_stage_a_reschedule_population.m`
- `src/rescheduling/vary_stage_a_reschedule_population.m`
- `scripts/run_stage_a_reschedule_operators.m`
- `tests/test_stage_a_reschedule_operators.m`
- `docs/stage_a_step_08_2b_restricted_operators.md`

## 6. 契约测试

测试使用原基线种子和原参数建立 6 个轻量候选，不计算目标函数。测试检查：

- 种群和子代规模；
- 作业序列多重集合不变；
- 机器、AGV 和速度范围；
- 每个子代均能被第 8.2a 解码器成功解码；
- 没有启动 NSGA-II 搜索。

## 7. MATLAB 测试

```matlab
run(fullfile(pwd, 'tests', ...
    'test_stage_a_reschedule_operators.m'))
```

预期输出：

```text
test_stage_a_reschedule_operators passed
```

## 8. 下一步

算子契约通过后，再实现候选评价和受限 NSGA-II 主循环。完整搜索实验仍需单独确认后才能运行。
