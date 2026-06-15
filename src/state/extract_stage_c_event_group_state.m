function state = extract_stage_c_event_group_state( ...
        baseline, faults, eventGroup)
%EXTRACT_STAGE_C_EVENT_GROUP_STATE Extract one Stage C event-group state.
%   The snapshot is read-only. Operations are partitioned into completed,
%   normal in-progress, fault in-progress, and unstarted categories.

if nargin < 3
    error('extract_stage_c_event_group_state:MissingInput', ...
        'baseline, faults, and eventGroup are required.');
end
validate_baseline(baseline);
validate_event_group(eventGroup);
groupFaults = select_group_faults(faults, eventGroup);
snapshotTime = groupFaults(1).start_time;
failedMachineIds = unique([groupFaults.machine_id], 'stable');

[completed, inProgress, unstarted] = classify_operations( ...
    baseline.machineTable, snapshotTime);
[faultInProgress, normalInProgress] = split_in_progress( ...
    inProgress, groupFaults);
[completedTransports, inProgressTransports, unstartedTransports] = ...
    classify_transports(baseline.AGVTable, snapshotTime);

expectedCount = sum(baseline.problem.operaNumVec);
actualCount = numel(completed) + numel(normalInProgress) + ...
    numel(faultInProgress) + numel(unstarted);
if actualCount ~= expectedCount
    error('extract_stage_c_event_group_state:PartitionMismatch', ...
        'Every operation must appear in exactly one state category.');
end
validate_operation_partition(baseline.problem.operaNumVec, ...
    completed, normalInProgress, faultInProgress, unstarted);

state = struct();
state.stage = 'C';
state.event_group = eventGroup;
state.event_ids = [groupFaults.event_id];
state.snapshot_time = snapshotTime;
state.failed_machine_ids = failedMachineIds;
state.completed_operations = completed;
state.normal_in_progress_operations = normalInProgress;
state.fault_in_progress_operations = faultInProgress;
state.unstarted_operations = unstarted;
state.completed_transports = completedTransports;
state.in_progress_transports = inProgressTransports;
state.unstarted_transports = unstartedTransports;
state.active_agv_ids = unique([inProgressTransports.agv_id], 'stable');
state.counts = build_counts(state);
state.is_rescheduled = false;
state.is_validated = validate_state(state, expectedCount);
end

function groupFaults = select_group_faults(faults, eventGroup)
required = {'event_id', 'stage', 'trigger_type', 'machine_id', ...
    'start_time', 'event_group', 'source_order', 'is_validated'};
if ~isstruct(faults) || isempty(faults) || ~isvector(faults)
    error('extract_stage_c_event_group_state:InvalidFaultArray', ...
        'faults must be a nonempty normalized struct vector.');
end
for index = 1:numel(faults)
    require_fields(faults(index), required, 'faults');
    if ~faults(index).is_validated || ...
            ~strcmp(faults(index).stage, 'C') || ...
            ~strcmp(faults(index).trigger_type, 'machine_failure')
        error('extract_stage_c_event_group_state:InvalidFault', ...
            'Every fault must be a validated Stage C machine failure.');
    end
end
groupFaults = faults([faults.event_group] == eventGroup);
if isempty(groupFaults)
    error('extract_stage_c_event_group_state:UnknownEventGroup', ...
        'eventGroup does not exist in faults.');
end
if max(abs([groupFaults.start_time] - ...
        groupFaults(1).start_time)) > 1e-9
    error('extract_stage_c_event_group_state:InconsistentGroupTime', ...
        'All faults in one event group must share the same start time.');
end
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

function [faultTasks, normalTasks] = split_in_progress(tasks, groupFaults)
template = interrupted_operation_template();
faultTasks = template([]);
normalTasks = operation_template([]);
failedMachineIds = [groupFaults.machine_id];
for index = 1:numel(tasks)
    task = tasks(index);
    matchingFaults = find(failedMachineIds == task.machine_id);
    if isempty(matchingFaults)
        normalTasks(end + 1) = task;
        continue
    end
    interrupted = template;
    fields = fieldnames(task);
    for fieldIndex = 1:numel(fields)
        interrupted.(fields{fieldIndex}) = task.(fields{fieldIndex});
    end
    interrupted.original_duration = task.end - task.start;
    interrupted.elapsed_processing_time = ...
        groupFaults(1).start_time - task.start;
    interrupted.remaining_processing_time = ...
        task.end - groupFaults(1).start_time;
    interrupted.progress_ratio = interrupted.elapsed_processing_time / ...
        interrupted.original_duration;
    interrupted.source_event_ids = ...
        [groupFaults(matchingFaults).event_id];
    interrupted.interruption_rules = ...
        {groupFaults(matchingFaults).interruption_rule};
    faultTasks(end + 1) = interrupted;
