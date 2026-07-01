# `normalize_stage_c_fault_events` 代码说明

## 1. 这个文件是干什么的

这个函数的作用是：

> 把 Stage C 的原始故障数据整理成统一、规范、可直接使用的结构体数组。

它做的不是复杂算法，而是三件很基础但很重要的事：

- 检查输入数据对不对
- 把每条故障记录整理成统一格式
- 按时间排序，并给相同开始时间的事件分组

简单说，这个函数像一个“故障数据整理员”。
原始数据进来以后，它会先检查，再清洗，再排好队，最后交给后面的调度逻辑使用。

---

## 2. 输入和输出

### 输入

这个函数需要两个输入：

- `rawFaults`
- `machineCount`

#### `rawFaults`
原始故障数据，要求是一个非空的结构体数组。  
每一条故障至少要包含这些字段：

- `event_id`
- `machine_id`
- `start_time`
- `repair_duration`
- `interruption_rule`

#### `machineCount`
机器总数，用来检查 `machine_id` 是否越界。

### 输出

函数输出 `faults`。

`faults` 是整理后的故障结构体数组。  
每一条记录都会补齐为统一格式，并带上这些额外信息：

- `stage`
- `trigger_type`
- `repair_end_time`
- `event_group`
- `source_order`
- `is_validated`

---

## 3. 主流程在做什么

这个文件的主流程可以分成 5 步：

1. 检查输入参数是否足够
2. 检查 `rawFaults` 和 `machineCount` 是否合法
3. 逐条处理每个故障事件
4. 检查 `event_id` 是否重复
5. 排序、分组、标记为已验证

---

## 4. 主函数逐段说明

### 4.1 检查是否传入两个参数

```matlab
if nargin < 2
    error('normalize_stage_c_fault_events:MissingInput', ...
        'rawFaults and machineCount are required.');
end
```

这段的意思是：

- 如果调用这个函数时，输入参数少于 2 个
- 就直接报错

也就是说，这个函数必须同时传入：

- 原始故障数据 `rawFaults`
- 机器总数 `machineCount`

### 4.2 检查机器总数是否合法

```matlab
validate_machine_count(machineCount);
```

这句是在检查 `machineCount` 是否是一个合法的正整数。

如果机器总数不合法，后面的 `machine_id` 检查就没有意义了，所以这里先检查它。

### 4.3 检查原始故障数组格式

```matlab
if ~isstruct(rawFaults) || isempty(rawFaults) || ~isvector(rawFaults)
    error('normalize_stage_c_fault_events:InvalidFaultArray', ...
        'rawFaults must be a nonempty struct vector.');
end
```

这段的意思是：

`rawFaults` 必须满足三个条件：

- 是结构体数组
- 不能是空的
- 必须是一维向量

如果不满足，就报错。

---

## 5. 逐条整理故障数据

### 5.1 先准备一个标准模板

```matlab
template = fault_template();
faults = repmat(template, 1, numel(rawFaults));
eventIds = zeros(1, numel(rawFaults));
```

这三句是在做准备工作：

- `fault_template()` 先生成一个“标准空故障记录”
- `repmat(...)` 把这个模板复制成和原始数据一样多的数量
- `eventIds` 用来单独保存每条故障的 `event_id`

这里可以理解成：

> 先准备好空表格，再一条一条往里面填。

### 5.2 遍历每条原始故障

```matlab
for index = 1:numel(rawFaults)
```

这表示：

- 逐条读取 `rawFaults` 中的每一条故障
- 一条一条检查、一条一条整理

### 5.3 取出当前这条故障

```matlab
raw = rawFaults(index);
```

这句就是把当前这条原始故障拿出来，后面所有检查都针对它。

### 5.4 检查必填字段是否存在

```matlab
require_fields(raw, {'event_id', 'machine_id', 'start_time', ...
    'repair_duration', 'interruption_rule'});
```

这句是在确认当前这条故障里，必须字段都已经写齐。

