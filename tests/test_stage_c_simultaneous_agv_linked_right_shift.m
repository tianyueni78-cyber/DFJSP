clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

scenario = run_stage_c_simultaneous_agv_linked_right_shift();
candidate = scenario.linked_right_shift;
tolerance = 1e-9;

assert(scenario.is_validated);
assert(scenario.step == 8);
assert(scenario.is_agv_rescheduled);
assert(scenario.is_fully_validated);
assert(candidate.is_machine_validated);
assert(candidate.is_agv_validated);
assert(candidate.is_fully_validated);
assert(isequaln(scenario.baseline.AGVTable, ...
    scenario.machine_right_shift.AGVTable));
assert(numel(candidate.interrupted_commitments) == ...
    numel(scenario.faults));

roots = candidate.operation_records( ...
    [candidate.operation_records.is_interrupted]);
assert(numel(roots) == numel(candidate.interrupted_commitments));
for index = 1:numel(candidate.interrupted_commitments)
    commitment = candidate.interrupted_commitments(index);
    root = roots([roots.job] == commitment.job & ...
        [roots.operation] == commitment.operation);
    assert(numel(root) == 1);
    assert(abs(root.start - commitment.original_start) <= tolerance);
    assert(abs(root.end - ...
        commitment.revised_completion_time) <= tolerance);
    segments = candidate.processing_segments( ...
        [candidate.processing_segments.job] == commitment.job & ...
        [candidate.processing_segments.operation] == ...
        commitment.operation);
    assert(numel(segments) == 2);
    assert(any(strcmp({segments.segment_type}, ...
        'processed_before_fault')));
    assert(any(strcmp({segments.segment_type}, ...
        'resumed_after_repair')));
end

for index = 1:numel(candidate.agv_activity_records)
    activity = candidate.agv_activity_records(index);
    assert(activity.start + tolerance >= activity.original_start);
    assert(abs((activity.end - activity.start) - ...
        activity.duration) <= tolerance);
    if activity.is_frozen
        assert(abs(activity.start - ...
            activity.original_start) <= tolerance);
        assert(abs(activity.end - ...
            activity.original_end) <= tolerance);
    end
end

assert_agv_non_overlap(candidate.agv_activity_records, tolerance);
assert_transport_constraints(candidate, ...
    scenario.baseline.problem.operaNumVec, tolerance);
assert_machine_segments(candidate.processing_segments, ...
    scenario.faults, tolerance);
assert_final_unloads(candidate, ...
    scenario.baseline.problem.operaNumVec, tolerance);

if scenario.agv_impact.requires_agv_adjustment
    assert(candidate.is_agv_updated);
end
validationValues = struct2cell(candidate.validation);
assert(all(cellfun(@(value) isequal(value, true), validationValues)));

reversed = build_stage_c_simultaneous_agv_linked_right_shift( ...
    scenario.baseline, scenario.faults(end:-1:1), ...
    scenario.machine_right_shift, scenario.agv_impact);
assert(isequaln(candidate.operation_records, ...
    reversed.operation_records));
assert(isequaln(candidate.agv_activity_records, ...
    reversed.agv_activity_records));
assert(isequaln(candidate.machineTable, reversed.machineTable));
assert(isequaln(candidate.AGVTable, reversed.AGVTable));

fprintf('test_stage_c_simultaneous_agv_linked_right_shift passed\n');

function assert_agv_non_overlap(activities, tolerance)
for agvId = unique([activities.agv_id])
    records = activities([activities.agv_id] == agvId);
    [~, order] = sort([records.original_table_index]);
    records = records(order);
    for index = 1:numel(records) - 1
        assert(records(index).end <= ...
            records(index + 1).start + tolerance);
    end
end
end

function assert_transport_constraints(candidate, operaNumVec, tolerance)
operations = candidate.operation_records;
activities = candidate.agv_activity_records;
for job = 1:numel(operaNumVec)
    for operation = 1:operaNumVec(job)
        task = find_operation(operations, job, operation);
        transport = find([activities.job] == job & ...
            [activities.operation] == operation & ...
            [activities.load_status] == -2);
        if isempty(transport)
            continue
        end
        assert(numel(transport) == 1);
        assert(activities(transport).end <= task.start + tolerance);
        if operation > 1
            predecessor = find_operation( ...
                operations, job, operation - 1);
            assert(activities(transport).start + tolerance >= ...
                predecessor.end);
        end
    end
end
end

function assert_machine_segments(segments, faults, tolerance)
for machineId = unique([segments.machine_id])
    records = segments([segments.machine_id] == machineId);
    [~, order] = sort([records.start]);
    records = records(order);
    for index = 1:numel(records) - 1
        assert(records(index).end <= ...
            records(index + 1).start + tolerance);
    end
end
for faultIndex = 1:numel(faults)
    fault = faults(faultIndex);
    records = segments([segments.machine_id] == fault.machine_id);
    for index = 1:numel(records)
        overlap = records(index).start < ...
            fault.repair_end_time - tolerance && ...
            fault.start_time < records(index).end - tolerance;
        assert(~overlap);
    end
end
end

function assert_final_unloads(candidate, operaNumVec, tolerance)
for job = 1:numel(operaNumVec)
    finalOperation = find_operation(candidate.operation_records, ...
        job, operaNumVec(job));
    unload = find([candidate.agv_activity_records.job] == job & ...
        [candidate.agv_activity_records.operation] == -1 & ...
        [candidate.agv_activity_records.load_status] == -2);
    assert(numel(unload) == 1);
    assert(candidate.agv_activity_records(unload).start + ...
        tolerance >= finalOperation.end);
end
end

function operation = find_operation(records, job, operationId)
match = find([records.job] == job & ...
    [records.operation] == operationId);
assert(numel(match) == 1);
operation = records(match);
end