end
end

function [completed, inProgress, unstarted] = ...
        classify_transports(agvTable, snapshotTime)
template = transport_template();
completed = template([]);
inProgress = template([]);
unstarted = template([]);
for agvId = 1:numel(agvTable)
    blocks = agvTable{agvId};
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
    error('extract_stage_c_event_group_state:InvalidInterval', ...
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

function validate_operation_partition(operaNumVec, varargin)
for jobId = 1:numel(operaNumVec)
    for operationId = 1:operaNumVec(jobId)
        matches = 0;
        for categoryIndex = 1:numel(varargin)
            operations = varargin{categoryIndex};
            if ~isempty(operations)
                matches = matches + sum([operations.job] == jobId & ...
                    [operations.operation] == operationId);
            end
        end
        if matches ~= 1
            error('extract_stage_c_event_group_state:PartitionMismatch', ...
                'Operation J%d-O%d appears %d times.', ...
                jobId, operationId, matches);
        end
    end
end
end

function counts = build_counts(state)
counts = struct();
counts.completed_operations = numel(state.completed_operations);
counts.normal_in_progress_operations = ...
    numel(state.normal_in_progress_operations);
counts.fault_in_progress_operations = ...
    numel(state.fault_in_progress_operations);
counts.unstarted_operations = numel(state.unstarted_operations);
counts.completed_transports = numel(state.completed_transports);
counts.in_progress_transports = numel(state.in_progress_transports);
counts.unstarted_transports = numel(state.unstarted_transports);
counts.active_agvs = numel(state.active_agv_ids);
end

function result = validate_state(state, expectedCount)
operationCount = state.counts.completed_operations + ...
    state.counts.normal_in_progress_operations + ...
    state.counts.fault_in_progress_operations + ...
    state.counts.unstarted_operations;
result = operationCount == expectedCount;
for index = 1:numel(state.fault_in_progress_operations)
    task = state.fault_in_progress_operations(index);
    result = result && task.elapsed_processing_time > 0 && ...
        task.remaining_processing_time > 0 && ...
        abs(task.elapsed_processing_time + ...
        task.remaining_processing_time - ...
        task.original_duration) <= 1e-9 && ...
        any(task.machine_id == state.failed_machine_ids) && ...
        ~isempty(task.source_event_ids);
end
if ~result
    error('extract_stage_c_event_group_state:InvalidState', ...
        'The Stage C event-group state is inconsistent.');
end
end

function validate_baseline(baseline)
require_fields(baseline, {'machineTable', 'AGVTable', 'problem', ...
    'isFaultFreeBaseline'}, 'baseline');
require_fields(baseline.problem, {'operaNumVec'}, 'baseline.problem');
if ~baseline.isFaultFreeBaseline
    error('extract_stage_c_event_group_state:InvalidBaseline', ...
        'baseline must be a fault-free normal schedule.');
end
end

function validate_event_group(value)
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || ...
        value < 1 || value ~= floor(value)
    error('extract_stage_c_event_group_state:InvalidEventGroup', ...
        'eventGroup must be a positive integer.');
end
end

function value = operation_template()
value = struct('machine_id', [], 'table_index', [], 'job', [], ...
    'operation', [], 'start', [], 'end', []);
end

function value = interrupted_operation_template()
value = struct('machine_id', [], 'table_index', [], 'job', [], ...
    'operation', [], 'start', [], 'end', [], ...
    'original_duration', [], 'elapsed_processing_time', [], ...
    'remaining_processing_time', [], 'progress_ratio', [], ...
    'source_event_ids', [], 'interruption_rules', {{}});
end

function value = transport_template()
value = struct('agv_id', [], 'table_index', [], 'job', [], ...
    'operation', [], 'transfer_type', '', 'load_status', [], ...
    'from_machine', [], 'to_machine', [], 'start', [], 'end', []);
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('extract_stage_c_event_group_state:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
