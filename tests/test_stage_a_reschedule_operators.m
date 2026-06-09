clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

scenario = run_stage_a_reschedule_operators();
population = scenario.operator_population;
offspring = scenario.operator_offspring;

assert(~scenario.is_search_executed);
assert(~scenario.is_rescheduled);
assert(numel(population) == 6);
assert(numel(offspring) == numel(population));
assert(strcmp(population(1).source, ...
    'baseline_chromosome_unstarted_suffix'));

assert_population_valid(population, scenario);
assert_population_valid(offspring, scenario);

for index = 1:numel(offspring)
    candidate = decode_stage_a_complete_reschedule( ...
        scenario.baseline, scenario.frozen_problem, offspring(index));
    assert(candidate.is_validated);
    assert(~candidate.is_search_executed);
end

fprintf('test_stage_a_reschedule_operators passed\n');

function assert_population_valid(population, scenario)
frozen = scenario.frozen_problem;
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
        upper = numel( ...
            frozen.reschedulable_operations(index).candidate_machines);
        assert_integer_range(decision.machine_choice(index), 1, upper);
        assert_integer_range(decision.agv_assignment(index), ...
            1, scenario.baseline.agvData.AGVNum);
        assert_integer_range(decision.free_speed_choice(index), ...
            1, speedCount);
        assert_integer_range(decision.load_speed_choice(index), ...
            1, speedCount);
    end
end
end

function assert_integer_range(value, lower, upper)
assert(value == floor(value));
assert(value >= lower && value <= upper);
end
