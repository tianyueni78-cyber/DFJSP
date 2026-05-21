# 工作规则

1. 不允许修改 raw_code
2. 每次只完成一个小任务
3. 不允许一次性重构全部项目
4. 不允许删除文件
5. 不允许写死绝对路径
6. 所有输出写入 outputs
7. 优先保证可复现
8. 不确定时先分析，不要猜测
 # AI Coding Agent Rules

## Core Principles

1. Preserve reproducibility above all else.
2. Do not refactor unrelated code.
3. Do not change algorithm logic unless explicitly requested.
4. Prefer clarity and stability over abstraction.
5. Avoid over-engineering.

---

## File Safety Rules

1. Never modify files in raw_code/.
2. Never delete files automatically.
3. Never overwrite outputs without confirmation.
4. Use relative paths only.
5. Do not hardcode local machine paths.

---

## Project Structure

- raw_code/: original archived code
- src/: refactored production code
- data_sample/: minimal runnable datasets
- configs/: yaml configuration files
- tests/: lightweight reproducibility tests
- outputs/: generated outputs and logs—outputs/：生成的输出和日志

---

## Refactoring Rules

1. Refactor incrementally.
2. One module at a time.
3. Separate:
   - data loading
   - preprocessing
   - algorithm
   - evaluation
4. Keep function names understandable.
5. Avoid unnecessary class abstractions.

---

## Testing Rules

1. Always test on small sample data first.1. 总是先在小样本数据上进行测试。
2. Prefer smoke tests before full experiments.2. 在全面实验之前更喜欢烟雾测试。
3. Report:   3. 报告:
   - changed files   -更改的文件
   - purpose of changes   -更改的目的
   - test results   -测试结果
   - possible risks   -可能的风险

---

## Resource Constraints   ##资源约束

1. Avoid loading large datasets automatically.1. 避免自动加载大型数据集。
2. Avoid recursive scanning of huge directories.2. 避免对大目录进行递归扫描。
3. Avoid generating excessive logs.3. 避免产生过多的日志。
4. Minimize RAM and disk usage.4. 尽量减少RAM和磁盘的使用。

---

## If Uncertain   ##如果不确定

Stop and explain assumptions before modifying code.在修改代码之前停止并解释假设。

## Time Limits

- Do not run for more than 5 minutes without reporting progress.—请勿运行超过5分钟而不报告进度。
- If a task exceeds 10 minutes, stop immediately and summarize findings.—如果一个任务超过10分钟，立即停止并总结发现。
- Avoid long-running loops, retries, or recursive analysis.—避免长时间循环、重试或递归分析。

## Scope Control   ##范围控制

- Do not expand the task beyond the user's explicit request.—不要超出用户的明确要求扩展任务。
- Do not autonomously redesign the architecture.-不要自主地重新设计架构。
- Do not recursively inspect unrelated files.—不要递归检查不相关的文件。
- Do not attempt global optimization unless explicitly requested.-除非明确要求，否则不要尝试全局优化。

## Execution Policy   ##执行策略

- Static analysis only by default.—默认为静态分析。
- Ask for confirmation before:-在以下情况前要求确认：
  - running MATLAB   -运行MATLAB
  - launching experiments   -开展实验
  - generating outputs   -生成输出
  - editing multiple files
