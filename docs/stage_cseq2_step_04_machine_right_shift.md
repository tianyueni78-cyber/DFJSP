# C-SEQ2 第 4 步：局部右移机器候选

## 目标

将 C-SEQ2 第 3 步得到的新故障影响集合写入机器侧候选调度表，生成局部右移
机器方案。

本步仍然只处理机器侧：

- 不调整 AGV；
- 不建立完全重调度冻结问题；
- 不运行搜索。

## 关键约束

- 新故障中断工序按 C-SEQ1 规则保留已加工进度，维修后继续剩余加工；
- 历史维修区间和新维修区间都必须作为机器不可用区间保留；
- 受影响后续工序右移，但机器分配不改变；
- 机器加工段之间不得重叠；
- AGV 表暂时保持当前计划视图不变。

## 代码入口

- `scripts/run_stage_cseq2_machine_right_shift.m`
- `tests/test_stage_cseq2_machine_right_shift.m`

## 测试命令

```matlab
cd('D:\CODEX\机器故障')
run(fullfile(pwd,'tests','test_stage_cseq2_machine_right_shift.m'))
```

## 完成标准

- 机器候选方案通过机器侧约束；
- 所有累计维修区间均被避开；
- 受影响工序时间写入候选表；
- AGV 表不变；
- 不运行搜索。
