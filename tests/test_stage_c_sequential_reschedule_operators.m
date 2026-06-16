clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

first = run_stage_c_sequential_reschedule_operators();
second = run_stage_c_sequential_reschedule_operators();
frozen = first.sequential_frozen_problem;
population = first.sequential_operator_population;
offspring = first.sequential_operator_offspring;

assert(first.is_validated);
assert(first.step == 16);
assert(strcmp(first.substep, '16.3a'));
assert(first.is_operator_contract_built);
assert(~first.is_fitness_evaluated);
assert(~first.is_search_executed_in_step_16);
assert(~first.is_combination_evaluated);
assert(numel(population) == ...
    first.sequential_operator_config.population_size);
assert(numel(offspring) == numel(population));
assert(isequaln(population, second.sequential_operator_population));
assert(isequaln(offspring, second.sequential_operator_offspring));

for index = 1:numel(population)
    assert_valid_decision(population(index), first, frozen);
    assert_valid_decision(offspring(index), first, frozen);
end

candidate = decode_stage_c_simultaneous_complete_reschedule( ...
    first.next_fault_state.current_plan_view, frozen, offspring(1));
assert(candidate.is_validated);
assert(numel(candidate.interrupted_commitments) == 1);

fprintf('test_stage_c_sequential_reschedule_operators passed\n');

function assert_valid_decision(decision, scenario, frozen)
operationCount = numel(frozen.reschedulable_operations);
assert(numel(decision.operation_sequence) == operationCount);
assert(numel(decision.machine_choice) == operationCount);
assert(numel(decision.agv_assignment) == operationCount);
assert(numel(decision.free_speed_choice) == operationCount);
assert(numel(decision.load_speed_choice) == operationCount);

expectedCounts = zeros(1, scenario.baseline.problem.jobNum);
for index = 1:operationCount
    job = frozen.reschedulable_operations(index).job;
    expectedCounts(job) = expectedCounts(job) + 1;
    assert(decision.machine_choice(index) >= 1);
    assert(decision.machine_choice(index) <= ...
        numel(frozen.reschedulable_operations(index).candidate_machines));
end
actualCounts = zeros(1, scenario.baseline.problem.jobNum);
for job = decision.operation_sequence
    actualCounts(job) = actualCounts(job) + 1;
end
assert(isequal(actualCounts, expectedCounts));
assert(all(decision.agv_assignment >= 1));
assert(all(decision.agv_assignment <= ...
    scenario.baseline.agvData.AGVNum));
speedCount = numel(scenario.baseline.agvData.AGVSpeed);
assert(all(decision.free_speed_choice >= 1));
assert(all(decision.free_speed_choice <= speedCount));
assert(all(decision.load_speed_choice >= 1));
assert(all(decision.load_speed_choice <= speedCount));
end
