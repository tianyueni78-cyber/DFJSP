clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

scenario = run_stage_cs2_agv_linked_right_shift();
candidate = scenario.cs2_linked_right_shift;
tolerance = 1e-9;

assert(scenario.is_validated);
assert(strcmp(scenario.extension, 'C-S2'));
assert(strcmp(scenario.step, 'C-S2.5'));
assert(scenario.is_agv_rescheduled);
assert(scenario.is_fully_validated);
assert(candidate.is_machine_validated);
assert(candidate.is_agv_validated);
assert(candidate.is_fully_validated);
assert(strcmp(candidate.stage, 'C-S2'));
assert(candidate.step == 5);
assert(strcmp(candidate.interruption_rule, 'restart_from_zero'));
assert(candidate.restart_from_zero);
assert(~candidate.progress_preserved);
assert(strcmp(candidate.adapted_core, ...
    'build_stage_c_simultaneous_agv_linked_right_shift'));
assert(isequaln(scenario.baseline.AGVTable, ...
    scenario.cs2_machine_right_shift.AGVTable));

assert(abs(candidate.lost_processing_time - ...
    scenario.cs2_machine_right_shift.lost_processing_time) <= tolerance);
assert(numel(candidate.interrupted_commitments) == ...
    numel(scenario.cs2_restart_commitments));
assert(numel(candidate.agv_activity_records) > 0);

for index = 1:numel(scenario.cs2_restart_commitments)
    commitment = scenario.cs2_restart_commitments(index);
    root = candidate.operation_records( ...
        [candidate.operation_records.job] == commitment.job & ...
        [candidate.operation_records.operation] == ...
        commitment.operation);
    assert(numel(root) == 1);
    assert(root.is_interrupted);
    assert(root.is_restart_from_zero);
    assert(abs(root.start - commitment.original_start) <= tolerance);
    assert(abs(root.end - ...
        commitment.revised_completion_time) <= tolerance);

    segments = candidate.processing_segments( ...
        [candidate.processing_segments.job] == commitment.job & ...
        [candidate.processing_segments.operation] == ...
        commitment.operation);
    assert(numel(segments) == 2);
    [~, order] = sort([segments.segment_order]);
    segments = segments(order);
    assert(strcmp(segments(1).segment_type, ...
        'lost_processing_before_fault'));
    assert(strcmp(segments(2).segment_type, ...
        'restart_after_repair'));
    assert(~segments(1).contributes_to_completion);
    assert(segments(2).contributes_to_completion);
    assert(abs(segments(1).processing_time - ...
        commitment.lost_processing_time) <= tolerance);
    assert(abs(segments(2).processing_time - ...
        commitment.original_duration) <= tolerance);
end

for index = 1:numel(candidate.agv_activity_records)
    activity = candidate.agv_activity_records(index);
    original = scenario.baseline.AGVTable{activity.agv_id}( ...
        activity.original_table_index);
    assert(activity.job == original.job);
    assert(activity.operation == original.opera);
    assert(activity.load_status == original.load_status);
    assert(activity.from_machine == original.from_machine);
    assert(activity.to_machine == original.to_machine);
    assert(activity.charge == original.charge);
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

if scenario.cs2_agv_impact.requires_agv_adjustment
    assert(candidate.is_agv_updated);
end
validationValues = struct2cell(candidate.validation);
assert(all(cellfun(@(value) isequal(value, true), validationValues)));

reversed = build_stage_cs2_agv_linked_right_shift( ...
    scenario.baseline, scenario.faults(end:-1:1), ...
    scenario.cs2_machine_right_shift, scenario.cs2_agv_impact);
assert(isequaln(candidate.operation_records, ...
    reversed.operation_records));
assert(isequaln(candidate.agv_activity_records, ...
    reversed.agv_activity_records));
assert(isequaln(candidate.machineTable, reversed.machineTable));
assert(isequaln(candidate.AGVTable, reversed.AGVTable));

fprintf('test_stage_cs2_agv_linked_right_shift passed\n');

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
for jobId = 1:numel(operaNumVec)
    for operationId = 1:operaNumVec(jobId)
        operation = find_operation(operations, jobId, operationId);
        transport = find([activities.job] == jobId & ...
            [activities.operation] == operationId & ...
            [activities.load_status] == -2);
        if ~isempty(transport)
            assert(numel(transport) == 1);
            assert(activities(transport).end <= ...
                operation.start + tolerance);
            if operationId > 1
                predecessor = find_operation( ...
                    operations, jobId, operationId - 1);
                assert(activities(transport).start + tolerance >= ...
                    predecessor.end);
            end
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
for jobId = 1:numel(operaNumVec)
    finalOperation = find_operation(candidate.operation_records, ...
        jobId, operaNumVec(jobId));
    unload = find([candidate.agv_activity_records.job] == jobId & ...
        [candidate.agv_activity_records.operation] == -1 & ...
        [candidate.agv_activity_records.load_status] == -2);
    assert(numel(unload) == 1);
    assert(candidate.agv_activity_records(unload).start + ...
        tolerance >= finalOperation.end);
end
end

function operation = find_operation(records, jobId, operationId)
match = find([records.job] == jobId & ...
    [records.operation] == operationId);
assert(numel(match) == 1);
operation = records(match);
end
