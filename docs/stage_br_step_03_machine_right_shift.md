# 阶段 B-R 第 3 步：机器局部右移候选

## 目标

将第 2 步的预计时间正式写入机器侧候选，并把中断工序表示为：

1. 故障前损失加工段；
2. 修复后完整重加工段。

本步不调整 AGV，输出还不是完整可执行的 FJSP-AGV 方案。

## 为什么需要专用构建器

阶段 B 的两个加工段共同构成一次完整有效加工，其加工时间之和等于原加工
时间。阶段 B-R 不同：

```text
实际机器加工总时间 = 损失加工时间 + 原完整加工时间
有效完成加工时间 = 原完整加工时间
```

因此不能直接套用阶段 B 的“两个加工段之和等于原加工时间”校验。

## 实现流程

1. 复制正常基线全部逻辑工序；
2. 将中断工序逻辑完成时间更新为完整重加工结束；
3. 保持逻辑工序有效加工时长为原加工时间；
4. 记录故障前损失加工时间；
5. 写入受影响未开始工序的预计时间；
6. 用损失段和完整重加工段重建机器时间表；
7. 检查机器不重叠、工序优先关系和维修区间；
8. 原 AGV 时间表保持不变并标记为尚未验证。

## 验证语义

- 每道逻辑工序仍只出现一次；
- 机器分配不改变；
- 中断工序必须恰好有两个实际加工段；
- 损失段时长等于故障前已加工时间；
- 重加工段时长等于原完整加工时间；
- 两段机器加工时长之和等于 `total_machine_processing_time`；
- 未受影响工序保持原时间；
- 故障机器维修区间内没有加工。

## 代码入口

- 构建函数：
  [`build_stage_br_machine_right_shift.m`](../src/rescheduling/build_stage_br_machine_right_shift.m)
- 运行入口：
  [`run_stage_br_machine_right_shift.m`](../scripts/run_stage_br_machine_right_shift.m)
- 轻量测试：
  [`test_stage_br_machine_right_shift.m`](../tests/test_stage_br_machine_right_shift.m)

## 轻量测试

```matlab
run(fullfile(pwd,'tests','test_stage_br_machine_right_shift.m'))
```

## 下一步

测试通过后进入阶段 B-R 第 4 步：分析机器时间变化是否使原 AGV 运输约束
失效，暂不正式调整 AGV。
