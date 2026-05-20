# Code Refactor Project

面向论文复现的调度算法整理项目。当前重点是把原始 MATLAB 代码逐步拆成清晰的数据层、调度解码层、算法层和实验复现层。

## Knowledge Base

- [知识地图工作表](docs/00_system_overview/knowledge_map_workplan.md)
- [项目入口地图：我想做一件事时该打开哪里](docs/00_system_overview/entrypoint_map.md)
- [项目文件导览：每个板块是干什么的](docs/00_system_overview/repository_file_guide.md)
- [项目易读版：这套代码到底在做什么](docs/00_system_overview/beginner_reading_guide.md)
- [系统五层认知结构](docs/00_system_overview/system_layer_architecture.md)
- [数据层认知地图](docs/02_data_flow/data_layer_map.md)
- [搜索层：基础搜索机制](docs/03_algorithm/search_layer_overview.md)
- [调度解码层：sorting.m 的系统作用](docs/04_decoding/decoding_layer_overview.md)
- [评价层：调度方案如何被评价](docs/05_evaluation/evaluation_layer_overview.md)
- [实验流程：dif_main.m 和 same_main.m 在跑什么](docs/06_experiments/experiment_flow.md)
- [复现步骤说明](docs/07_reproduction/reproduction_steps/README.md)
  - [MATLAB 复现命令清单](docs/07_reproduction/reproduction_steps/matlab_command_cheatsheet.md)
  - [现在这套封装怎么跑](docs/07_reproduction/reproduction_steps/00_how_to_run_current_stage.md)
  - [第 1 步：数据读取封装](docs/07_reproduction/reproduction_steps/01_data_reading.md)
  - [第 2 步：fitness/sorting 最小调用链](docs/07_reproduction/reproduction_steps/02_fitness_sorting_call_chain.md)
  - [第 3 步：单条染色体评价入口](docs/07_reproduction/reproduction_steps/03_single_chromosome_evaluation.md)
  - [第 4 步：单条评价运行脚本](docs/07_reproduction/reproduction_steps/04_run_single_evaluation_script.md)
  - [第 5 步：小种群短迭代](docs/07_reproduction/reproduction_steps/05_run_small_nsga2.md)
  - [第 6 步：配置化 small_nsga2](docs/07_reproduction/reproduction_steps/06_config_small_nsga2.md)
  - [第 7 步：数据与配置扩展准备](docs/07_reproduction/reproduction_steps/07_data_config_extension.md)
  - [第 8 步：配置入口测试](docs/07_reproduction/reproduction_steps/08_config_entry_test.md)
  - [第 9 步：小幅放大参数运行](docs/07_reproduction/reproduction_steps/09_medium_nsga2_run.md)
  - [第 10 步：运行入口分层整理](docs/07_reproduction/reproduction_steps/10_reproduction_entry_layers.md)
  - [第 11 步：阶段总结与下一阶段路线](docs/07_reproduction/reproduction_steps/11_stage_summary_next_routes.md)
  - [第 12 步：outputs 输出结构整理](docs/07_reproduction/reproduction_steps/12_outputs_structure.md)
  - [第 13 步：运行日志与参数记录设计](docs/07_reproduction/reproduction_steps/13_run_log_and_parameter_record.md)
  - [第 14 步：正式实验入口设计](docs/07_reproduction/reproduction_steps/14_formal_experiment_entry_design.md)
  - [第 15 步：正式实验配置设计](docs/07_reproduction/reproduction_steps/15_formal_config_design.md)
- [数据层复现风险](docs/07_reproduction/data_reproduction_risks.md)
- [复现与封装路线：遇到问题时怎么办](docs/08_engineering/refactor_roadmap.md)

## Current Principle

- 不修改 `raw_code/`
- 小步重构
- 所有实验输出进入 `outputs/`
- 优先保证数据流清晰和实验可复现