如果少了一个字段，比如没有 `machine_id`，就会直接报错。

### 5.5 检查 `event_id`

```matlab
eventIds(index) = validate_positive_integer( ...
    raw.event_id, 'event_id');
faults(index).event_id = eventIds(index);
```

这两句的意思是：

- 检查 `event_id` 必须是正整数
- 合法后写进 `faults` 里

`event_id` 相当于这条故障的编号。

### 5.6 填入固定字段

```matlab
faults(index).stage = 'C';
faults(index).trigger_type = 'machine_failure';
```

这两句是在给每条故障加上固定标签：

- `stage = 'C'`，说明这是 Stage C 的故障
- `trigger_type = 'machine_failure'`，说明触发原因是机器故障

这类字段不是从原始数据里推出来的，而是程序统一补上的。

### 5.7 检查 `machine_id`

```matlab
faults(index).machine_id = validate_machine_id( ...
    raw.machine_id, machineCount);
```

这句是在检查故障对应的是哪台机器。

要求有两个：

- 必须是正整数
- 不能超过 `machineCount`

也就是：

> 机器编号必须落在合理范围内。

### 5.8 检查开始时间

```matlab
faults(index).start_time = validate_nonnegative_scalar( ...
    raw.start_time, 'start_time');
```

这句是在检查开始时间：

- 必须是数字
- 不能是负数

因为时间通常不能小于 0。

### 5.9 检查维修时长

```matlab
faults(index).repair_duration = validate_positive_scalar( ...
    raw.repair_duration, 'repair_duration');
```

这句是在检查维修时间：

- 必须是数字
- 必须大于 0

因为维修时长不能是 0，也不能是负数。

### 5.10 计算维修结束时间

```matlab
faults(index).repair_end_time = faults(index).start_time + ...
    faults(index).repair_duration;
```

这句是在算：

> 故障从什么时候开始，维修多久后结束。

也就是：

`repair_end_time = start_time + repair_duration`

### 5.11 检查可选的 `repair_end_time`

```matlab
validate_optional_repair_end(raw, faults(index).repair_end_time);
```

这句的意思是：

- 如果原始数据里没有写 `repair_end_time`，那就不管
- 如果写了，就检查它是否和程序计算结果一致

这样可以避免原始数据里手工填写的结束时间出错。

### 5.12 检查中断规则

```matlab
faults(index).interruption_rule = normalize_rule( ...
    raw.interruption_rule);
```

这句是在检查 `interruption_rule` 是否是允许的规则。

目前只允许两种：

- `resume_remaining`
- `restart_from_zero`

如果写了别的，就报错。

### 5.13 记录原始顺序

```matlab
faults(index).source_order = index;
```

这句是在记录：

> 这条故障原来在输入里是第几条。

这个字段后面排序时会用到，用来保证时间相同时，仍然保留原始顺序。

---

## 6. 检查 `event_id` 是否重复

```matlab
if numel(unique(eventIds)) ~= numel(eventIds)
    error('normalize_stage_c_fault_events:DuplicateEventId', ...
        'Each fault event_id must be unique.');
end
```

这段的意思是：

- `unique(eventIds)` 会把重复编号去掉
- 如果去重前后数量不一样，说明有重复编号
- 一旦重复，就报错

也就是说：

> 每条故障必须有自己唯一的 `event_id`，不能重复。

---

## 7. 排序

```matlab
startTimes = [faults.start_time].';
sourceOrders = [faults.source_order].';
[~, order] = sortrows([startTimes, sourceOrders], [1, 2]);
faults = faults(order);
```

这几句是在做排序。

### 排序规则

先按：

1. `start_time`
2. 如果开始时间一样，再按 `source_order`

这样做的好处是：

- 故障按时间顺序排列
- 同一时刻发生的故障，也能保持输入顺序不乱

---

## 8. 分组

```matlab
faults = assign_event_groups(faults);
```

