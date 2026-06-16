# C-S2 第 8 步：从头加工完全重调度算子契约

## 目标

在 C-S2 第 7 步解码器可用后，接入受限种群初始化、交叉和变异算子，
验证 C-S2 的完全重调度候选可以被合法生成和扰动。

本步只做轻量算子契约测试，不评价适应度，不运行正式搜索。

## 编码结构

C-S2 继续使用原项目的四段决策编码：

- `operation_sequence`：未开工工序的工件序列；
- `machine_choice`：候选机器选择；
- `agv_assignment`：AGV 分配；
- `free_speed_choice` / `load_speed_choice`：空载与负载速度选择。

冻结工序、中断承诺和维修区间不进入变异范围。

## 复用关系

本步复用阶段 A 的：

- `build_stage_a_baseline_seed_decision`；
- `initialize_stage_a_reschedule_population`；
- `vary_stage_a_reschedule_population`。

区别是所有个体都用 C-S2 第 7 步解码器验证。

## 代码入口

- 阶段入口：`scripts/run_stage_cs2_reschedule_operators.m`
- 契约测试：`tests/test_stage_cs2_reschedule_operators.m`

## 完成标准

- 种群规模正确；
- 固定随机种子下结果可复现；
- 每个个体的 OS/MS/AS/SS 长度和取值范围合法；
- 父代和子代均能通过 C-S2 解码器；
- 不评价适应度；
- 不运行正式搜索。

## 运行方式

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_cs2_reschedule_operators.m'))
```
