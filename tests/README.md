# tests

## 当前测试

`test_normal_schedule_contract.m`

检查正常调度入口能否返回：

- 染色体和目标值；
- 机器时间表与 AGV 时间表；
- 最大完工时间与能耗；
- AGV 电量和充电记录；
- 后续故障状态提取需要的输入数据。

当前仅完成测试代码与静态检查，尚未运行 MATLAB。

## 运行方法

先把 MATLAB 当前文件夹切换到项目根目录，并确认当前目录下存在 `tests/`、`scripts/`、`src/` 和 `raw_code/`。

```matlab
pwd
run(fullfile(pwd, 'tests', 'test_normal_schedule_contract.m'))
```

不能在其他项目目录中直接使用相对路径 `run('tests/test_normal_schedule_contract.m')`。

## 阶段 A 第 2 步测试

`test_completion_fault_event.m`

检查故障事件是否：

- 发生在目标工序完成时刻；
- 自动关联正确机器；
- 没有中断正在加工的工序；
- 正确计算维修结束时刻；
- 没有提前执行重调度。

```matlab
run(fullfile(pwd, 'tests', 'test_completion_fault_event.m'))
```
