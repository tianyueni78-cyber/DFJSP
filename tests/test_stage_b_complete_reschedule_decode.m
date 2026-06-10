clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_b_complete_reschedule_decode();
candidate = scenario.complete_reschedule_candidate;
frozen = scenario.frozen_problem;
tolerance = 1e-9;

assert(scenario.is_validated);
assert(scenario.step == 8);
assert(scenario.is_complete_reschedule_decoded);
assert(~scenario.is_search_executed);
assert(candidate.is_validated);
assert(candidate.is_stage_b_split_operation_decoded);
assert(strcmp(candidate.decoder, ...
    'stage_b_split_operation_decoder'));
assert(strcmp(candidate.stage, 'B'));
assert(candidate.step == 8);

assert(numel(candidate.operation_records) == ...
    sum(scenario.baseline.problem.operaNumVec));
assert_frozen_preserved(candidate.operation_records, ...
    frozen.frozen_operations, tolerance);
assert_interrupted_commitment(candidate, ...
    frozen.interrupted_commitment, tolerance);
assert_rescheduled_sources(candidate.operation_records, ...
    frozen.reschedulable_operations, tolerance);
assert_machine_segments(candidate.processing_segments, tolerance);
assert_job_constraints(candidate.operation_records, ...
    scenario.baseline.problem.operaNumVec, tolerance);
assert_transport_constraints(candidate, tolerance);

assert(all(candidate.job_complete_unload > 0));
assert(candidate.makespan == max(candidate.job_complete_unload));
assert(candidate.machine_energy >= 0);
assert(candidate.agv_energy >= 0);
assert(abs(candidate.total_energy - ...
    (candidate.machine_energy + candidate.agv_energy)) <= tolerance);
assert(all(isfinite(candidate.final_agv_energy)));

fprintf('test_stage_b_complete_reschedule_decode passed\n');

function assert_frozen_preserved(records, frozen, tolerance)
for index = 1:numel(frozen)
    match = find([records.job] == frozen(index).job & ...
        [records.operation] == frozen(index).operation);
    assert(numel(match) == 1);
    assert(records(match).machine_id == frozen(index).machine_id);
    assert(abs(records(match).start - frozen(index).start) <= tolerance);
    assert(abs(records(match).end - frozen(index).end) <= tolerance);
end
end

function assert_interrupted_commitment(candidate, commitment, tolerance)
operation = find_operation(candidate.operation_records, ...
    commitment.job, commitment.operation);
assert(operation.is_interrupted);
assert(strcmp(operation.status, 'interrupted_committed'));
assert(operation.machine_id == commitment.machine_id);
assert(abs(operation.duration - commitment.original_duration) <= ...
    tolerance);
assert((operation.end - operation.start) > operation.duration);

segments = candidate.processing_segments( ...
    [candidate.processing_segments.job] == commitment.job & ...
    [candidate.processing_segments.operation] == commitment.operation);
assert(numel(segments) == 2);
[~, order] = sort([segments.segment_order]);
segments = segments(order);
assert(abs(segments(1).end - ...
    commitment.completed_segment.end) <= tolerance);
assert(abs(segments(2).start - ...
    commitment.resumed_segment.start) <= tolerance);
assert(abs(sum([segments.processing_time]) - ...
    commitment.original_duration) <= tolerance);
end

function assert_rescheduled_sources(records, sources, tolerance)
for index = 1:numel(sources)
    operation = find_operation(records, ...
        sources(index).job, sources(index).operation);
    assert(strcmp(operation.status, 'rescheduled'));
    position = find(sources(index).candidate_machines == ...
        operation.machine_id);
    assert(numel(position) == 1);
    assert(abs(operation.duration - ...
        sources(index).processing_times(position)) <= tolerance);
end
end

function assert_machine_segments(segments, tolerance)
for machineId = unique([segments.machine_id])
    records = segments([segments.machine_id] == machineId);
    [~, order] = sort([records.start]);
    records = records(order);
    for index = 1:numel(records) - 1
        assert(records(index).end <= ...
            records(index + 1).start + tolerance);
    end
end
end

function assert_job_constraints(records, operaNumVec, tolerance)
for jobId = 1:numel(operaNumVec)
    for operationId = 1:operaNumVec(jobId) - 1
        current = find_operation(records, jobId, operationId);
        successor = find_operation(records, jobId, operationId + 1);
        assert(current.end <= successor.start + tolerance);
    end
end
end

function assert_transport_constraints(candidate, tolerance)
for index = 1:numel(candidate.transport_records)
    transport = candidate.transport_records(index);
    if transport.load_status ~= -2
        continue
    end
    if transport.operation == -1
        operations = candidate.operation_records( ...
            [candidate.operation_records.job] == transport.job);
        [~, last] = max([operations.operation]);
        assert(transport.start + tolerance >= operations(last).end);
    else
        operation = find_operation(candidate.operation_records, ...
            transport.job, transport.operation);
        assert(transport.end <= operation.start + tolerance);
    end
end
end

function operation = find_operation(records, jobId, operationId)
match = find([records.job] == jobId & ...
    [records.operation] == operationId);
assert(numel(match) == 1);
operation = records(match);
end
