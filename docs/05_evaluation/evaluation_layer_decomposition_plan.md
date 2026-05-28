# Evaluation Layer Decomposition Plan

## 1. Purpose

This note records the first evaluation-layer decomposition after the raw
wrapper acceptance step.

The goal is to make the objective calculations understandable and testable as
small functions, while keeping the current raw `fitness.m` wrapper unchanged as
the baseline.

This stage is not a replacement for raw `fitness.m`.

## 2. What raw fitness.m does

The current raw entry is:

```text
raw_code/NSGA-II/fitness.m
```

Its responsibilities are:

```text
initialize machineTable
initialize AGVTable
call sorting
compute makespan
compute machine energy
compute AGV energy
build FUNC = {[makespan, totalEnergy]}
```

The raw chain is:

```text
chrom
-> sorting(...)
-> machineTable / AGVTable / jobCompleteUnLoad / agvEGRecord / agvChargeNum
-> makespan and energy objectives
```

## 3. Output sources

`machineTable`

```text
Created in fitness.m and filled by sorting.m.
Used later to compute machine work and idle durations.
```

`AGVTable`

```text
Created in fitness.m and filled by sorting.m.
Returned for schedule inspection, but raw AGV energy is computed from agvEGRecord.
```

`makespan`

```text
makespan = max(jobCompleteUnLoad)
```

`machineEnergy`

```text
For every finite machineTable block:
job == 0  -> idle/free duration
job ~= 0  -> work duration

machineEnergy = workRates' * workDurations + freeRates' * idleDurations
```

`agvEnergy`

```text
For every AGV battery record:
only positive drops between consecutive battery values are accumulated.
Charging increases are ignored.
```

`FUNC`

```text
FUNC = {[makespan, machineEnergy + agvEnergy]}
```

## 4. New component entries

The split evaluation helpers are:

```text
src/evaluation/compute_makespan_from_schedule.m
src/evaluation/compute_machine_energy.m
src/evaluation/compute_agv_energy.m
src/evaluation/build_objectives.m
```

Responsibilities:

```text
compute_makespan_from_schedule
    Reads schedule.jobCompleteUnLoad and returns max(jobCompleteUnLoad).

compute_machine_energy
    Reads machineTable and machineEnergy rates, then returns machine energy.

compute_agv_energy
    Reads agvEGRecord and returns accumulated AGV battery drops.

build_objectives
    Combines makespan, machine energy, and AGV energy into objective fields.
```

These helpers do not call:

```text
fitness.m
sorting.m
NSGA2.m
```

## 5. Test entries

Manual component test:

```matlab
run('tests/test_evaluation_components.m')
```

Raw-wrapper comparison test:

```matlab
run('tests/test_evaluation_components_compare_raw.m')
```

Existing wrapper tests:

```matlab
run('tests/test_evaluate_chromosome.m')
run('tests/test_evaluation_invalid_cases.m')
```

## 6. What passing tests mean

If the evaluation component tests pass, this stage confirms:

```text
makespan can be computed as a small function
machine energy can be computed as a small function
AGV energy can be computed as a small function
objectives can be built as a small function
machineEnergy / agvEnergy / totalEnergy match evaluate_chromosome outputs
```

The raw comparison test deliberately uses `evaluate_chromosome` as the current
baseline. This keeps the decomposition aligned with raw `fitness.m`.

## 7. What is not completed

This stage does not:

```text
replace raw fitness.m
replace raw sorting.m
run full NSGA-II
validate medium/formal experiments
implement independent search
implement metrics or plots
```

The current stage only splits objective calculations into testable helper
functions.

## 8. Future path

To fully detach from raw `fitness.m`, continue in small steps:

```text
1. Keep evaluate_chromosome as the raw baseline.
2. Use decoded schedules as inputs to the new component helpers.
3. Add compare tests for every future independent evaluation entry.
4. Replace the raw fitness wrapper only after all component comparisons pass.
```
