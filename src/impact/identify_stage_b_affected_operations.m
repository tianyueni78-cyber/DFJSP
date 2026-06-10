function impact = identify_stage_b_affected_operations( ...
        baseline, state, resumePlan)
%IDENTIFY_STAGE_B_AFFECTED_OPERATIONS Propagate the interruption delay.
%   The resumed operation is the propagation root. Its revised completion
%   time is propagated through job and machine successors. Projected times
%   are calculated only; the baseline schedule is not modified.

if nargin < 3
    error('identify_stage_b_affected_operations:MissingInput', ...
        'baseline, state, and resumePlan are required.');
end
require_fields(baseline, {'machineTable', 'isFaultFreeBaseline'}, ...
    'baseline');
require_fields(state, {'stage', 'unstarted_operations', ...
    'interrupted_operation', 'is_validated', 'is_rescheduled'}, ...
    'state');
require_fields(resumePlan, {'stage', 'rule', 'machine_id', 'job', ...
    'operation', 'original_table_index', ...
    'revised_completion_time', 'completion_delay', ...
    'is_validated', 'successor_propagation_executed'}, 'resumePlan');
validate_inputs(baseline, state, resumePlan);

operations = initialize_operations(state.unstarted_operations);
jobSuccessor = build_job_successors(operations);
machineSuccessor = build_machine_successors(operations);
[rootJobSuccessor, rootMachineSuccessor] = ...
    find_root_successors(operations, resumePlan);

affected = false(1, numel(operations));
rootJobReason = false(1, numel(operations));
rootMachineReason = false(1, numel(operations));
jobReason = false(1, numel(operations));
machineReason = false(1, numel(operations));
projectedStart = [operations.original_start];
projectedEnd = [operations.original_end];

[affected, rootJobReason, projectedStart, projectedEnd] = ...
    seed_root_successor(operations, rootJobSuccessor, ...
    resumePlan.revised_completion_time, affected, rootJobReason, ...
    projectedStart, projectedEnd);
[affected, rootMachineReason, projectedStart, projectedEnd] = ...
    seed_root_successor(operations, rootMachineSuccessor, ...
    resumePlan.revised_completion_time, affected, rootMachineReason, ...
    projectedStart, projectedEnd);

[affected, jobReason, machineReason, projectedStart, projectedEnd] = ...
    propagate_delays(operations, jobSuccessor, machineSuccessor, ...
    affected, jobReason, machineReason, projectedStart, projectedEnd);

affectedOperations = build_affected_records( ...
    operations, affected, rootJobReason, rootMachineReason, ...
    jobReason, machineReason, projectedStart, projectedEnd);
unaffectedOperations = operations(~affected);

impact = struct();
impact.stage = 'B';
impact.step = 3;
impact.root_operation = struct( ...
    'machine_id', resumePlan.machine_id, ...
    'job', resumePlan.job, ...
    'operation', resumePlan.operation, ...
    'original_end', resumePlan.original_end, ...
    'revised_end', resumePlan.revised_completion_time, ...
    'completion_delay', resumePlan.completion_delay);
impact.root_job_successor = operation_identity( ...
    operations, rootJobSuccessor);
impact.root_machine_successor = operation_identity( ...
    operations, rootMachineSuccessor);
impact.affected_operations = affectedOperations;
impact.unaffected_unstarted_operations = unaffectedOperations;
impact.counts = struct( ...
    'affected_total', numel(affectedOperations), ...
    'unaffected_unstarted', numel(unaffectedOperations), ...
    'root_job_successors', double(rootJobSuccessor > 0), ...
    'root_machine_successors', double(rootMachineSuccessor > 0));
