# 阶段 A 第 8.1 步：构造故障冻结问题

## 1. 目标

为完全重调度建立故障时刻边界。该步骤只定义哪些内容冻结、哪些内容允许重新优化，不运行搜索算法。

## 2. 冻结规则

- 已完成工序保持原机器和原时间；
- 故障时刻正在加工的工序保持原机器和原完成时间；
- 未开始工序进入完全重调度决策集合；
- 原计划中未开始的 AGV 运输被释放，后续允许重新分配 AGV；
- 已开始的 AGV 活动决定对应 AGV 的最早可用时间和位置。

阶段 A 的故障发生在工序完成时，因此故障机器上不存在被故障中断的在制工序。

## 3. 动态输出

构造器根据任意已验证的故障事件和状态快照生成：

- 冻结工序集合；
- 可重调度工序集合；
- 每个工件的已冻结工序前缀、释放时刻和当前位置；
- 每台机器的最早可用时刻；
- 每辆 AGV 的最早可用时刻和位置；
- 故障机器维修区间；
- 被释放的原计划未开始运输。

没有写死 `J5-O1`、机器编号或维修时长。

## 4. 候选机器与加工时间

每道未开始工序的候选机器及对应加工时间直接读取：

```text
baseline.problem.candidateMachine
baseline.problem.jobInfo
```

不生成替代加工数据。

## 5. 新增文件

- `src/rescheduling/build_stage_a_frozen_problem.m`
- `scripts/run_stage_a_frozen_problem.m`
- `tests/test_stage_a_frozen_problem.m`
- `docs/stage_a_step_08_1_frozen_problem.md`

## 6. 当前边界

本步没有：

- 生成染色体或种群；
- 运行 NSGA-II；
- 改变任何工序、机器或 AGV 安排；
- 计算完全重调度候选方案；
- 计算 `tD`、`SD` 或 `Y`。

## 7. MATLAB 测试

在项目根目录执行：

```matlab
run(fullfile(pwd, 'tests', 'test_stage_a_frozen_problem.m'))
```

预期输出：

```text
test_stage_a_frozen_problem passed
```

测试确认冻结集合与可重调度集合完整划分原工序，并核对工件、机器和 AGV 的边界状态。
