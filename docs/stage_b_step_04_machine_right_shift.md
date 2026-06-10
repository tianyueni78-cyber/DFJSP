# 阶段 B 第 4 步：加工中故障的机器局部右移候选

## 本步目标

把第 3 步得到的受影响工序及预计开始、完成时间正式写入机器时间表，生成
加工中故障场景下的机器局部右移候选方案。

本步只处理机器工序时间，不调整 AGV。

## 核心处理

加工中断工序同时具有两种表示：

1. 逻辑工序：仍然只算一道工序，用于工件工艺顺序和完工时间检查；
2. 机器加工段：拆成故障前已加工段和修复后剩余加工段。

因此，维修区间不会被误算为机器加工时间，同时已完成的加工进度也不会丢失。

## 实现流程

1. 复制正常基线中的全部逻辑工序；
2. 将中断工序完成时间更新为修复后续加工完成时间；
3. 将第 3 步影响集合中的预计时间写入受影响的未开工工序；
4. 未受影响工序保持原机器、原开始时间和原完成时间；
5. 将中断工序拆成两个机器加工段；
6. 根据全部实际加工段重建机器时间表和空闲区间；
7. 检查机器无重叠、工件顺序、维修区间和加工时长；
8. 原 AGV 时间表原样复制，并标记为尚未调整、尚未验证。

## 代码入口

- 构建函数：
  [`build_stage_b_machine_right_shift.m`](../src/rescheduling/build_stage_b_machine_right_shift.m)
- 运行入口：
  [`run_stage_b_machine_right_shift.m`](../scripts/run_stage_b_machine_right_shift.m)
- 轻量测试：
  [`test_stage_b_machine_right_shift.m`](../tests/test_stage_b_machine_right_shift.m)

## 输出边界

本步输出是机器侧候选，不是完整 FJSP-AGV 可执行方案：

- `is_machine_validated = true`
- `is_agv_updated = false`
- `is_agv_validated = false`
- `is_fully_validated = false`

下一步必须分析机器时间变化对 AGV 运输时序的影响，再决定需要调整的运输任务。

## MATLAB 轻量测试

```matlab
cd('项目根目录')
run(fullfile(pwd,'tests','test_stage_b_machine_right_shift.m'))
```

该测试使用项目已有原数据入口，不新增工件、机器、加工时间或运输数据。
