clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

scenario = run_stage_cs2_complete_reschedule_decode();
candidate = scenario.complete_reschedule_candidate;
frozen = scenario.cs2_frozen_problem;
tolerance = 1e-9;

assert(scenario.is_validated);
assert(strcmp(scenario.step, 'C-S2.7'));
assert(strcmp(scenario.substep, '7'));
assert(scenario.is_complete_reschedule_decoded);
assert(~scenario.is_search_executed);
assert(candidate.is_validated);
assert(candidate.is_stage_cs2_multiple_restart_operation_decoded);
assert(~candidate.is_search_executed);
assert(strcmp(candidate.decoder, ...
    'stage_cs2_multiple_restart_operation_decoder'));
assert(numel(candidate.interrupted_commitments) >= 2);

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

fprintf(['test_stage_cs2_complete_reschedule_decode ', ...
    'passed\n']);

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
    assert(operation.restart_from_zero);
    assert(~operation.progress_preserved);
    assert(abs(operation.lost_processing_time - ...
        commitment.lost_processing_time) <= tolerance);
    assert(abs(operation.total_machine_processing_time - ...
        commitment.total_machine_processing_time) <= tolerance);
    assert(isequal(operation.source_event_ids, commitment.event_ids));

    selected = segments([segments.job] == commitment.job & ...
        [segments.operation] == commitment.operation);
    assert(numel(selected) == 2);
    [~, order] = sort([selected.segment_order]);
    selected = selected(order);
    assert(strcmp(selected(1).segment_type, ...
        'lost_processing_before_fault'));
    assert(strcmp(selected(2).segment_type, ...
        'restart_after_repair'));
    assert(abs(selected(1).start - ...
        commitment.lost_processing_segment.start) <= tolerance);
    assert(abs(selected(1).end - ...
        commitment.lost_processing_segment.end) <= tolerance);
    assert(abs(selected(2).start - ...
        commitment.restart_segment.start) <= tolerance);
    assert(abs(selected(2).end - ...
        commitment.restart_segment.end) <= tolerance);
    assert(abs(sum([selected.processing_time]) - ...
        commitment.total_machine_processing_time) <= tolerance);
    assert(abs(selected(1).processing_time - ...
        commitment.lost_processing_time) <= tolerance);
    assert(abs(selected(2).processing_time - ...
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
