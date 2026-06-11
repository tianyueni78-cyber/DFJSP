# 阶段 B 第 9 步：受限种群初始化、交叉和变异

## 本步目标

将已在阶段 A 验证的受限种群算子接入阶段 B 冻结问题和两段加工解码器，
确认生成的父代与子代均属于合法决策空间。

本步不计算适应度，不执行非支配排序，也不运行 NSGA-II 代循环。

## 为什么可以复用阶段 A 算子

算子只读取：

- 可重调度工序及其工件编号；
- 每道工序的原候选机器数量；
- 原 AGV 数量；
- 原速度档位数量。

它不读取故障发生在工序完成时还是加工中，也不修改冻结工序。因此阶段 B
无需复制一套交叉和变异算法。

## 使用的编码与算子

- `OS`：未开工工序对应的工件序列；
- `MS`：候选机器位置；
- `AS`：AGV 编号；
- `SS`：空载与负载速度档位；
- `IPOX`：保持工件出现次数的 OS 交叉；
- `MPX`：MS、AS、SS 的掩码交叉；
- 受限变异：只在原候选机器、AGV 和速度范围内变异。

## 轻量契约

- 种群规模：`6`；
- 交叉概率：`0.8`；
- 变异概率：`0.2`；
- 随机种子：沿用原基线；
- 每个父代和子代均调用阶段 B 第 8 步解码器；
- 不保存输出，不运行正式搜索。

## 代码入口

- 复用算子：
  [`initialize_stage_a_reschedule_population.m`](../src/rescheduling/initialize_stage_a_reschedule_population.m)
  和
  [`vary_stage_a_reschedule_population.m`](../src/rescheduling/vary_stage_a_reschedule_population.m)
- 阶段 B 入口：
  [`run_stage_b_reschedule_operators.m`](../scripts/run_stage_b_reschedule_operators.m)
- 轻量测试：
  [`test_stage_b_reschedule_operators.m`](../tests/test_stage_b_reschedule_operators.m)

## MATLAB 轻量测试

```matlab
run(fullfile(pwd,'tests','test_stage_b_reschedule_operators.m'))
```

测试重复运行两次，以确认固定随机种子下父代和子代完全一致。