这句是在调用辅助函数，给故障分组。

它的逻辑是：

- 开始时间相同的故障，归到同一组
- 开始时间不同的故障，进入新的一组

---

## 9. 标记为已验证

```matlab
for index = 1:numel(faults)
    faults(index).is_validated = true;
end
```

这句很简单：

- 遍历每条故障
- 给它加上 `is_validated = true`

意思是：

> 这条数据已经检查过、整理过了，可以放心给后续流程用。

---

## 10. 辅助函数说明

### 10.1 `assign_event_groups(faults)`

这个函数的作用是给故障分组。

```matlab
function faults = assign_event_groups(faults)
tolerance = 1e-9;
groupId = 1;
groupStart = faults(1).start_time;
faults(1).event_group = groupId;
for index = 2:numel(faults)
    if abs(faults(index).start_time - groupStart) > tolerance
        groupId = groupId + 1;
        groupStart = faults(index).start_time;
    end
    faults(index).event_group = groupId;
end
end
```

### 它在做什么

- 第一条故障先放进第 1 组
- 后面的故障逐条比较开始时间
- 如果开始时间和当前组不同，就开新组

### 为什么要有 `tolerance`

因为时间值有时会有非常小的浮点误差。  
所以不是“完全相等”才算同一组，而是允许一个很小的误差范围。

### 直白理解

> 开始时间一样的事件，算同一组。

### 10.2 `fault_template()`

这个函数定义了一条标准故障记录应该有哪些字段。

```matlab
function value = fault_template()
value = struct('event_id', [], 'stage', '', 'trigger_type', '', ...
    'machine_id', [], 'start_time', [], 'repair_duration', [], ...
    'repair_end_time', [], 'interruption_rule', '', ...
    'event_group', [], 'source_order', [], 'is_validated', false);
end
```

### 它的作用

就是准备一个“空模板”。

### 直白理解

> 先规定一条故障记录应该长什么样，然后后面再往里面填数据。

### 10.3 `validate_machine_count(value)`

```matlab
function validate_machine_count(value)
validate_positive_integer(value, 'machineCount');
end
```

这个函数只是一个包装，意思是：

> `machineCount` 必须是正整数。

### 10.4 `validate_machine_id(value, machineCount)`

```matlab
function value = validate_machine_id(value, machineCount)
value = validate_positive_integer(value, 'machine_id');
if value > machineCount
    error('normalize_stage_c_fault_events:InvalidMachine', ...
        'machine_id must not exceed machineCount.');
end
end
```

这个函数检查机器编号：

- 必须是正整数
- 不能超过总机器数

### 10.5 `validate_positive_integer(value, name)`

```matlab
function value = validate_positive_integer(value, name)
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || ...
        value < 1 || value ~= floor(value)
    error('normalize_stage_c_fault_events:InvalidInteger', ...
        '%s must be a positive integer.', name);
end
end
```

这个函数检查一个值是不是正整数。

### 直白理解

> 必须是一个正常的整数，不能是 0，不能是小数，不能是无穷大，不能是文字。

### 10.6 `validate_nonnegative_scalar(value, name)`

```matlab
function value = validate_nonnegative_scalar(value, name)
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || value < 0
    error('normalize_stage_c_fault_events:InvalidScalar', ...
        '%s must be a nonnegative finite scalar.', name);
end
end
```

这个函数检查一个值是不是非负数。

### 直白理解

> 可以是 0，也可以是正数，但不能是负数。

### 10.7 `validate_positive_scalar(value, name)`

```matlab
function value = validate_positive_scalar(value, name)
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || value <= 0
    error('normalize_stage_c_fault_events:InvalidScalar', ...
        '%s must be a positive finite scalar.', name);
end
end
```

这个函数检查一个值是不是正数。

### 直白理解

> 必须大于 0，0 也不行。

### 10.8 `validate_optional_repair_end(raw, expected)`

