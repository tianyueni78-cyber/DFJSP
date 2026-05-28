# Evaluation Layer Wrapper Acceptance

## 1. Evaluation layer responsibility

The evaluation layer answers one question:

```text
How good is this chromosome?
```

For the current project, one chromosome is evaluated as:

```text
chrom
-> raw fitness.m
-> makespan
-> machine energy
-> AGV energy
-> total energy
-> objective vector
```

This layer does not search for new chromosomes. It only evaluates one given
chromosome.

## 2. Current entry point

The current evaluation wrapper entry point is:

```text
src/evaluation/evaluate_chromosome.m
```

Function form:

```matlab
result = evaluate_chromosome(chrom, problem, machineData, agvData, config)
```

This is a single-chromosome evaluation entry. It is not a population search
entry and it does not run NSGA-II.

## 3. Current raw dependency

The current stage is not an independent evaluation implementation.

The wrapper still depends on:

```text
raw_code/NSGA-II/fitness.m
```

The selected raw algorithm directory must be on the MATLAB path before calling
`evaluate_chromosome`.

Current wrapper behavior:

```text
check required fields
check obvious chromosome format errors
call raw fitness.m
pack raw outputs into result
```

It does not rewrite `fitness.m`, and it does not change the original algorithm
logic.

## 4. Input structures

`chrom`

```text
One chromosome row vector.
The current encoding length must be 5 * sum(problem.operaNumVec).
```

`problem`

Required fields:

```text
jobNum
jobInfo
operaNumVec
machineNum
candidateMachine
```

`machineData`

Required fields:

```text
distance_matrix
machineEnergy
```

`agvData`

Required fields:

```text
AGVNum
AGVSpeed
AGVEnergy
```

`config`

Required fields:

```text
AGVEG_MAX
AGVEG_MIN
eChargeSpeed
```

## 5. Output result structure

`evaluate_chromosome` returns a `result` struct with these fields:

```text
FUNC
objectives
makespan
machineEnergy
agvEnergy
totalEnergy
machineTable
AGVTable
agvEGRecord
agvChargeNum
```

The main objective fields are:

```text
result.objectives   [makespan, totalEnergy]
result.makespan     schedule completion time
result.totalEnergy  machineEnergy + agvEnergy
```

The schedule-table fields are passed through from raw `fitness.m`.

## 6. How to reproduce this layer

Open MATLAB in the project root:

```matlab
cd('D:\CODEX\code_refactor_project')
```

Run the smoke test:

```matlab
run('tests/test_evaluate_chromosome.m')
```

Run the invalid-case test:

```matlab
run('tests/test_evaluation_invalid_cases.m')
```

Expected successful output:

```text
test_evaluate_chromosome passed: makespan=..., totalEnergy=...
test_evaluation_invalid_cases passed
```

These tests use small sample data. They do not run full NSGA-II, medium
experiments, or formal experiments.

## 7. What passing tests mean

If the tests pass, this stage confirms:

```text
one chromosome can be evaluated through the wrapper
makespan is returned
totalEnergy is returned
missing required fields fail clearly
missing fitness.m path fails clearly
obvious bad chromosome formats fail before raw fitness.m
the wrapper does not create project-root files during the smoke test
```

Passing tests mean the raw evaluation chain is callable through a stable
wrapper. They do not mean the project has an independent evaluation
implementation.

## 8. What is not completed in this stage

This stage does not complete:

```text
independent makespan computation
independent machine energy computation
independent AGV energy computation
replacement of raw fitness.m
NSGA-II search validation
medium/formal experiment validation
metrics or plotting
```

In short:

```text
Current stage = raw fitness wrapper acceptance.
Not current stage = independent evaluation rewrite.
```

## 9. Path toward independence from raw fitness.m

To remove the dependency on raw `fitness.m`, use a separate future task.

Suggested order:

```text
1. Freeze this wrapper as the raw baseline.
2. Split makespan calculation into a small pure function.
3. Split machine energy calculation into a small pure function.
4. Split AGV energy calculation into a small pure function.
5. Build an independent objective-vector function.
6. Compare every independent output against raw fitness.m on small samples.
7. Only after those comparisons pass, consider replacing the wrapper path.
```

Do not combine that work with this wrapper acceptance stage.
