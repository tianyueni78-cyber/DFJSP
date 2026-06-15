# 阶段 C 第 10.2 步：同时故障受限种群与遗传算子

## 本步目标

在第 9 步释放的未开工工序范围内，复用原项目的 OS、MS、AS、SS 编码，
建立受限种群初始化、交叉和变异契约。多个中断工序和维修区间不是染色体
变量，由第 10.1 步解码器固定恢复和校验。

## 代码入口

- 通用初始化算子：
  [`initialize_stage_a_reschedule_population.m`](../src/rescheduling/initialize_stage_a_reschedule_population.m)
- 通用交叉与变异：
  [`vary_stage_a_reschedule_population.m`](../src/rescheduling/vary_stage_a_reschedule_population.m)
- 阶段 C 轻量入口：
  [`run_stage_c_simultaneous_reschedule_operators.m`](../scripts/run_stage_c_simultaneous_reschedule_operators.m)
- 契约测试：
  [`test_stage_c_simultaneous_reschedule_operators.m`](../tests/test_stage_c_simultaneous_reschedule_operators.m)

## 编码含义

- `OS`：未开工工序的工件执行顺序；
- `MS`：各未开工工序选择候选机器的序号；
- `AS`：各未开工工序选择的 AGV；
- `SS`：AGV 空载和负载速度档位。

初始化和变异只能在原数据给出的候选机器、AGV 数量和速度档位内取值。
第一个个体保留原基线染色体中未开工部分，其余个体使用固定随机种子生成。

## 轻量契约

本步使用 `6` 个父代和 `6` 个子代，只执行一次交叉与变异。测试要求：

1. 两次运行产生完全相同的父代和子代；
2. 每条 OS 保持正确的工件多重集合；
3. MS、AS、SS 全部处于原数据合法范围；
4. 每个父代和子代均能通过多中断解码器；
5. 不评价适应度、不选择幸存者、不运行迭代搜索、不生成输出。
