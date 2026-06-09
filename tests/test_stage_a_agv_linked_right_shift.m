clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_a_agv_linked_right_shift();
candidate = scenario.linked_right_shift;

assert(candidate.is_machine_validated);
assert(candidate.is_agv_validated);
assert(candidate.is_fully_validated);
assert(isequaln(scenario.baseline.AGVTable, ...
    scenario.right_shift.AGVTable), ...
    'The machine-only candidate must remain unchanged.');

assert_operation_assignments_and_durations_preserved( ...
    scenario.right_shift.operation_records, ...
    candidate.operation_records);
assert_agv_activity_identity_preserved( ...
    scenario.baseline.AGVTable, candidate.agv_activity_records);
assert_machine_constraints(candidate.operation_records);
assert_job_and_transport_constraints(candidate, ...
    scenario.baseline.problem.operaNumVec);
assert_agv_sequence(candidate.agv_activity_records);
assert_repair_interval(candidate.operation_records, scenario.fault);

if scenario.agv_impact.requires_agv_adjustment
    assert(candidate.is_agv_updated, ...
        'An impacted AGV plan must contain at least one shifted activity.');
end

fprintf('test_stage_a_agv_linked_right_shift passed\n');

function assert_operation_assignments_and_durations_preserved( ...
        original, updated)
assert(numel(original) == numel(updated));
for index = 1:numel(original)
    match = find([updated.job] == original(index).job & ...
        [updated.operation] == original(index).operation);
    assert(numel(match) == 1);
    assert(updated(match).machine_id == original(index).machine_id);
    assert(abs(updated(match).duration - original(index).duration) <= 1e-9);
    assert(updated(match).start + 1e-9 >= original(index).start);
end
end

function assert_agv_activity_identity_preserved(AGVTable, updated)
original = collect_activities(AGVTable);
assert(numel(original) == numel(updated));
for index = 1:numel(original)
    match = find([updated.agv_id] == original(index).agv_id & ...
        [updated.original_table_index] == ...
        original(index).original_table_index);
    assert(numel(match) == 1);
    fields = {'job', 'operation', 'load_status', ...
        'from_machine', 'to_machine', 'charge'};
    for fieldIndex = 1:numel(fields)
        field = fields{fieldIndex};
        assert(updated(match).(field) == original(index).(field));
    end
    assert(abs(updated(match).duration - original(index).duration) <= 1e-9);
    assert(updated(match).start + 1e-9 >= original(index).start);
end
end

function records = collect_activities(AGVTable)
template = struct('agv_id', [], 'original_table_index', [], ...
    'job', [], 'operation', [], 'load_status', [], ...
    'from_machine', [], 'to_machine', [], 'charge', [], ...
    'duration', []);
records = template([]);
for agvId = 1:numel(AGVTable)
    for tableIndex = 1:numel(AGVTable{agvId})
        block = AGVTable{agvId}(tableIndex);
        isIdle = block.job == 0 && block.opera == 0 && ...
            block.load_status == 0 && block.charge == 0;
        if isIdle || ~isfinite(block.end)
            continue
        end
        record = template;
        record.agv_id = agvId;
        record.original_table_index = tableIndex;
        record.job = block.job;
        record.operation = block.opera;
        record.load_status = block.load_status;
        record.from_machine = block.from_machine;
        record.to_machine = block.to_machine;
        record.charge = block.charge;
        record.duration = block.end - block.start;
        records(end + 1) = record;
    end
end
end

function assert_machine_constraints(operations)
for machineId = unique([operations.machine_id])
    records = operations([operations.machine_id] == machineId);
    [~, order] = sort([records.start]);
    records = records(order);
    for index = 1:numel(records) - 1
        assert(records(index).end <= records(index + 1).start + 1e-9);
    end
end
end

function assert_job_and_transport_constraints(candidate, operaNumVec)
operations = candidate.operation_records;
activities = candidate.agv_activity_records;
for jobId = 1:numel(operaNumVec)
    for operationId = 1:operaNumVec(jobId)
        operation = find_operation(operations, jobId, operationId);
        if operationId > 1
            predecessor = find_operation( ...
                operations, jobId, operationId - 1);
            assert(predecessor.end <= operation.start + 1e-9);
        end
        transport = find([activities.job] == jobId & ...
            [activities.operation] == operationId & ...
            [activities.load_status] == -2);
        if ~isempty(transport)
            assert(numel(transport) == 1);
            assert(activities(transport).end <= operation.start + 1e-9);
            if operationId > 1
                predecessor = find_operation( ...
                    operations, jobId, operationId - 1);
                assert(activities(transport).start + 1e-9 >= ...
                    predecessor.end);
            end
        end
    end
end
end

function assert_agv_sequence(activities)
for agvId = unique([activities.agv_id])
    records = activities([activities.agv_id] == agvId);
    [~, order] = sort([records.original_table_index]);
    records = records(order);
    for index = 1:numel(records) - 1
        assert(records(index).end <= records(index + 1).start + 1e-9);
    end
end
end

function assert_repair_interval(operations, fault)
records = operations([operations.machine_id] == fault.machine_id);
for index = 1:numel(records)
    overlap = records(index).start < fault.repair_end_time - 1e-9 && ...
        fault.start_time < records(index).end - 1e-9;
    assert(~overlap);
end
end

function operation = find_operation(records, jobId, operationId)
match = find([records.job] == jobId & ...
    [records.operation] == operationId);
assert(numel(match) == 1);
operation = records(match);
end
