# 阶段 A 第 8.2d 步：最终卸载、充电与完整能耗

## 1. 目标

补齐完全重调度解码器中的最终卸载运输、AGV 剩余电量、阈值充电、机器能耗和 AGV 能耗，使搜索能够恢复原项目的完整双目标评价。

## 2. 故障边界电量

第 8.1 步现在从原基线直接恢复每辆 AGV 在其故障边界可用时刻的：

- 位置；
- 可用时间；
- 剩余电量；
- 已累计运输能耗；
- 已完成充电次数。

数据来自原 `AGVTable` 和 `agvEGRecord`，不假设故障后 AGV 重新满电。

## 3. 充电规则

沿用原 `sorting.m`：

1. 每次安排下一道未开工工序前检查 AGV 电量；
2. 电量不高于 `AGVEG_MIN` 时前往卸载站充电；
3. 前往充电站使用最快速度挡位和对应空载能耗；
4. 充电时间为 `(AGVEG_MAX - 当前电量) / eChargeSpeed`；
5. 充电后恢复为 `AGVEG_MAX`。

充电增加时间和次数，但充入电量不计入运输消耗目标；AGV 能耗仍按原 `fitness.m` 统计电量下降量。

## 4. 最终卸载

每个工件最后一道工序完成后：

- 计算每辆 AGV 空载到达该机器的时刻；
- 选择最早可以离开的 AGV；
- 并列时沿用原规则选择到达较晚者；
- 使用最快速度空载到机器，再负载运输到卸载站；
- 负载运输结束时刻写入工件完整完工时间。

## 5. 完整目标

候选现在输出：

- `makespan`：所有工件最终卸载完成时刻的最大值；
- `machine_energy`：机器加工和有限空闲能耗；
- `agv_energy`：故障前已发生消耗与故障后运输消耗之和；
- `total_energy`：机器能耗与 AGV 能耗之和。

第 8.2c 搜索目标相应恢复为：

```text
final_unload_makespan
total_energy
```

机器分配变化数仍保留在评价结构中，供后续计算 `SD` 和组合评价使用，但不作为当前 NSGA-II 的第二目标。

## 6. 修改与新增文件

修改：

- `src/rescheduling/build_stage_a_frozen_problem.m`
- `src/rescheduling/decode_stage_a_complete_reschedule.m`
- `src/rescheduling/evaluate_stage_a_reschedule_candidate.m`
- `src/rescheduling/search_stage_a_complete_reschedule.m`
- 对应既有回归测试。

新增：

- `scripts/run_stage_a_complete_energy_contract.m`
- `tests/test_stage_a_complete_energy_contract.m`
- `docs/stage_a_step_08_2d_energy_and_unload.md`

## 7. MATLAB 测试

先运行本步契约测试：

```matlab
run(fullfile(pwd, 'tests', ...
    'test_stage_a_complete_energy_contract.m'))
```

然后回归轻量搜索：

```matlab
run(fullfile(pwd, 'tests', ...
    'test_stage_a_restricted_search_contract.m'))
```

预期分别输出：

```text
test_stage_a_complete_energy_contract passed
test_stage_a_restricted_search_contract passed
```

## 8. 当前边界

- 不运行完整 NSGA-II 实验；
- 不生成正式实验输出；
- 不计算论文组合指标 `Y`；
- 正式搜索规模和权重仍需后续单独确认。
