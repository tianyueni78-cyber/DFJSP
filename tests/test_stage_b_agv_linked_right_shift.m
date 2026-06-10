clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_b_agv_linked_right_shift();
candidate = scenario.linked_right_shift;
tolerance = 1e-9;

assert(scenario.is_validated);
assert(scenario.step == 6);
assert(scenario.is_agv_rescheduled);
assert(scenario.is_fully_validated);
assert(candidate.is_machine_validated);
assert(candidate.is_agv_validated);
assert(candidate.is_fully_validated);
assert(isequaln(scenario.baseline.AGVTable, ...
    scenario.machine_right_shift.AGVTable));

root = candidate.operation_records( ...
    [candidate.operation_records.is_interrupted]);
assert(numel(root) == 1);
assert(abs(root.start - scenario.resume_plan.original_start) <= tolerance);
assert(abs(root.end - ...
    scenario.resume_plan.revised_completion_time) <= tolerance);

rootSegments = candidate.processing_segments( ...
    [candidate.processing_segments.job] == scenario.resume_plan.job & ...
    [candidate.processing_segments.operation] == ...
    scenario.resume_plan.operation);
assert(numel(rootSegments) == 2);
assert(any(strcmp({rootSegments.segment_type}, ...
    'processed_before_fault')));
assert(any(strcmp({rootSegments.segment_type}, ...
    'resumed_after_repair')));

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
    scenario.fault, tolerance);

if scenario.agv_impact.requires_agv_adjustment
    assert(candidate.is_agv_updated);
end

validationValues = struct2cell(candidate.validation);
assert(all(cellfun(@(value) isequal(value, true), validationValues)));

fprintf('test_stage_b_agv_linked_right_shift passed\n');

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

function assert_machine_segments(segments, fault, tolerance)
for machineId = unique([segments.machine_id])
    records = segments([segments.machine_id] == machineId);
    [~, order] = sort([records.start]);
    records = records(order);
    for index = 1:numel(records) - 1
        assert(records(index).end <= records(index + 1).start + tolerance);
    end
end
records = segments([segments.machine_id] == fault.machine_id);
for index = 1:numel(records)
    overlap = records(index).start < fault.repair_end_time - tolerance && ...
        fault.start_time < records(index).end - tolerance;
    assert(~overlap);
end
end

function operation = find_operation(records, jobId, operationId)
match = find([records.job] == jobId & ...
    [records.operation] == operationId);
assert(numel(match) == 1);
operation = records(match);
end
