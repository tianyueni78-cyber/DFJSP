# tests

## 当前测试

`test_normal_schedule_contract.m`

检查正常调度入口能否返回：

- 染色体和目标值；
- 机器时间表与 AGV 时间表；
- 最大完工时间与能耗；
- AGV 电量和充电记录；
- 后续故障状态提取需要的输入数据。

当前仅完成测试代码与静态检查，尚未运行 MATLAB。

## 运行方法

先把 MATLAB 当前文件夹切换到项目根目录，并确认当前目录下存在 `tests/`、`scripts/`、`src/` 和 `raw_code/`。

```matlab
pwd
run(fullfile(pwd, 'tests', 'test_normal_schedule_contract.m'))
```

不能在其他项目目录中直接使用相对路径 `run('tests/test_normal_schedule_contract.m')`。

## 阶段 A 第 2 步测试

`test_completion_fault_event.m`

检查故障事件是否：

- 发生在目标工序完成时刻；
- 自动关联正确机器；
- 没有中断正在加工的工序；
- 正确计算维修结束时刻；
- 没有提前执行重调度。

```matlab
run(fullfile(pwd, 'tests', 'test_completion_fault_event.m'))
```

## 阶段 A 第 3 步测试

`test_stage_a_state_snapshot.m`

测试直接使用原项目数据生成的正常基线，不创建人工调度样例。它检查：

- 触发工序属于已完成集合；
- 所有真实工序被完整且唯一地分类；
- 已完成、进行中、未开始的时间边界；
- AGV 空闲和充电记录不会被误算为工件运输；
- 本步骤没有执行重调度。

```matlab
run(fullfile(pwd, 'tests', 'test_stage_a_state_snapshot.m'))
```

## 阶段 A 第 4 步测试

`test_stage_a_impact_analysis.m`

测试直接使用原项目数据生成的正常基线，检查：

- 维修区间与故障事件一致；
- 直接冲突工序属于故障机器并与维修区间重叠；
- 受影响与未受影响集合完整划分未开始工序；
- 每个受影响工序具有正的预计延迟和明确原因；
- 正常机器时间表没有被修改；
- 本步骤没有执行重调度。

```matlab
run(fullfile(pwd, 'tests', 'test_stage_a_impact_analysis.m'))
```

## 阶段 A 第 5 步测试

`test_stage_a_machine_right_shift.m`

检查：

- 正常基线没有被修改；
- 受影响工序使用第 4 步预计时间；
- 未受影响工序保持原时间；
- 若原故障场景的影响集合为空，全部工序时间保持原样；
- 机器分配和加工时长不变；
- 机器无加工重叠；
- 工件工艺顺序有效；
- 维修区间内无加工；
- AGV 时间表保持原样且未被标记为已验证。

```matlab
run(fullfile(pwd, 'tests', 'test_stage_a_machine_right_shift.m'))
```

## 阶段 A 第 6 步测试

`test_stage_a_agv_impact_analysis.m`

检查：

- 使用原项目 AGV 时间表；
- AGV 时间表未被修改；
- 受影响和未受影响运输完整划分工件运输；
- 直接受影响项是违反时间约束的负载运输；
- 同一 AGV 后续任务被标记为需要复核；
- 当前零机器变化场景得到零 AGV 调整。

```matlab
run(fullfile(pwd, 'tests', 'test_stage_a_agv_impact_analysis.m'))
```
