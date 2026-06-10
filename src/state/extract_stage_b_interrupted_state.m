function state = extract_stage_b_interrupted_state(baseline, fault)
%EXTRACT_STAGE_B_INTERRUPTED_STATE Identify the in-process operation.
%   This step partitions machine operations at the fault time and records
%   the interrupted operation's elapsed and remaining processing times.
%   It does not apply a resume, restart, or migration rule.

if nargin < 2
    error('extract_stage_b_interrupted_state:MissingInput', ...
        'baseline and fault are required.');
end
require_fields(baseline, {'machineTable', 'problem', ...
    'isFaultFreeBaseline'}, 'baseline');
require_fields(baseline.problem, {'operaNumVec'}, 'baseline.problem');
require_fields(fault, {'stage', 'trigger_type', 'machine_id', ...
    'start_time', 'interrupted_operation', 'is_validated'}, 'fault');
if ~baseline.isFaultFreeBaseline || ~fault.is_validated || ...
        ~strcmp(fault.stage, 'B') || ...
        ~strcmp(fault.trigger_type, 'operation_processing')
    error('extract_stage_b_interrupted_state:InvalidInput', ...
        'Validated Stage B inputs are required.');
end

[completed, inProgress, unstarted] = classify_operations( ...
    baseline.machineTable, fault.start_time);
expectedCount = sum(baseline.problem.operaNumVec);
if numel(completed) + numel(inProgress) + numel(unstarted) ~= ...
        expectedCount
    error('extract_stage_b_interrupted_state:PartitionMismatch', ...
        'Every operation must appear in exactly one state category.');
end

onFailedMachine = inProgress( ...
    [inProgress.machine_id] == fault.machine_id);
if numel(onFailedMachine) ~= 1 || ...
        onFailedMachine.job ~= fault.interrupted_operation.job || ...
        onFailedMachine.operation ~= ...
        fault.interrupted_operation.operation
    error('extract_stage_b_interrupted_state:InterruptedMismatch', ...
        'Exactly one matching operation must be active on the failed machine.');
end

interrupted = onFailedMachine;
interrupted.original_duration = interrupted.end - interrupted.start;
interrupted.elapsed_processing_time = ...
    fault.start_time - interrupted.start;
interrupted.remaining_processing_time = ...
    interrupted.end - fault.start_time;
interrupted.progress_ratio = interrupted.elapsed_processing_time / ...
    interrupted.original_duration;
interrupted.interruption_rule = fault.interruption_rule;

state = struct();
state.stage = 'B';
state.snapshot_time = fault.start_time;
state.completed_operations = completed;
state.in_progress_operations = inProgress;
state.unstarted_operations = unstarted;
state.interrupted_operation = interrupted;
state.counts = struct( ...
    'completed_operations', numel(completed), ...
    'in_progress_operations', numel(inProgress), ...
    'unstarted_operations', numel(unstarted), ...
    'interrupted_operations', 1);
state.interruption_rule_resolved = false;
state.is_rescheduled = false;
state.is_validated = validate_state(state, fault, expectedCount);
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
        if block.end <= snapshotTime
            completed(end + 1) = task;
        elseif block.start < snapshotTime && snapshotTime < block.end
            inProgress(end + 1) = task;
        else
            unstarted(end + 1) = task;
        end
    end
end
end

function result = validate_state(state, fault, expectedCount)
interrupted = state.interrupted_operation;
if interrupted.elapsed_processing_time <= 0 || ...
        interrupted.remaining_processing_time <= 0 || ...
        abs(interrupted.elapsed_processing_time + ...
        interrupted.remaining_processing_time - ...
        interrupted.original_duration) > 1e-9 || ...
        interrupted.machine_id ~= fault.machine_id || ...
        state.counts.completed_operations + ...
        state.counts.in_progress_operations + ...
        state.counts.unstarted_operations ~= expectedCount
    error('extract_stage_b_interrupted_state:InvalidState', ...
        'The Stage B interrupted state is inconsistent.');
end
result = true;
end

function value = operation_template()
value = struct('machine_id', [], 'table_index', [], 'job', [], ...
    'operation', [], 'start', [], 'end', []);
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('extract_stage_b_interrupted_state:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
