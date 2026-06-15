function impact = identify_stage_c_simultaneous_affected_operations( ...
        baseline, state, faults)
%IDENTIFY_STAGE_C_SIMULTANEOUS_AFFECTED_OPERATIONS Propagate one or more roots.
%   Each interrupted root is propagated independently through job and
%   machine successors. Duplicate operations are then merged by taking the
%   maximum projected time and preserving every source event identity.

if nargin < 3
    error('identify_stage_c_simultaneous_affected_operations:MissingInput', ...
        'baseline, state, and faults are required.');
end
validate_inputs(baseline, state, faults);

operations = initialize_operations(state.unstarted_operations);
jobSuccessor = build_job_successors(operations);
machineSuccessor = build_machine_successors(operations);
rootTemplate = root_impact_template();
rootImpacts = repmat(rootTemplate, 1, numel(faults));

for faultIndex = 1:numel(faults)
    fault = faults(faultIndex);
    root = find_root_state(state.fault_in_progress_operations, fault);
    rootImpacts(faultIndex) = propagate_one_root( ...
        operations, jobSuccessor, machineSuccessor, root, fault);
end

merged = merge_root_impacts(rootImpacts);
affectedKeys = operation_keys(merged);
unaffected = operations(~ismember(operation_keys(operations), ...
    affectedKeys, 'rows'));

impact = struct();
impact.stage = 'C';
impact.step = 5;
impact.event_group = state.event_group;
impact.root_impacts = rootImpacts;
impact.affected_operations = merged;
impact.unaffected_unstarted_operations = unaffected;
impact.counts = struct( ...
    'root_count', numel(rootImpacts), ...
    'per_root_affected', [rootImpacts.affected_count], ...
    'affected_total', numel(merged), ...
    'multi_source_operations', sum([merged.source_count] > 1), ...
    'unaffected_unstarted', numel(unaffected));
impact.merge_rule = ...
    'maximum projected start/end with all source event ids preserved';
impact.baseline_modified = false;
impact.is_rescheduled = false;
impact.is_validated = validate_impact(impact, state);
end

function rootImpact = propagate_one_root(operations, jobSuccessor, ...
        machineSuccessor, root, fault)
[rootJobSuccessor, rootMachineSuccessor] = ...
    find_root_successors(operations, root);
revisedCompletion = fault.repair_end_time + ...
    root.remaining_processing_time;

affected = false(1, numel(operations));
rootJobReason = false(1, numel(operations));
rootMachineReason = false(1, numel(operations));
jobReason = false(1, numel(operations));
machineReason = false(1, numel(operations));
projectedStart = [operations.original_start];
projectedEnd = [operations.original_end];

[affected, rootJobReason, projectedStart, projectedEnd] = ...
    seed_successor(operations, rootJobSuccessor, revisedCompletion, ...
    affected, rootJobReason, projectedStart, projectedEnd);
[affected, rootMachineReason, projectedStart, projectedEnd] = ...
    seed_successor(operations, rootMachineSuccessor, revisedCompletion, ...
    affected, rootMachineReason, projectedStart, projectedEnd);
[affected, jobReason, machineReason, projectedStart, projectedEnd] = ...
    propagate_delays(operations, jobSuccessor, machineSuccessor, ...
    affected, jobReason, machineReason, projectedStart, projectedEnd);

records = build_source_records(operations, affected, fault.event_id, ...
    rootJobReason, rootMachineReason, jobReason, machineReason, ...
    projectedStart, projectedEnd);
rootImpact = root_impact_template();
rootImpact.event_id = fault.event_id;
rootImpact.machine_id = fault.machine_id;
rootImpact.job = root.job;
rootImpact.operation = root.operation;
rootImpact.original_end = root.end;
rootImpact.revised_end = revisedCompletion;
rootImpact.completion_delay = revisedCompletion - root.end;
rootImpact.affected_operations = records;
rootImpact.affected_count = numel(records);
rootImpact.is_validated = rootImpact.completion_delay > 0 && ...
    all([records.projected_delay] > 0);
