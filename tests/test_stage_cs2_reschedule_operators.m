clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

first = run_stage_cs2_reschedule_operators();
second = run_stage_cs2_reschedule_operators();

assert(first.is_validated);
assert(strcmp(first.step, 'C-S2.8'));
assert(strcmp(first.substep, '8'));
assert(first.is_operator_contract_built);
assert(~first.is_fitness_evaluated);
assert(~first.is_search_executed);
assert(~first.is_rescheduled);
assert(numel(first.operator_population) == ...
    first.operator_config.population_size);
assert(numel(first.operator_offspring) == ...
    first.operator_config.population_size);
assert(isequaln(first.operator_population, ...
    second.operator_population));
assert(isequaln(first.operator_offspring, ...
    second.operator_offspring));
assert(strcmp(first.operator_population(1).source, ...
    'baseline_chromosome_unstarted_suffix'));

assert_population_valid(first.operator_population, first);
assert_population_valid(first.operator_offspring, first);
assert_population_decodable(first.operator_population, first);
assert_population_decodable(first.operator_offspring, first);

fprintf('test_stage_cs2_reschedule_operators passed\n');

function assert_population_valid(population, scenario)
frozen = scenario.cs2_frozen_problem;
expectedJobs = sort([frozen.reschedulable_operations.job]);
operationCount = numel(frozen.reschedulable_operations);
speedCount = numel(scenario.baseline.agvData.AGVSpeed);

for individual = 1:numel(population)
    decision = population(individual);
    assert(numel(decision.operation_sequence) == operationCount);
    assert(isequal(sort(decision.operation_sequence), expectedJobs));
    assert(numel(decision.machine_choice) == operationCount);
    assert(numel(decision.agv_assignment) == operationCount);
    assert(numel(decision.free_speed_choice) == operationCount);
    assert(numel(decision.load_speed_choice) == operationCount);

    for index = 1:operationCount
        machineCount = numel( ...
            frozen.reschedulable_operations(index).candidate_machines);
        assert_integer_range( ...
            decision.machine_choice(index), 1, machineCount);
        assert_integer_range(decision.agv_assignment(index), ...
            1, scenario.baseline.agvData.AGVNum);
        assert_integer_range(decision.free_speed_choice(index), ...
            1, speedCount);
        assert_integer_range(decision.load_speed_choice(index), ...
            1, speedCount);
    end
end
end

function assert_population_decodable(population, scenario)
expectedSegmentCount = ...
    sum(scenario.baseline.problem.operaNumVec) + ...
    numel(scenario.cs2_frozen_problem.interrupted_commitments);
for index = 1:numel(population)
    candidate = decode_stage_cs2_complete_reschedule( ...
        scenario.baseline, scenario.cs2_frozen_problem, population(index));
    assert(candidate.is_validated);
    assert(candidate.is_stage_cs2_multiple_restart_operation_decoded);
    assert(~candidate.is_search_executed);
    assert(numel(candidate.processing_segments) == ...
        expectedSegmentCount);
    assert(candidate.validation.all_repair_intervals_respected);
    assert(candidate.validation.multiple_interrupted_operations_preserved);
end
end

function assert_integer_range(value, lower, upper)
assert(value == floor(value));
assert(value >= lower && value <= upper);
end