impact.baseline_modified = false;
impact.is_rescheduled = false;
impact.is_validated = validate_impact(impact, state);
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
        error('identify_stage_b_affected_operations:DuplicateOperation', ...
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
    ordered = indices(order);
    for position = 1:numel(ordered) - 1
        successors(ordered(position)) = ordered(position + 1);
    end
end
end

function [jobSuccessor, machineSuccessor] = ...
        find_root_successors(operations, resumePlan)
jobMatches = find([operations.job] == resumePlan.job & ...
    [operations.operation] == resumePlan.operation + 1);
if numel(jobMatches) > 1
    error('identify_stage_b_affected_operations:RootJobSuccessor', ...
        'The root job successor appears more than once.');
end
if isempty(jobMatches)
    jobSuccessor = 0;
else
    jobSuccessor = jobMatches;
end

machineIndices = find([operations.machine_id] == resumePlan.machine_id & ...
    [operations.table_index] > resumePlan.original_table_index);
if isempty(machineIndices)
    machineSuccessor = 0;
    return
end
ordering = [[operations(machineIndices).table_index].', ...
    [operations(machineIndices).original_start].'];
[~, order] = sortrows(ordering, [1, 2]);
machineSuccessor = machineIndices(order(1));
end

function [affected, reason, projectedStart, projectedEnd] = ...
        seed_root_successor(operations, targetIndex, requiredStart, ...
        affected, reason, projectedStart, projectedEnd)
if targetIndex == 0 || ...
        requiredStart <= operations(targetIndex).original_start + 1e-9
    return
end
affected(targetIndex) = true;
reason(targetIndex) = true;
projectedStart(targetIndex) = requiredStart;
projectedEnd(targetIndex) = requiredStart + ...
    operations(targetIndex).duration;
end

function [affected, jobReason, machineReason, ...
        projectedStart, projectedEnd] = propagate_delays( ...
        operations, jobSuccessor, machineSuccessor, affected, ...
        jobReason, machineReason, projectedStart, projectedEnd)
maximumIterations = max(1, numel(operations) ^ 2);
for iteration = 1:maximumIterations
    changed = false;
    for sourceIndex = find(affected)
        [affected, jobReason, projectedStart, projectedEnd, changed] = ...
            relax_successor(operations, sourceIndex, ...
            jobSuccessor(sourceIndex), affected, jobReason, ...
            projectedStart, projectedEnd, changed);
        [affected, machineReason, projectedStart, projectedEnd, changed] = ...
            relax_successor(operations, sourceIndex, ...
            machineSuccessor(sourceIndex), affected, machineReason, ...
            projectedStart, projectedEnd, changed);
    end
    if ~changed
        return
    end
end
error('identify_stage_b_affected_operations:NoConvergence', ...
    'Stage B impact propagation did not converge.');
end

function [affected, reason, projectedStart, projectedEnd, changed] = ...
        relax_successor(operations, sourceIndex, targetIndex, ...
        affected, reason, projectedStart, projectedEnd, changed)
if targetIndex == 0
    return
end
requiredStart = projectedEnd(sourceIndex);
if requiredStart <= operations(targetIndex).original_start + 1e-9
    return
end
newStart = max(projectedStart(targetIndex), requiredStart);
newEnd = newStart + operations(targetIndex).duration;
reason(targetIndex) = true;
if ~affected(targetIndex) || newEnd > projectedEnd(targetIndex) + 1e-9
    affected(targetIndex) = true;
    projectedStart(targetIndex) = newStart;
    projectedEnd(targetIndex) = newEnd;
    changed = true;
end
end

function records = build_affected_records(operations, affected, ...
        rootJobReason, rootMachineReason, jobReason, machineReason, ...
        projectedStart, projectedEnd)
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
    records(outputIndex).root_job_successor = ...
        rootJobReason(sourceIndex);
    records(outputIndex).root_machine_successor = ...
        rootMachineReason(sourceIndex);
    records(outputIndex).job_precedence_conflict = ...
        jobReason(sourceIndex);
    records(outputIndex).machine_sequence_conflict = ...
        machineReason(sourceIndex);
end
end

function identity = operation_identity(operations, index)
identity = struct('exists', false, 'machine_id', [], ...
    'job', [], 'operation', []);
if index == 0
    return
end
identity.exists = true;
identity.machine_id = operations(index).machine_id;
identity.job = operations(index).job;
identity.operation = operations(index).operation;
end

function result = validate_impact(impact, state)
if impact.counts.affected_total + ...
        impact.counts.unaffected_unstarted ~= ...
        numel(state.unstarted_operations)
    error('identify_stage_b_affected_operations:PartitionMismatch', ...
        'Impact sets must partition all unstarted operations.');
end
for index = 1:numel(impact.affected_operations)
    operation = impact.affected_operations(index);
    if operation.projected_delay <= 0 || ...
            ~(operation.root_job_successor || ...
            operation.root_machine_successor || ...
            operation.job_precedence_conflict || ...
            operation.machine_sequence_conflict)
        error('identify_stage_b_affected_operations:InvalidImpact', ...
            'Every affected operation needs a positive delay and cause.');
    end
end
result = true;
end

function validate_inputs(baseline, state, resumePlan)
if ~baseline.isFaultFreeBaseline || ~state.is_validated || ...
        state.is_rescheduled || ~resumePlan.is_validated || ...
        ~strcmp(state.stage, 'B') || ~strcmp(resumePlan.stage, 'B') || ...
        ~strcmp(resumePlan.rule, 'resume_on_original_machine') || ...
        resumePlan.successor_propagation_executed
    error('identify_stage_b_affected_operations:InvalidInput', ...
        'Validated Stage B resume inputs are required.');
end
if resumePlan.machine_id ~= state.interrupted_operation.machine_id || ...
        resumePlan.job ~= state.interrupted_operation.job || ...
        resumePlan.operation ~= state.interrupted_operation.operation
    error('identify_stage_b_affected_operations:RootMismatch', ...
        'Resume plan and interrupted state must identify the same root.');
end
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
value.root_job_successor = false;
value.root_machine_successor = false;
value.job_precedence_conflict = false;
value.machine_sequence_conflict = false;
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('identify_stage_b_affected_operations:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
