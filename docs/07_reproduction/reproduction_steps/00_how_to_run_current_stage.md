# 现在这套封装怎么跑

这个文档只解决一个问题：

```text
我现在打开 MATLAB，应该怎么一步步跑已经封装好的东西？
```

先说清楚：现在还没有完整跑论文实验。

当前已经做到的是：

```text
第 1 段：能单独读取数据
第 2 段：已经知道 fitness/sorting 需要什么输入
第 3 段：已经封装了 evaluate_chromosome 评价入口
```

还没有做到：

```text
自动生成 chrom 的小测试
一键评价一条 chrom 的测试
小种群短迭代
完整 dif_main / same_main 复现
```

所以你现在能跑的，分两类。

## 1. 先跑已经有测试的部分

这部分最稳，建议你先跑。

在 MATLAB 里输入：

```matlab
cd D:\CODEX\code_refactor_project

run('tests/test_read_fjsp.m')
run('tests/test_read_machine_data.m')
run('tests/test_read_agv_data.m')
```

这三条是在检查：

```text
.fjs 能不能读
机器 Excel 能不能读
AGV Excel 能不能读
读取时有没有乱生成文件
```

如果这三条过了，说明：

```text
数据入口基本没问题。
```

如果这里就报错，先不要看算法，先查：

- 当前 MATLAB 目录是不是 `D:\CODEX\code_refactor_project`
- `data_sample/` 里的样本文件还在不在
- Excel 文件名或 sheet 名有没有被改
- MATLAB 能不能正常读 Excel

## 2. evaluate_chromosome 现在怎么理解

`evaluate_chromosome.m` 现在已经有了，但它还不是一个可以直接“按一下就跑”的完整实验脚本。

它更像一个零件：

```text
给它一条 chrom
给它数据 problem / machineData / agvData
给它参数 config
它帮你调用原始 fitness.m
然后返回 makespan 和 energy
```

也就是说，它的用途是：

```text
以后评价一条调度方案时，不用手动拼 fitness.m 那一长串参数。
```

但是它还缺一个东西：

```text
一条合法 chrom 从哪里来。
```

`chrom` 可以以后由 `init.m` 生成，也可以测试里临时生成。

所以当前阶段不要把 `evaluate_chromosome.m` 理解成“完整运行入口”。

更准确地说：

```text
它是后面 test_evaluate_chromosome.m 要调用的核心函数。
```

## 3. 如果你想手动试 evaluate_chromosome，需要准备什么

这一段是“手动试跑思路”，不是当前最推荐的入口。

你需要准备五样东西：

```text
chrom
problem
machineData
agvData
config
```

其中：

```matlab
problem = read_fjsp(...);
machineData = read_machine_data(...);
agvData = read_agv_data(...);
```

这些已经有函数了。

`config` 目前需要你手动写：

```matlab
config.AGVEG_MAX = 100;
config.AGVEG_MIN = 某个充电阈值;
config.eChargeSpeed = 20;
```

`chrom` 目前还没有新封装入口。

如果临时用原始 `init.m`，你还要加路径：

```matlab
projectRoot = 'D:\CODEX\code_refactor_project';

addpath(fullfile(projectRoot, 'src', 'data'))
addpath(fullfile(projectRoot, 'src', 'evaluation'))
addpath(fullfile(projectRoot, 'raw_code', 'NSGA-II'))
```

注意：

```text
raw_code 里有多个 fitness.m / sorting.m / init.m。
你 addpath 哪个算法目录，就会调用哪个算法目录里的函数。
```

当前建议先用：

```text
raw_code/NSGA-II
```

因为它是基础链路，比改进算法更适合做最小试跑。

## 4. 为什么你现在会觉得“拆太碎”

你这个感觉是对的。

因为现在仓库里有两种文档：

```text
拆解记录：解释我拆了什么、为什么这样拆
运行教程：告诉你打开 MATLAB 具体怎么跑
```

之前多是“拆解记录”，所以你会觉得：

```text
我知道你封装了，但我还是不知道我该怎么跑。
```

以后复现步骤文件夹会按这个规则维护：

```text
00_how_to_run_current_stage.md
    永远写“当前能怎么跑”

01/02/03...
    写每一步拆解、封装、测试的来龙去脉
```

你以后不知道怎么跑时，先看：

```text
docs/07_reproduction/reproduction_steps/00_how_to_run_current_stage.md
```

不要先看第 2 步、第 3 步那些拆解文。

## 5. 当前最推荐你跑什么

现在最推荐你只跑这三条：

```matlab
cd D:\CODEX\code_refactor_project

run('tests/test_read_fjsp.m')
run('tests/test_read_machine_data.m')
run('tests/test_read_agv_data.m')
```

如果这三条正常，当前阶段就算你本地验证通过。

下一步我应该做的是：

```text
写 test_evaluate_chromosome.m
```

它会把：

```text
读数据
生成一条 chrom
调用 evaluate_chromosome
检查 makespan / totalEnergy
```

串成一条你可以直接 `run(...)` 的小测试。

也就是说，下一步完成后，你才会有一个更接近“直接跑评价链路”的入口。

