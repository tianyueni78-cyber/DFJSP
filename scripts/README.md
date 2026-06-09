# scripts

## 当前入口

`run_normal_schedule_baseline.m`

作用：

1. 读取阶段 A 正常调度配置。
2. 读取原始算例、机器数据和 AGV 数据。
3. 使用固定随机种子生成一条正常染色体。
4. 调用 `build_normal_schedule` 生成故障前基线。
5. 在内存中返回结果。

该入口不保存 outputs、不绘图、不加入机器故障逻辑。