```matlab
function validate_optional_repair_end(raw, expected)
if ~isfield(raw, 'repair_end_time') || isempty(raw.repair_end_time)
    return
end
value = raw.repair_end_time;
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || ...
        abs(value - expected) > 1e-9
    error('normalize_stage_c_fault_events:InvalidRepairEnd', ...
        'repair_end_time must equal start_time + repair_duration.');
end
end
```

这个函数检查一个可选字段。

### 它的逻辑

- 如果 `repair_end_time` 没写，就不检查
- 如果写了，就必须和程序算出来的值一致

### 直白理解

> 这个字段可以不填，但一旦填了，就不能乱填。

### 10.9 `normalize_rule(value)`

```matlab
function value = normalize_rule(value)
if isstring(value) && isscalar(value)
    value = char(value);
end
if ~ischar(value) || size(value, 1) ~= 1
    error('normalize_stage_c_fault_events:InvalidRule', ...
        'interruption_rule must be a character vector or string scalar.');
end
allowed = {'resume_remaining', 'restart_from_zero'};
if ~any(strcmp(value, allowed))
    error('normalize_stage_c_fault_events:InvalidRule', ...
        'Unsupported interruption_rule: %s.', value);
end
end
```

这个函数检查中断规则。

### 允许的值只有两个

- `resume_remaining`
- `restart_from_zero`

### 直白理解

> 中断规则必须是项目规定好的两种写法之一，不能随便写别的。

### 10.10 `require_fields(value, fields)`

```matlab
function require_fields(value, fields)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('normalize_stage_c_fault_events:MissingField', ...
            'rawFaults.%s is required.', fields{index});
    end
end
end
```

这个函数检查结构体中是否包含所有必需字段。

### 直白理解

> 该有的字段必须都有，少一个都不行。

---

## 11. 这个文件整体的作用

这整个文件的核心职责可以总结成一句话：

> 把 Stage C 的原始故障事件转换成标准、可检查、可排序、可分组的格式。

它的价值在于：

- 让后续逻辑不用再反复检查数据格式
- 保证输入数据是干净的
- 统一不同来源的故障数据
- 方便后续调度、仿真、分析

---

## 12. 哪些地方以后可能会改

如果项目规则发生变化，这个文件里有些地方可能需要改。

### 可能改动的场景

- 新增故障字段
- 删除某个字段
- `event_id` 规则变化
- `machine_id` 规则变化
- 允许新的 `interruption_rule`
- `repair_end_time` 的定义变化
- 排序规则变化
- 分组规则变化

### 12.1 如果新增字段

要改的地方通常是：

- `fault_template()`
- `require_fields(...)`
- 主循环里给 `faults(index)` 赋值的部分

### 12.2 如果允许新的中断规则

要改的地方是：

- `normalize_rule(...)` 里的 `allowed` 列表

比如如果以后要新增：

- `pause_and_resume`

那就把它加进去。

### 12.3 如果分组规则变化

要改的地方是：

- `assign_event_groups(...)`

比如现在是“开始时间相同就分一组”，  
以后如果改成“时间差小于某个阈值才算一组”，就要改这里。

### 12.4 如果维修结束时间的定义变化

要改的地方是：

- 主函数里计算 `repair_end_time` 的那一行
- `validate_optional_repair_end(...)`

---

## 13. 初学者怎么理解这份代码

如果你是刚开始学代码，可以把它记成这个顺序：

1. 先检查参数
2. 再检查原始数据格式
3. 再一条一条处理故障
4. 再检查编号有没有重复
5. 再排序
6. 再分组
7. 再标记为已验证

也就是说，它不是“高深算法”，而是一个很典型的：

> **输入检查 + 数据整理 + 统一格式**

---

## 14. 一句话总结

`normalize_stage_c_fault_events` 的作用就是：

> 把原始 Stage C 故障数据检查一遍、整理一遍、排序一遍、分组一遍，最后变成后续流程可以直接使用的标准格式。
