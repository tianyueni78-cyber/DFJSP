# 阶段 B-R 第 7 步：完全重调度解码器

## 目标

将第 6 步冻结问题和一组 OS/MS/AS/SS 决策解码为完整机器与 AGV 调度，
同时严格保留“故障前损失加工 + 修复后完整重加工”的中断承诺。

本步只解码一个来自原基线染色体的未开工任务种子，不运行种群搜索。

## 复用部分

未开工任务继续使用阶段 A 已验证的调度核心：

- 工序顺序和候选机器选择；
- AGV 分配和运输速度；
- 空载、负载运输；
- 充电和最终卸载；
- AGV 能耗；
- 机器、工件和运输基本约束。

## B-R 专用处理

核心解码完成后，专用适配器执行：

1. 固定中断工序原机器和完整重加工结束时间；
2. 将逻辑有效加工时长恢复为原加工时长；
3. 恢复故障前损失加工段；
4. 恢复维修后的完整重加工段；
5. 按实际加工段重建机器时间表；
6. 将损失加工计入机器工作能耗；
7. 将维修停机作为空闲时间，不算作加工；
8. 验证工序、机器、运输、维修区间及两段承诺。

## 时间与能耗语义

- 工件完成进度只由完整重加工段产生；
- 故障前损失段不贡献工件完成进度；
- 逻辑有效加工时间等于原加工时间；
- 机器实际工作时间等于损失加工时间加原加工时间；
- 后续工序和运输必须等待完整重加工完成。

## 代码入口

- 解码器：
  [`decode_stage_br_complete_reschedule.m`](../src/rescheduling/decode_stage_br_complete_reschedule.m)
- 运行入口：
  [`run_stage_br_complete_reschedule_decode.m`](../scripts/run_stage_br_complete_reschedule_decode.m)
- 轻量测试：
  [`test_stage_br_complete_reschedule_decode.m`](../tests/test_stage_br_complete_reschedule_decode.m)

## 轻量测试

```matlab
run(fullfile(pwd,'tests','test_stage_br_complete_reschedule_decode.m'))
```

## 下一步

测试通过后进入阶段 B-R 第 8 步：接入受限种群初始化、交叉和变异，并
进行轻量算子契约测试。
