# 阶段 B-R 第 9 步：候选评价与受限 NSGA-II 轻量搜索

## 目标

将 B-R 从头加工解码器接入候选评价和受限 NSGA-II 主循环，验证从种群、
解码、目标计算、非支配排序到 Pareto 输出的完整搜索契约。

本步只运行 `6×2` 轻量契约，不是正式实验结果，不保存输出文件。

## 双目标评价

每个个体通过 B-R 第 7 步解码器后计算：

1. 最终卸载完工时间；
2. 机器与 AGV 总能耗。

机器能耗按实际加工段计算：

- 故障前损失加工计入工作能耗；
- 修复后的完整重加工计入工作能耗；
- 维修停机只计为空闲，不计为加工。

## 搜索流程

1. 原基线未开工后缀作为种子；
2. 受限种群初始化；
3. B-R 候选解码与双目标评价；
4. 非支配排序和拥挤距离；
5. 锦标赛选择；
6. IPOX、MPX 与受限变异；
7. 父子代合并和精英保留；
8. Pareto 目标去重；
9. 最大代数、连续无改善或时间上限停止。

## 轻量配置

- 种群规模：`6`；
- 最大代数：`2`；
- 交叉概率：`0.8`；
- 变异概率：`0.2`；
- 锦标赛规模：`2`；
- 随机种子：原基线种子；
- 不保存输出。

测试还分别验证：

- 连续 `1` 代无 Pareto 改善停止；
- 极短时间上限停止；
- 固定随机种子下双目标结果可复现。

## 代码入口

- 候选评价：
  [`evaluate_stage_br_reschedule_candidate.m`](../src/rescheduling/evaluate_stage_br_reschedule_candidate.m)
- 搜索主循环：
  [`search_stage_br_complete_reschedule.m`](../src/rescheduling/search_stage_br_complete_reschedule.m)
- 轻量入口：
  [`run_stage_br_restricted_search_contract.m`](../scripts/run_stage_br_restricted_search_contract.m)
- 轻量测试：
  [`test_stage_br_restricted_search_contract.m`](../tests/test_stage_br_restricted_search_contract.m)

## 轻量测试

```matlab
run(fullfile(pwd,'tests','test_stage_br_restricted_search_contract.m'))
```

## 下一步

测试通过后进入阶段 B-R 第 10 步：建立正式搜索配置和结果保存入口。正式
搜索运行前仍需单独确认。
