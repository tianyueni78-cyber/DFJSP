# 阶段 B 第 10 步：候选评价与受限 NSGA-II 轻量搜索

## 本步目标

将阶段 B 两段加工解码器接入候选评价与受限 NSGA-II 主循环，验证从种群、
解码、目标计算、非支配排序到 Pareto 输出的完整搜索契约。

本步采用轻量配置，不作为正式实验结果。

## 评价目标

每个个体先通过阶段 B 第 8 步解码器，再计算：

1. 最终卸载完工时间；
2. 机器与 AGV 总能耗。

机器能耗使用修正后的有效加工时长，维修停机不计入工作能耗。

## 搜索流程

1. 原基线未开工后缀作为种子；
2. 受限种群初始化；
3. 候选解码与双目标评价；
4. 非支配排序；
5. 拥挤距离；
6. 锦标赛选择；
7. IPOX、MPX 和受限变异；
8. 父子代合并与精英保留；
9. Pareto 目标去重；
10. 最大代数、连续无改善或时间上限停止。

## 轻量配置

- 种群：`6`；
- 最大代数：`2`；
- 交叉概率：`0.8`；
- 变异概率：`0.2`；
- 锦标赛规模：`2`；
- 固定原基线随机种子；
- 不保存输出文件。

测试还使用极小配置分别验证：

- 连续一代无 Pareto 改善停止；
- 极短时间上限停止。

## 代码入口

- 候选评价：
  [`evaluate_stage_b_reschedule_candidate.m`](../src/rescheduling/evaluate_stage_b_reschedule_candidate.m)
- 搜索主循环：
  [`search_stage_b_complete_reschedule.m`](../src/rescheduling/search_stage_b_complete_reschedule.m)
- 轻量入口：
  [`run_stage_b_restricted_search_contract.m`](../scripts/run_stage_b_restricted_search_contract.m)
- 轻量测试：
  [`test_stage_b_restricted_search_contract.m`](../tests/test_stage_b_restricted_search_contract.m)

## MATLAB 轻量测试

```matlab
run(fullfile(pwd,'tests','test_stage_b_restricted_search_contract.m'))
```

通过本步不代表完成正式搜索，只证明阶段 B 搜索链路可以正确运行。
