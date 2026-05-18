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
- outputs/: generated outputs and logs

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

1. Always test on small sample data first.
2. Prefer smoke tests before full experiments.
3. Report:
   - changed files
   - purpose of changes
   - test results
   - possible risks

---

## Resource Constraints

1. Avoid loading large datasets automatically.
2. Avoid recursive scanning of huge directories.
3. Avoid generating excessive logs.
4. Minimize RAM and disk usage.

---

## If Uncertain

Stop and explain assumptions before modifying code.