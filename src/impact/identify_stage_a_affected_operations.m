function impact = identify_stage_a_affected_operations( ...
        baseline, fault, state)
%IDENTIFY_STAGE_A_AFFECTED_OPERATIONS Find delayed unstarted operations.
%   Projected times are used only to propagate impact. The baseline
%   machine table is never modified by this function.

if nargin < 3
    error('identify_stage_a_affected_operations:MissingInput', ...
        'baseline, fault, and state are required.');
end

require_fields(baseline, {'machineTable', 'problem', ...
    'isFaultFreeBaseline'}, 'baseline');
require_fields(fault, {'stage', 'machine_id', 'start_time', ...
    'repair_end_time', 'is_validated'}, 'fault');
require_fields(state, {'snapshot_time', 'unstarted_operations', ...
    'is_validated', 'is_rescheduled'}, 'state');

validate_inputs(baseline, fault, state);

operations = initialize_operations(state.unstarted_operations);
jobSuccessor = build_job_successors(operations);
machineSuccessor = build_machine_successors(operations);

affected = false(1, numel(operations));
directReason = false(1, numel(operations));
jobReason = false(1, numel(operations));
machineReason = false(1, numel(operations));
projectedStart = [operations.original_start];
projectedEnd = [operations.original_end];

for index = 1:numel(operations)
    if operations(index).machine_id == fault.machine_id && ...
            operations(index).original_start < fault.repair_end_time && ...
            fault.start_time < operations(index).original_end
        affected(index) = true;
        directReason(index) = true;
        projectedStart(index) = max( ...
            operations(index).original_start, fault.repair_end_time);
        projectedEnd(index) = projectedStart(index) + ...
            operations(index).duration;
    end
end

[affected, jobReason, machineReason, projectedStart, projectedEnd] = ...
    propagate_delays(operations, jobSuccessor, machineSuccessor, ...
    affected, jobReason, machineReason, projectedStart, projectedEnd);

affectedOperations = build_affected_records(operations, affected, ...
    directReason, jobReason, machineReason, projectedStart, projectedEnd);
unaffectedOperations = operations(~affected);

impact = struct();
impact.stage = 'A';
impact.unavailable_interval = struct( ...
    'machine_id', fault.machine_id, ...
    'start_time', fault.start_time, ...
    'end_time', fault.repair_end_time, ...
    'interval_type', '[start, end)');
impact.directly_affected_operations = ...
    affectedOperations([affectedOperations.direct_repair_conflict]);
impact.affected_operations = affectedOperations;
impact.unaffected_unstarted_operations = unaffectedOperations;
impact.counts = struct( ...
    'directly_affected', numel(impact.directly_affected_operations), ...
    'affected_total', numel(affectedOperations), ...
    'unaffected_unstarted', numel(unaffectedOperations));
impact.is_validated = validate_impact(impact, state);
impact.baseline_modified = false;
impact.is_rescheduled = false;
end

function operations = initialize_operations(unstarted)
template = operation_template();
operations = repmat(template, 1, numel(unstarted));
for index = 1:numel(unstarted)
    operations(index).machine_id = unstarted(index).machine_id;
    operations(index).table_index = unstarted(index).table_index;
    operations(index).job = unstarted(index).job;
    operations(index).operation = unstarted(index).operation;
    operations(index).original_start = unstarted(index).start;
    operations(index).original_end = unstarted(index).end;
    operations(index).duration = ...
        unstarted(index).end - unstarted(index).start;
end
end

function successors = build_job_successors(operations)
successors = zeros(1, numel(operations));
for index = 1:numel(operations)
    matches = find([operations.job] == operations(index).job & ...
        [operations.operation] == operations(index).operation + 1);
    if numel(matches) > 1
        error('identify_stage_a_affected_operations:DuplicateOperation', ...
            'A job successor appears more than once.');
    end
    if ~isempty(matches)
        successors(index) = matches;
    end
end
end

function successors = build_machine_successors(operations)
successors = zeros(1, numel(operations));
if isempty(operations)
    return
end