end

function root = find_root_state(interrupted, fault)
matches = find([interrupted.machine_id] == fault.machine_id & ...
    cellfun(@(ids) any(ids == fault.event_id), ...
    {interrupted.source_event_ids}));
if numel(matches) ~= 1
    error(['identify_stage_c_simultaneous_affected_operations:', ...
        'RootMismatch'], ...
        'Each fault must identify exactly one interrupted root.');
end
root = interrupted(matches);
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
    operations(index).duration = unstarted(index).end - ...
        unstarted(index).start;
end
end

function successors = build_job_successors(operations)
successors = zeros(1, numel(operations));
for index = 1:numel(operations)
    matches = find([operations.job] == operations(index).job & ...
        [operations.operation] == operations(index).operation + 1);
    if numel(matches) > 1
        error(['identify_stage_c_simultaneous_affected_operations:', ...
            'DuplicateOperation'], ...
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
        find_root_successors(operations, root)
jobMatches = find([operations.job] == root.job & ...
    [operations.operation] == root.operation + 1);
if numel(jobMatches) > 1
    error(['identify_stage_c_simultaneous_affected_operations:', ...
        'RootJobSuccessor'], ...
        'The root job successor appears more than once.');
end
if isempty(jobMatches)
    jobSuccessor = 0;
else
    jobSuccessor = jobMatches;
end

machineIndices = find([operations.machine_id] == root.machine_id & ...
    [operations.table_index] > root.table_index);
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
        seed_successor(operations, targetIndex, requiredStart, ...
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
error(['identify_stage_c_simultaneous_affected_operations:', ...
    'NoConvergence'], 'Stage C impact propagation did not converge.');
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

function records = build_source_records(operations, affected, eventId, ...
        rootJobReason, rootMachineReason, jobReason, machineReason, ...
        projectedStart, projectedEnd)
template = source_record_template();
indices = find(affected);
records = repmat(template, 1, numel(indices));
for outputIndex = 1:numel(indices)
    index = indices(outputIndex);
    records(outputIndex) = source_record(operations(index), eventId, ...
        rootJobReason(index), rootMachineReason(index), ...
        jobReason(index), machineReason(index), ...
        projectedStart(index), projectedEnd(index));
end
end

function value = source_record(operation, eventId, rootJobReason, ...
        rootMachineReason, jobReason, machineReason, ...
        projectedStart, projectedEnd)
value = source_record_template();
fields = fieldnames(operation);
for index = 1:numel(fields)
    value.(fields{index}) = operation.(fields{index});
end
value.projected_start = projectedStart;
value.projected_end = projectedEnd;
value.projected_delay = projectedStart - operation.original_start;
value.source_event_ids = eventId;
value.source_count = 1;
value.root_job_successor = rootJobReason;
value.root_machine_successor = rootMachineReason;
value.job_precedence_conflict = jobReason;
value.machine_sequence_conflict = machineReason;
end

function merged = merge_root_impacts(rootImpacts)
template = source_record_template();
merged = template([]);
for rootIndex = 1:numel(rootImpacts)
    records = rootImpacts(rootIndex).affected_operations;
    for recordIndex = 1:numel(records)
        record = records(recordIndex);
        match = find_operation(merged, record.job, record.operation);
        if match == 0
            merged(end + 1) = record;
            continue
        end
        merged(match).projected_start = max( ...
            merged(match).projected_start, record.projected_start);
        merged(match).projected_end = max( ...
            merged(match).projected_end, record.projected_end);
        merged(match).projected_delay = ...
            merged(match).projected_start - ...
            merged(match).original_start;
        merged(match).source_event_ids = unique( ...
            [merged(match).source_event_ids, record.source_event_ids]);
        merged(match).source_count = ...
            numel(merged(match).source_event_ids);
        merged(match).root_job_successor = ...
            merged(match).root_job_successor || ...
            record.root_job_successor;
        merged(match).root_machine_successor = ...
            merged(match).root_machine_successor || ...
            record.root_machine_successor;
        merged(match).job_precedence_conflict = ...
            merged(match).job_precedence_conflict || ...
            record.job_precedence_conflict;
        merged(match).machine_sequence_conflict = ...
            merged(match).machine_sequence_conflict || ...
            record.machine_sequence_conflict;
    end
end
if numel(merged) > 1
    [~, order] = sortrows(operation_keys(merged), [1, 2]);
    merged = merged(order);
end
end

function index = find_operation(records, job, operation)
if isempty(records)
    index = 0;
    return
end
matches = find([records.job] == job & ...
    [records.operation] == operation);
if numel(matches) > 1
    error(['identify_stage_c_simultaneous_affected_operations:', ...
        'DuplicateMergedOperation'], ...
        'A merged operation appears more than once.');
end
if isempty(matches)
    index = 0;
else
    index = matches;
end
end

function keys = operation_keys(operations)
if isempty(operations)
    keys = zeros(0, 2);
else
    keys = [[operations.job].', [operations.operation].'];
end
end

function result = validate_impact(impact, state)
result = impact.counts.root_count == ...
    numel(state.fault_in_progress_operations) && ...
    all([impact.root_impacts.is_validated]) && ...
    impact.counts.affected_total + ...
    impact.counts.unaffected_unstarted == ...
    numel(state.unstarted_operations);
keys = operation_keys(impact.affected_operations);
result = result && size(unique(keys, 'rows'), 1) == size(keys, 1);
for index = 1:numel(impact.affected_operations)
    operation = impact.affected_operations(index);
    result = result && operation.projected_delay > 0 && ...
        operation.source_count == ...
        numel(operation.source_event_ids) && ...
        operation.source_count >= 1;
end
if ~result
    error(['identify_stage_c_simultaneous_affected_operations:', ...
        'InvalidImpact'], ...
        'The merged simultaneous-fault impact is inconsistent.');
end
end

function validate_inputs(baseline, state, faults)
isFaultFree = isfield(baseline, 'isFaultFreeBaseline') && ...
    isequal(baseline.isFaultFreeBaseline, true);
isCurrentView = isfield(baseline, 'isCurrentPlanView') && ...
    isequal(baseline.isCurrentPlanView, true);
if (~isFaultFree && ~isCurrentView) || ...
        ~isfield(state, 'is_validated') || ~state.is_validated || ...
        state.is_rescheduled || ~strcmp(state.stage, 'C')
    error(['identify_stage_c_simultaneous_affected_operations:', ...
        'InvalidInput'], ...
        'A validated source baseline and Stage C state are required.');
end
if ~isstruct(faults) || isempty(faults) || ...
        ~all([faults.is_validated]) || ...
        numel(unique([faults.event_group])) ~= 1 || ...
        faults(1).event_group ~= state.event_group || ...
        max(abs([faults.start_time] - state.snapshot_time)) > 1e-9
    error(['identify_stage_c_simultaneous_affected_operations:', ...
        'InvalidFaults'], ...
        'Validated simultaneous faults matching the state are required.');
end
end

function value = operation_template()
value = struct('machine_id', [], 'table_index', [], 'job', [], ...
    'operation', [], 'original_start', [], 'original_end', [], ...
    'duration', []);
end

function value = source_record_template()
value = operation_template();
value.projected_start = [];
value.projected_end = [];
value.projected_delay = [];
value.source_event_ids = [];
value.source_count = [];
value.root_job_successor = false;
value.root_machine_successor = false;
value.job_precedence_conflict = false;
value.machine_sequence_conflict = false;
end

function value = root_impact_template()
record = source_record_template();
value = struct();
value.event_id = [];
value.machine_id = [];
value.job = [];
value.operation = [];
value.original_end = [];
value.revised_end = [];
value.completion_delay = [];
value.affected_operations = record([]);
value.affected_count = [];
value.is_validated = false;
end
