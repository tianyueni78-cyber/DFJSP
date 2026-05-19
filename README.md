# Code Refactor Project

面向论文复现的调度算法整理项目。当前重点是把原始 MATLAB 代码逐步拆成清晰的数据层、调度解码层、算法层和实验复现层。

## Knowledge Base

- [知识地图工作表](docs/00_system_overview/knowledge_map_workplan.md)
- [项目文件导览：每个板块是干什么的](docs/00_system_overview/repository_file_guide.md)
- [项目易读版：这套代码到底在做什么](docs/00_system_overview/beginner_reading_guide.md)
- [系统五层认知结构](docs/00_system_overview/system_layer_architecture.md)
- [数据层认知地图](docs/02_data_flow/data_layer_map.md)
- [搜索层：基础搜索机制](docs/03_algorithm/search_layer_overview.md)
- [调度解码层：sorting.m 的系统作用](docs/04_decoding/decoding_layer_overview.md)
- [评价层：调度方案如何被评价](docs/05_evaluation/evaluation_layer_overview.md)
- [实验流程：dif_main.m 和 same_main.m 在跑什么](docs/06_experiments/experiment_flow.md)
- [复现步骤说明](docs/07_reproduction/reproduction_steps/README.md)
- [数据层复现风险](docs/07_reproduction/data_reproduction_risks.md)
- [复现与封装路线：遇到问题时怎么办](docs/08_engineering/refactor_roadmap.md)

## Current Principle

- 不修改 `raw_code/`
- 小步重构
- 所有实验输出进入 `outputs/`
- 优先保证数据流清晰和实验可复现
