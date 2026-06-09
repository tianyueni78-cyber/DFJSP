function state = extract_stage_a_state(baseline, fault)
%EXTRACT_STAGE_A_STATE Classify baseline tasks at a Stage A fault time.
%   Tasks ending at the fault time are completed. Tasks starting exactly
%   at the fault time are unstarted. Idle and charging blocks are excluded.

if nargin < 2
    error('extract_stage_a_state:MissingInput', ...
        'baseline and fault are required.');
end

require_fields(baseline, {'machineTable', 'AGVTable', 'problem', ...
    'isFaultFreeBaseline'}, 'baseline');
require_fields(baseline.problem, {'operaNumVec'}, 'baseline.problem');
require_fields(fault, {'stage', 'trigger_type', 'machine_id', ...
    'start_time', 'trigger_job', 'trigger_operation', ...
    'is_validated'}, 'fault');

if ~baseline.isFaultFreeBaseline
    error('extract_stage_a_state:InvalidBaseline', ...
        'baseline must be a fault-free normal schedule.');
end
if ~fault.is_validated || ~strcmp(fault.stage, 'A') || ...
        ~strcmp(fault.trigger_type, 'operation_completion')
    error('extract_stage_a_state:InvalidFault', ...
        'fault must be a validated Stage A completion-time event.');
end

snapshotTime = fault.start_time;
[completedOperations, inProgressOperations, unstartedOperations] = ...
    classify_operations(baseline.machineTable, snapshotTime);
[completedTransports, inProgressTransports, unstartedTransports] = ...
    classify_transports(baseline.AGVTable, snapshotTime);

expectedOperationCount = sum(baseline.problem.operaNumVec);
actualOperationCount = numel(completedOperations) + ...
    numel(inProgressOperations) + numel(unstartedOperations);
if actualOperationCount ~= expectedOperationCount
    error('extract_stage_a_state:OperationPartitionMismatch', ...
        ['The operation partition contains %d tasks, but the problem ', ...
        'defines %d operations.'], actualOperationCount, ...
        expectedOperationCount);
end
validate_operation_partition(baseline.problem.operaNumVec, ...
    completedOperations, inProgressOperations, unstartedOperations);

if ~contains_operation(completedOperations, ...
        fault.trigger_job, fault.trigger_operation)
    error('extract_stage_a_state:TriggerNotCompleted', ...
        'The operation that triggered the fault must be completed.');
end

state = struct();
state.stage = 'A';
state.snapshot_time = snapshotTime;
state.completed_operations = completedOperations;
state.in_progress_operations = inProgressOperations;
state.unstarted_operations = unstartedOperations;
state.completed_transports = completedTransports;
state.in_progress_transports = inProgressTransports;
state.unstarted_transports = unstartedTransports;
state.counts = build_counts(state);
state.is_validated = true;
state.is_rescheduled = false;
end

function [completed, inProgress, unstarted] = ...
        classify_operations(machineTable, snapshotTime)
template = operation_template();
completed = template([]);
inProgress = template([]);
unstarted = template([]);

for machineId = 1:numel(machineTable)
    blocks = machineTable{machineId};
    for tableIndex = 1:numel(blocks)
        block = blocks(tableIndex);
        if block.job <= 0 || block.opera <= 0 || ~isfinite(block.end)
            continue
        end

        task = template;
        task.machine_id = machineId;
        task.table_index = tableIndex;
        task.job = block.job;
        task.operation = block.opera;
        task.start = block.start;
        task.end = block.end;

        category = classify_interval(block.start, block.end, snapshotTime);
        switch category
            case 'completed'
                completed(end + 1) = task;
            case 'in_progress'
                inProgress(end + 1) = task;
            case 'unstarted'
                unstarted(end + 1) = task;
        end
    end
end
end

function [completed, inProgress, unstarted] = ...
        classify_transports(AGVTable, snapshotTime)
template = transport_template();
completed = template([]);
inProgress = template([]);
unstarted = template([]);

for agvId = 1:numel(AGVTable)
    blocks = AGVTable{agvId};
    for tableIndex = 1:numel(blocks)
        block = blocks(tableIndex);
        if ~is_job_transport(block)
            continue
        end

        task = template;
        task.agv_id = agvId;
        task.table_index = tableIndex;
        task.job = block.job;
        task.operation = block.opera;
        task.transfer_type = transfer_type(block.load_status);
        task.load_status = block.load_status;
        task.from_machine = block.from_machine;
        task.to_machine = block.to_machine;
        task.start = block.start;
        task.end = block.end;

        category = classify_interval(block.start, block.end, snapshotTime);
        switch category
            case 'completed'
                completed(end + 1) = task;
            case 'in_progress'
                inProgress(end + 1) = task;
            case 'unstarted'
                unstarted(end + 1) = task;
        end
    end
end
end

function category = classify_interval(startTime, endTime, snapshotTime)
if ~isfinite(startTime) || ~isfinite(endTime) || endTime < startTime
    error('extract_stage_a_state:InvalidInterval', ...
        'Task intervals must be finite and satisfy start <= end.');
end

if endTime <= snapshotTime
    category = 'completed';
elseif startTime < snapshotTime && snapshotTime < endTime
    category = 'in_progress';
else
    category = 'unstarted';
end
end

function result = is_job_transport(block)
required = {'job', 'opera', 'load_status', 'from_machine', ...
    'to_machine', 'charge', 'start', 'end'};
result = all(isfield(block, required)) && ...
    block.job > 0 && block.charge == 0 && ...
    any(block.load_status == [-1, -2]) && isfinite(block.end);
end

function value = transfer_type(loadStatus)
if loadStatus == -1
    value = 'empty';
else
    value = 'loaded';
end
end

function result = contains_operation(operations, jobId, operationId)
result = false;
for index = 1:numel(operations)
    if operations(index).job == jobId && ...
            operations(index).operation == operationId
        result = true;
        return
    end
end
end

function validate_operation_partition( ...
        operaNumVec, completed, inProgress, unstarted)
allOperations = [completed, inProgress, unstarted];
for jobId = 1:numel(operaNumVec)
    for operationId = 1:operaNumVec(jobId)
        matches = 0;
        for index = 1:numel(allOperations)
            matches = matches + ...
                (allOperations(index).job == jobId && ...
                allOperations(index).operation == operationId);
        end
        if matches ~= 1
            error('extract_stage_a_state:OperationPartitionMismatch', ...
                'Operation J%d-O%d appears %d times in the partition.', ...
                jobId, operationId, matches);
        end
    end
end
end

function counts = build_counts(state)
counts = struct();
counts.completed_operations = numel(state.completed_operations);
counts.in_progress_operations = numel(state.in_progress_operations);
counts.unstarted_operations = numel(state.unstarted_operations);
counts.completed_transports = numel(state.completed_transports);
counts.in_progress_transports = numel(state.in_progress_transports);
counts.unstarted_transports = numel(state.unstarted_transports);
end

function value = operation_template()
value = struct('machine_id', [], 'table_index', [], 'job', [], ...
    'operation', [], 'start', [], 'end', []);
end

function value = transport_template()
value = struct('agv_id', [], 'table_index', [], 'job', [], ...
    'operation', [], 'transfer_type', '', 'load_status', [], ...
    'from_machine', [], 'to_machine', [], 'start', [], 'end', []);
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('extract_stage_a_state:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