for machineId = unique([operations.machine_id])
    indices = find([operations.machine_id] == machineId);
    ordering = [[operations(indices).original_start].', ...
        [operations(indices).table_index].'];
    [~, order] = sortrows(ordering, [1, 2]);
    orderedIndices = indices(order);
    for position = 1:numel(orderedIndices) - 1
        successors(orderedIndices(position)) = ...
            orderedIndices(position + 1);
    end
end
end

function [affected, jobReason, machineReason, ...
        projectedStart, projectedEnd] = propagate_delays( ...
        operations, jobSuccessor, machineSuccessor, affected, ...
        jobReason, machineReason, projectedStart, projectedEnd)
tolerance = 1e-9;
maximumIterations = max(1, numel(operations) ^ 2);

for iteration = 1:maximumIterations
    changed = false;
    affectedIndices = find(affected);
    for sourceIndex = affectedIndices
        [affected, jobReason, projectedStart, projectedEnd, changed] = ...
            relax_successor(operations, sourceIndex, ...
            jobSuccessor(sourceIndex), affected, jobReason, ...
            projectedStart, projectedEnd, changed, tolerance);
        [affected, machineReason, projectedStart, projectedEnd, changed] = ...
            relax_successor(operations, sourceIndex, ...
            machineSuccessor(sourceIndex), affected, machineReason, ...
            projectedStart, projectedEnd, changed, tolerance);
    end
    if ~changed
        return
    end
end

error('identify_stage_a_affected_operations:PropagationDidNotConverge', ...
    'Impact propagation did not converge.');
end

function [affected, reason, projectedStart, projectedEnd, changed] = ...
        relax_successor(operations, sourceIndex, targetIndex, ...
        affected, reason, projectedStart, projectedEnd, changed, tolerance)
if targetIndex == 0
    return
end

requiredStart = projectedEnd(sourceIndex);
if requiredStart <= operations(targetIndex).original_start + tolerance
    return
end

reason(targetIndex) = true;
newStart = max(projectedStart(targetIndex), requiredStart);
newEnd = newStart + operations(targetIndex).duration;
if ~affected(targetIndex) || ...
        newEnd > projectedEnd(targetIndex) + tolerance
    affected(targetIndex) = true;
    projectedStart(targetIndex) = newStart;
    projectedEnd(targetIndex) = newEnd;
    changed = true;
end
end

function records = build_affected_records(operations, affected, ...
        directReason, jobReason, machineReason, projectedStart, projectedEnd)
template = affected_template();
indices = find(affected);
records = repmat(template, 1, numel(indices));

for outputIndex = 1:numel(indices)
    sourceIndex = indices(outputIndex);
    records(outputIndex).machine_id = operations(sourceIndex).machine_id;
    records(outputIndex).table_index = operations(sourceIndex).table_index;
    records(outputIndex).job = operations(sourceIndex).job;
    records(outputIndex).operation = operations(sourceIndex).operation;
    records(outputIndex).original_start = ...
        operations(sourceIndex).original_start;
    records(outputIndex).original_end = ...
        operations(sourceIndex).original_end;
    records(outputIndex).duration = operations(sourceIndex).duration;
    records(outputIndex).projected_start = projectedStart(sourceIndex);
    records(outputIndex).projected_end = projectedEnd(sourceIndex);
    records(outputIndex).projected_delay = ...
        projectedStart(sourceIndex) - ...
        operations(sourceIndex).original_start;
    records(outputIndex).direct_repair_conflict = ...
        directReason(sourceIndex);
    records(outputIndex).job_precedence_conflict = ...
        jobReason(sourceIndex);
    records(outputIndex).machine_sequence_conflict = ...
        machineReason(sourceIndex);
end
end

function result = validate_impact(impact, state)
if impact.counts.affected_total + ...
        impact.counts.unaffected_unstarted ~= ...
        numel(state.unstarted_operations)
    error('identify_stage_a_affected_operations:PartitionMismatch', ...
        'Affected and unaffected operations do not partition the input.');
end

for index = 1:numel(impact.affected_operations)
    operation = impact.affected_operations(index);
    if operation.projected_delay <= 0
        error('identify_stage_a_affected_operations:InvalidDelay', ...
            'Every affected operation must have a positive delay.');
    end
end
result = true;
end

function value = operation_template()
value = struct('machine_id', [], 'table_index', [], 'job', [], ...
    'operation', [], 'original_start', [], 'original_end', [], ...
    'duration', []);
end

function value = affected_template()
value = operation_template();
value.projected_start = [];
value.projected_end = [];
value.projected_delay = [];
value.direct_repair_conflict = false;
value.job_precedence_conflict = false;
value.machine_sequence_conflict = false;
end

function validate_inputs(baseline, fault, state)
if ~baseline.isFaultFreeBaseline || ~fault.is_validated || ...
        ~state.is_validated || state.is_rescheduled
    error('identify_stage_a_affected_operations:InvalidInputState', ...
        'A validated fault-free baseline and state snapshot are required.');
end
if ~strcmp(fault.stage, 'A') || ...
        abs(state.snapshot_time - fault.start_time) > 1e-9
    error('identify_stage_a_affected_operations:InconsistentSnapshot', ...
        'The state snapshot must correspond to the Stage A fault.');
end
if fault.repair_end_time <= fault.start_time
    error('identify_stage_a_affected_operations:InvalidInterval', ...
        'The repair interval must have positive duration.');
end
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('identify_stage_a_affected_operations:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
