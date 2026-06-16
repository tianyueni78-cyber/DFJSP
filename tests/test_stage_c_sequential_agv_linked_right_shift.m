clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_c_sequential_agv_linked_right_shift();
machineCandidate = scenario.sequential_machine_right_shift;
agvImpact = scenario.sequential_agv_impact;
linkedCandidate = scenario.sequential_linked_right_shift;
tolerance = 1e-9;

assert(scenario.is_validated);
assert(scenario.step == 15);
assert(scenario.is_machine_right_shift_built);
assert(scenario.is_agv_impact_identified);
assert(scenario.is_agv_rescheduled);
assert(scenario.is_fully_validated);
assert(~scenario.is_search_executed_in_step_15);
assert(~scenario.is_plan_version_appended_in_step_15);

assert(machineCandidate.is_machine_validated);
assert(~machineCandidate.is_agv_updated);
assert(agvImpact.is_validated);
assert(linkedCandidate.is_machine_validated);
assert(linkedCandidate.is_agv_validated);
assert(linkedCandidate.is_fully_validated);
assert(numel(machineCandidate.interrupted_commitments) == 1);
assert(numel(linkedCandidate.interrupted_commitments) == 1);

assert(scenario.sequential_impact_context.counts.new_event_affected > 0);
assert(numel(machineCandidate.operation_records) == ...
    sum(scenario.baseline.problem.operaNumVec));
assert(numel(linkedCandidate.operation_records) == ...
    numel(machineCandidate.operation_records));
assert(isequaln(machineCandidate.AGVTable, ...
    scenario.next_fault_state.current_plan_view.AGVTable));

commitment = linkedCandidate.interrupted_commitments;
root = linkedCandidate.operation_records( ...
    [linkedCandidate.operation_records.job] == commitment.job & ...
    [linkedCandidate.operation_records.operation] == ...
    commitment.operation);
assert(numel(root) == 1);
assert(abs(root.start - commitment.original_start) <= tolerance);
assert(abs(root.end - commitment.revised_completion_time) <= ...
    tolerance);

assert_machine_segments(linkedCandidate.processing_segments, ...
    scenario.next_fault, tolerance);
assert_agv_non_overlap(linkedCandidate.agv_activity_records, ...
    tolerance);
assert_transport_arrival(linkedCandidate, ...
    scenario.baseline.problem.operaNumVec, tolerance);

validationValues = struct2cell(linkedCandidate.validation);
assert(all(cellfun(@(value) isequal(value, true), validationValues)));

fprintf('test_stage_c_sequential_agv_linked_right_shift passed\n');

function assert_machine_segments(segments, fault, tolerance)
for machineId = unique([segments.machine_id])
    records = segments([segments.machine_id] == machineId);
    [~, order] = sort([records.start]);
    records = records(order);
    for index = 1:numel(records) - 1
        assert(records(index).end <= ...
            records(index + 1).start + tolerance);
    end
end
records = segments([segments.machine_id] == fault.machine_id);
for index = 1:numel(records)
    overlap = records(index).start < ...
        fault.repair_end_time - tolerance && ...
        fault.start_time < records(index).end - tolerance;
    assert(~overlap);
end
end

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

function assert_transport_arrival(candidate, operaNumVec, tolerance)
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
    end
end
end

function operation = find_operation(records, job, operationId)
match = find([records.job] == job & ...
    [records.operation] == operationId);
assert(numel(match) == 1);
operation = records(match);
end
