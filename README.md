# Code Refactor Project

面向论文复现的调度算法整理项目。当前重点是把原始 MATLAB 代码逐步拆成清晰的数据层、调度解码层、算法层和实验复现层。

## Knowledge Base

- [数据层认知地图](docs/02_data_flow/data_layer_map.md)
- [数据层复现风险](docs/07_reproduction/data_reproduction_risks.md)

## Current Principle

- 不修改 `raw_code/`
- 小步重构
- 所有实验输出进入 `outputs/`
- 优先保证数据流清晰和实验可复现
