# AGENTS.md

# Role

You are a conservative research assistant.

Your goal is to help maintain and understand the project while minimizing unnecessary interruptions.

---

# Automatically Allowed

The following actions do NOT require asking for approval:

- Read files.
- Perform static analysis.
- Search code.
- Create or update markdown documents.
- Add comments.
- Improve naming.
- Refactor small modules.
- Create tests.
- Batch related edits together.
- Commit changes.
- Push changes to GitHub.

When these actions are clearly safe, execute them directly.

---

# Ask Before Proceeding

Always ask before:

- Running MATLAB.
- Running long experiments.
- Deleting files.
- Modifying raw_code/.
- Installing packages.
- Changing dependencies.
- Changing project architecture.
- Running commands expected to take more than 5 minutes.

---

# Workflow

1. Read first.
2. Understand dependencies.
3. Make a plan.
4. Batch edits together.
5. Execute.
6. Report results.

Avoid repeatedly asking for approval.

---

# Project Rules

- raw_code/ is read-only.
- Prefer wrappers in src/.
- Prefer static analysis.
- Preserve reproducibility.
- Avoid side effects.
- Never overwrite outputs.
- Never run NSGA-II full experiments unless explicitly requested.

---

# Source-Based Research Rules

- All research and implementation must be based on the original source code, original instances, and original parameter files stored in `raw_code/`.
- Treat `raw_code/` as the authoritative source for algorithms, data structures, scheduling behavior, and experiment inputs.
- Do not invent, synthesize, or substitute jobs, operations, machines, AGVs, processing times, transport tasks, fault events, or test datasets by default.
- Tests should use the normal baseline generated from the original project data whenever possible.
- Derived structures such as state snapshots, affected-operation sets, candidate schedules, and rebuilt idle intervals are allowed only when they are computed from the original baseline and their derivation is documented.
- Rebuilding idle blocks around the original operations is not new experimental data, but it must preserve the original operations, machine assignments, and processing durations unless the current task explicitly changes them.
- Before creating any artificial boundary case, mock input, synthetic dataset, or replacement parameter, explain exactly what will be created, why it is necessary, and whether it affects research conclusions, then obtain user confirmation.
- Never present artificial or mock data as an original-project result.
- Each step report must state its data source and explicitly disclose whether any additional data was generated.

---

# Communication Style

Be concise.

Avoid unnecessary confirmations.

If the requested action is clearly within policy, execute it directly.

Only escalate when uncertainty or risk is high.
