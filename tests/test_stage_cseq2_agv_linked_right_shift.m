clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_cseq2_agv_linked_right_shift();
candidate = scenario.cseq2_linked_right_shift;
tolerance = 1e-9;

assert(scenario.is_validated);
assert(strcmp(scenario.step, 'C-SEQ2.6'));
assert(strcmp(scenario.substep, '6'));
assert(scenario.is_agv_rescheduled);
assert(scenario.is_fully_validated);
assert(~scenario.is_search_executed_in_cseq2_step_6);
assert(~scenario.is_plan_version_appended_in_cseq2_step_6);
assert(candidate.is_validated);
assert(candidate.is_machine_validated);
assert(candidate.is_agv_validated);
assert(candidate.is_fully_validated);
assert(strcmp(candidate.stage, 'C-SEQ2'));
assert(strcmp(candidate.step, '6'));
assert(candidate.history_unchanged);
assert(~candidate.is_plan_modified);
assert(candidate.is_rescheduled);
assert(candidate.cumulative_unavailability.is_validated);
assert(numel(candidate.overlap_relationships) == ...
    scenario.cseq2_impact_context.counts.overlap_relationships);
assert(candidate.agv_impact_required_adjustment == ...
    scenario.cseq2_agv_impact.requires_agv_adjustment);

assert(numel(candidate.interrupted_commitments) == 1);
assert(numel(candidate.operation_records) == ...
    sum(scenario.baseline.problem.operaNumVec));
assert_agv_non_overlap(candidate.agv_activity_records, tolerance);
assert_transport_constraints(candidate, ...
    scenario.baseline.problem.operaNumVec, tolerance);
assert_machine_segments(candidate.processing_segments, ...
    scenario.next_fault, tolerance);
assert_final_unloads(candidate, ...
    scenario.baseline.problem.operaNumVec, tolerance);

if scenario.cseq2_agv_impact.requires_agv_adjustment
    assert(candidate.is_agv_updated);
end
validationValues = struct2cell(candidate.validation);
assert(all(cellfun(@(value) isequal(value, true), validationValues)));

fprintf('test_stage_cseq2_agv_linked_right_shift passed\n');

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
