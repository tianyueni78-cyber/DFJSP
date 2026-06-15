# 阶段 C 第 10.3 步：候选评价与受限 NSGA-II 轻量搜索

## 本步目标

把第 10.1 步多中断解码器和第 10.2 步受限算子接入 NSGA-II，使用最终卸载
完工时间和总能耗评价候选。本步只运行 `6×2` 轻量契约，不保存正式结果。

## 代码入口

- 候选评价：
  [`evaluate_stage_c_simultaneous_reschedule_candidate.m`](../src/rescheduling/evaluate_stage_c_simultaneous_reschedule_candidate.m)
- 受限搜索：
  [`search_stage_c_simultaneous_complete_reschedule.m`](../src/rescheduling/search_stage_c_simultaneous_complete_reschedule.m)
- 轻量入口：
  [`run_stage_c_simultaneous_restricted_search_contract.m`](../scripts/run_stage_c_simultaneous_restricted_search_contract.m)
- 契约测试：
  [`test_stage_c_simultaneous_restricted_search_contract.m`](../tests/test_stage_c_simultaneous_restricted_search_contract.m)

## 目标函数

1. `final_unload_makespan`：全部工件完成最终卸载的时间；
2. `total_energy`：机器能耗与 AGV 运输、等待和充电能耗之和。

每次评价均通过多中断解码器，因此多个中断承诺和全部维修区间是候选可行性
的一部分，不作为可被搜索改变的变量。

## 搜索机制

- 非支配排序；
- 拥挤距离；
- 锦标赛选择；
- 精英保留；
- Pareto 目标向量去重；
- 连续若干代无改善停止；
- 达到时间上限停止。

轻量契约使用固定随机种子、种群 `6`、最多 `2` 代，并额外验证两种自适应
停止分支。它不是正式实验，不写入 `outputs/`。
