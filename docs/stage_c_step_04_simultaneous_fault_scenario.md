# 阶段 C 第 4 步：同时故障场景筛选

## 本步目标

从原项目正常基线中动态选择两台在同一时刻确实受到故障直接影响的机器，
建立第一版正式同时故障场景。本步不传播故障影响，不修改机器或 AGV 计划。

## 筛选方法

1. 读取原基线全部真实加工块；
2. 找到机器活动集合保持不变的时间窗口；
3. 只保留至少两台机器同时加工的窗口；
4. 对活动机器两两组合；
5. 将窗口中点作为候选故障时刻；
6. 要求两台机器各有一道在制工序被直接中断；
7. 统计维修期内与两台机器原计划相交的工序数量；
8. 按维修相交工序数、活动窗口长度、故障时刻和机器编号排序。

维修相交工序数仅用于场景排序，不属于第 5 步的影响传播结果。

## 第一版参数

```text
故障机器数：2
维修时长：5
中断规则：resume_remaining
```

生产问题、工件、机器能力、加工时间和 AGV 数据均来自原项目。程序只增加
故障实验参数，不生成新的生产问题数据。

## 场景输出

场景包含：

- 原正常基线及来源；
- 全部有效候选和排序规则；
- 排名第 1 的候选；
- 两个标准化故障事件；
- 两台机器的维修不可用区间；
- 故障时刻状态快照；
- `impact_propagated = false`；
- `is_rescheduled = false`。

## 代码入口

- 配置：`configs/stage_c_simultaneous_fault_config.m`
- 筛选：`src/screening/screen_stage_c_simultaneous_fault_scenarios.m`
- 场景入口：`scripts/run_stage_c_simultaneous_fault_scenario.m`
- 测试：`tests/test_stage_c_simultaneous_fault_scenario.m`

```matlab
run(fullfile(pwd,'tests','test_stage_c_simultaneous_fault_scenario.m'))
```

## 完成标准

- 至少存在一个有效同时故障候选；
- 两台机器在故障时刻均有在制工序；
- 候选和正式事件都能追溯到原基线；
- 使用统一中断规则和维修参数；
- 不新增生产数据；
- 不执行影响传播或重调度。
