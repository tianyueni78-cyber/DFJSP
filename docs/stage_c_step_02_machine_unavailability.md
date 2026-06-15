# 阶段 C 第 2 步：机器维修不可用区间

## 本步目标

将第 1 步标准化的 `faults[]` 按机器汇总，并合并同一机器上重叠或相接的
维修区间。本步只建立资源不可用数据，不读取机器时间表、不修改调度方案。

## 合并规则

维修区间统一采用半开区间：

```text
[start_time, end_time)
```

同一机器的两个区间满足以下条件时合并：

```text
next.start_time <= current.end_time
```

因此 `[10,15)` 与 `[14,18)` 重叠并合并；`[10,15)` 与 `[15,18)` 相接，
也合并为 `[10,18)`。不同机器的区间绝不合并。

## 输出结构

```matlab
result.by_machine{machine_id}
result.intervals
```

- `by_machine` 供后续解码器按机器查询；
- `intervals` 是全部合并区间的扁平视图；
- 无故障机器对应空数组；
- 每个区间保存 `source_event_ids`、`source_event_groups` 和
  `source_orders`；
- 合并不会丢失任何原故障事件身份。

## 轻量测试

测试使用六条最小故障元数据：

- 机器 1 上三个重叠或相接区间合并为一个区间；
- 机器 1 上另一个分离区间保持独立；
- 机器 2、机器 3 分别保留自己的区间；
- 机器 4 没有故障，区间为空。

这些数据只验证区间算法，不是新的生产问题数据。

## 代码入口

- 实现：`src/fault/build_stage_c_machine_unavailability.m`
- 测试：`tests/test_stage_c_machine_unavailability.m`

```matlab
run(fullfile(pwd,'tests','test_stage_c_machine_unavailability.m'))
```

## 完成标准

- 每台机器可以有零个、一个或多个不可用区间；
- 同一机器重叠或相接区间正确合并；
- 合并后区间按时间有序且互不重叠；
- 不同机器区间互不混淆；
- 每个原故障事件恰好被一个合并区间覆盖；
- 不接入现有调度算法。
