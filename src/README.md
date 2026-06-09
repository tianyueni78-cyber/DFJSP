# src

当前源码按职责分为：

```text
data/           无副作用的数据读取
scheduling/     正常调度解码与基线包装入口
search/         从原项目迁移的搜索基础函数
visualization/  甘特图等可视化函数
fault/          后续故障事件与状态提取
rescheduling/   后续右移和完全重调度
evaluation/     后续重调度评价指标
```

阶段 A 第 1 步使用：

- `data/read_fjsp.m`
- `data/read_machine_data.m`
- `data/read_agv_data.m`
- `scheduling/build_normal_schedule.m`

`raw_code/` 始终只读。新的入口通过包装函数调用已迁移代码。

阶段 A 第 2 步已开始使用 `fault/`：

- `fault/create_completion_fault_event.m`
- `fault/validate_completion_fault_event.m`

当前只负责工序完成时故障事件的创建和校验。
