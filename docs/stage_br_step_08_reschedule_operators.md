# 阶段 B-R 第 8 步：受限种群初始化、交叉和变异

## 目标

把已验证的受限种群算子接入 B-R 冻结问题和从头加工解码器，确认父代与
子代全部处于合法决策空间。

本步不计算适应度、不执行非支配排序、不运行 NSGA-II 代循环。

## 为什么复用现有算子

种群算子只读取：

- 未开工工序对应的工件编号；
- 每道工序的原候选机器；
- 原 AGV 数量；
- 原运输速度档位。

算子不读取中断工序采用续加工还是从头加工，也不修改冻结任务。因此复用
阶段 A 已验证算子，不复制和改写算法逻辑。

## 编码与算子

- `OS`：未开工工序的工件序列；
- `MS`：候选机器位置；
- `AS`：AGV 编号；
- `SS`：空载与负载速度档位；
- `IPOX`：保持工件出现次数的 OS 交叉；
- `MPX`：MS、AS、SS 掩码交叉；
- 受限变异：只在原候选机器、AGV 和速度范围内改变。

## 轻量契约

- 种群规模：`6`；
- 交叉概率：`0.8`；
- 变异概率：`0.2`；
- 随机种子：沿用原基线；
- 第一个个体来自原基线染色体未开工后缀；
- 每个父代和子代均通过 B-R 第 7 步解码器；
- 重复运行两次时结果完全一致；
- 不保存输出，不运行正式搜索。

## 代码入口

- 复用初始化：
  [`initialize_stage_a_reschedule_population.m`](../src/rescheduling/initialize_stage_a_reschedule_population.m)
- 复用交叉和变异：
  [`vary_stage_a_reschedule_population.m`](../src/rescheduling/vary_stage_a_reschedule_population.m)
- B-R 运行入口：
  [`run_stage_br_reschedule_operators.m`](../scripts/run_stage_br_reschedule_operators.m)
- 轻量测试：
  [`test_stage_br_reschedule_operators.m`](../tests/test_stage_br_reschedule_operators.m)

## 轻量测试

```matlab
run(fullfile(pwd,'tests','test_stage_br_reschedule_operators.m'))
```

## 下一步

测试通过后进入阶段 B-R 第 9 步：实现候选评价和受限 NSGA-II 轻量搜索
契约，暂不运行正式实验。
