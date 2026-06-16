clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_c_sequential_complete_reschedule_decode();
candidate = scenario.sequential_complete_reschedule_candidate;
frozen = scenario.sequential_frozen_problem;
tolerance = 1e-9;

assert(scenario.is_validated);
assert(scenario.step == 16);
assert(strcmp(scenario.substep, '16.2'));
assert(scenario.is_complete_reschedule_decoded);
assert(~scenario.is_search_executed_in_step_16);
assert(~scenario.is_combination_evaluated);
assert(candidate.is_validated);
assert(candidate.is_stage_c_multiple_split_operation_decoded);
assert(~candidate.is_search_executed);
assert(strcmp(candidate.decoder, ...
    'stage_c_multiple_split_operation_decoder'));
assert(numel(candidate.interrupted_commitments) == 1);

assert_frozen_operations(candidate.operation_records, frozen, tolerance);
assert_interrupted_commitments(candidate, frozen, tolerance);
assert_machine_non_overlap(candidate.processing_segments, ...
    scenario.baseline.problem.machineNum, tolerance);
assert_repair_intervals(candidate.processing_segments, ...
    frozen.repair_intervals, tolerance);
assert_job_precedence(candidate.operation_records, ...
    scenario.baseline.problem.operaNumVec, tolerance);

assert(all(candidate.job_complete_unload > 0));
assert(all(isfinite(candidate.final_agv_energy)));
assert(candidate.machine_energy >= 0);
assert(candidate.agv_energy >= 0);
assert(abs(candidate.total_energy - ...
    (candidate.machine_energy + candidate.agv_energy)) <= tolerance);

fprintf('test_stage_c_sequential_complete_reschedule_decode passed\n');

function assert_frozen_operations(operations, frozen, tolerance)
for index = 1:numel(frozen.frozen_operations)
    source = frozen.frozen_operations(index);
    target = find_operation(operations, source.job, source.operation);
    assert(target.machine_id == source.machine_id);
    assert(abs(target.start - source.start) <= tolerance);
    assert(abs(target.end - source.end) <= tolerance);
end
end

function assert_interrupted_commitments(candidate, frozen, tolerance)
operations = candidate.operation_records;
segments = candidate.processing_segments;
assert(sum([operations.is_interrupted]) == ...
    numel(frozen.interrupted_commitments));
for index = 1:numel(frozen.interrupted_commitments)
    commitment = frozen.interrupted_commitments(index);
    operation = find_operation( ...
        operations, commitment.job, commitment.operation);
    assert(operation.is_interrupted);
    assert(operation.machine_id == commitment.machine_id);
    assert(abs(operation.duration - ...
        commitment.original_duration) <= tolerance);
    assert(abs(operation.end - ...
        commitment.revised_completion_time) <= tolerance);
    assert(isequal(operation.source_event_ids, commitment.event_ids));

    selected = segments([segments.job] == commitment.job & ...
        [segments.operation] == commitment.operation);
    assert(numel(selected) == 2);
    [~, order] = sort([selected.segment_order]);
    selected = selected(order);
    assert(abs(selected(1).start - ...
        commitment.completed_segment.start) <= tolerance);
    assert(abs(selected(1).end - ...
        commitment.completed_segment.end) <= tolerance);
    assert(abs(selected(2).start - ...
        commitment.resumed_segment.start) <= tolerance);
    assert(abs(selected(2).end - ...
        commitment.resumed_segment.end) <= tolerance);
    assert(abs(sum([selected.processing_time]) - ...
        commitment.original_duration) <= tolerance);
end
end

function assert_machine_non_overlap(segments, machineCount, tolerance)
for machineId = 1:machineCount
    records = segments([segments.machine_id] == machineId);
    [~, order] = sort([records.start]);
    records = records(order);
    for index = 1:numel(records) - 1
        assert(records(index).end <= ...
            records(index + 1).start + tolerance);
    end
end
end

function assert_repair_intervals(segments, intervals, tolerance)
for intervalIndex = 1:numel(intervals)
    interval = intervals(intervalIndex);
    records = segments([segments.machine_id] == interval.machine_id);
    for recordIndex = 1:numel(records)
        overlaps = records(recordIndex).start < ...
            interval.end_time - tolerance && ...
            records(recordIndex).end > interval.start_time + tolerance;
        assert(~overlaps);
    end
end
end

function assert_job_precedence(operations, operaNumVec, tolerance)
for jobId = 1:numel(operaNumVec)
    for operationId = 1:operaNumVec(jobId) - 1
        current = find_operation(operations, jobId, operationId);
        successor = find_operation(operations, jobId, operationId + 1);
        assert(current.end <= successor.start + tolerance);
    end
end
end

function operation = find_operation(records, jobId, operationId)
match = find([records.job] == jobId & ...
    [records.operation] == operationId);
assert(numel(match) == 1);
operation = records(match);
end
