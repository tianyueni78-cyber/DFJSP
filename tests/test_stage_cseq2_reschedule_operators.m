clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

first = run_stage_cseq2_reschedule_operators();
second = run_stage_cseq2_reschedule_operators();
frozen = first.cseq2_frozen_problem;
population = first.cseq2_operator_population;
offspring = first.cseq2_operator_offspring;
currentView = first.next_fault_state.current_plan_view;

assert(first.is_validated);
assert(strcmp(first.step, 'C-SEQ2.9'));
assert(strcmp(first.substep, '9'));
assert(first.is_operator_contract_built);
assert(~first.is_fitness_evaluated);
assert(~first.is_search_executed_in_cseq2_step_9);
assert(~first.is_combination_evaluated);
assert(numel(population) == first.cseq2_operator_config.population_size);
assert(numel(offspring) == numel(population));
assert(isequaln(population, second.cseq2_operator_population));
assert(isequaln(offspring, second.cseq2_operator_offspring));
assert(strcmp(population(1).source, ...
    'baseline_chromosome_unstarted_suffix'));

for index = 1:numel(population)
    assert_valid_decision(population(index), first, frozen);
    assert_valid_decision(offspring(index), first, frozen);
end

candidate = decode_cseq2_candidate(currentView, frozen, offspring(1));
assert(candidate.is_validated);
assert(candidate.is_stage_c_multiple_split_operation_decoded);
assert(~candidate.is_search_executed);
assert(numel(candidate.interrupted_commitments) == 1);
assert(candidate.cumulative_repair_intervals_respected);
assert(candidate.frozen_history_repair_overlap_count >= 0);

fprintf('test_stage_cseq2_reschedule_operators passed\n');

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
    assert_integer_range(decision.machine_choice(index), 1, ...
        numel(frozen.reschedulable_operations(index).candidate_machines));
end
actualCounts = zeros(1, scenario.baseline.problem.jobNum);
for job = decision.operation_sequence
    actualCounts(job) = actualCounts(job) + 1;
end
assert(isequal(actualCounts, expectedCounts));
assert(all(decision.agv_assignment >= 1));
assert(all(decision.agv_assignment <= scenario.baseline.agvData.AGVNum));
speedCount = numel(scenario.baseline.agvData.AGVSpeed);
assert(all(decision.free_speed_choice >= 1));
assert(all(decision.free_speed_choice <= speedCount));
assert(all(decision.load_speed_choice >= 1));
assert(all(decision.load_speed_choice <= speedCount));
end

function candidate = decode_cseq2_candidate(currentView, frozen, decision)
coreFrozen = frozen;
coreFrozen.stage = 'C';
coreFrozen.step = 9;
candidate = decode_stage_c_simultaneous_complete_reschedule( ...
    currentView, coreFrozen, decision);
[candidate.cumulative_repair_intervals_respected, ...
    candidate.frozen_history_repair_overlap_count] = ...
    audit_cumulative_repairs(candidate.processing_segments, ...
    frozen.cumulative_unavailability, frozen.frozen_operations);
candidate.is_validated = candidate.is_validated && ...
    candidate.cumulative_repair_intervals_respected;
end

function [result, frozenOverlapCount] = audit_cumulative_repairs( ...
        segments, cumulative, frozenOperations)
result = cumulative.is_validated;
frozenOverlapCount = 0;
tolerance = 1e-9;
for index = 1:numel(cumulative.intervals)
    interval = cumulative.intervals(index);
    records = segments([segments.machine_id] == interval.machine_id);
    for recordIndex = 1:numel(records)
        overlaps = records(recordIndex).start < ...
            interval.end_time - tolerance && ...
            records(recordIndex).end > interval.start_time + tolerance;
        if overlaps && is_frozen_operation(records(recordIndex), frozenOperations)
            frozenOverlapCount = frozenOverlapCount + 1;
        else
            result = result && ~overlaps;
        end
    end
end
end

function result = is_frozen_operation(segment, frozenOperations)
result = any([frozenOperations.job] == segment.job & ...
    [frozenOperations.operation] == segment.operation);
end

function assert_integer_range(value, lower, upper)
assert(value == floor(value));
assert(value >= lower && value <= upper);
end
