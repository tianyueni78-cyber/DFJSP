function context = build_stage_c_sequential_impact_context(stage13)
%BUILD_STAGE_C_SEQUENTIAL_IMPACT_CONTEXT Build Stage C Step 14 context.
%   Cumulative repairs retain every event. Only historical effects still
%   active at the next event time are eligible for impact merging.

if nargin < 1 || stage13.step ~= 13 || ~stage13.is_validated
    error('build_stage_c_sequential_impact_context:InvalidInput', ...
        'A validated Stage C Step 13 scenario is required.');
end

currentView = stage13.next_fault_state.current_plan_view;
state = stage13.next_fault_state.state;
nextFault = stage13.next_fault;
cumulativeFaults = [stage13.faults, nextFault];
cumulativeUnavailability = build_stage_c_machine_unavailability( ...
    cumulativeFaults, stage13.baseline.problem.machineNum);
newImpact = identify_stage_c_simultaneous_affected_operations( ...
    currentView, state, nextFault);

historical = active_historical_impacts(stage13, state.snapshot_time, ...
    state.unstarted_operations);
merged = merge_impacts(historical, newImpact.affected_operations);
unaffected = remove_affected( ...
    state.unstarted_operations, merged);

context = struct();
context.stage = 'C';
context.step = 14;
context.input_version_id = ...
    stage13.next_fault_state.input_version_id;
context.cumulative_faults = cumulativeFaults;
context.cumulative_unavailability = cumulativeUnavailability;
context.new_event_impact = newImpact;
context.active_historical_impacts = historical;
context.merged_affected_operations = merged;
context.unaffected_unstarted_operations = unaffected;
context.counts = struct( ...
    'cumulative_faults', numel(cumulativeFaults), ...
    'cumulative_repair_intervals', ...
    cumulativeUnavailability.interval_count, ...
    'active_historical_affected', numel(historical), ...
    'new_event_affected', numel(newImpact.affected_operations), ...
    'merged_affected', numel(merged), ...
    'multi_source_operations', sum([merged.source_count] > 1), ...
    'unaffected_unstarted', numel(unaffected));
context.merge_rule = ...
    'maximum projected start/end with all active event sources preserved';
context.history_unchanged = true;
context.is_plan_modified = false;
context.is_rescheduled = false;
context.is_validated = validate_context(context, state);
end

function records = active_historical_impacts(stage13, snapshotTime, unstarted)
template = impact_template();
records = template([]);
% The selected V1 plan already contains the previous fault response.
% Only explicitly persisted pending impacts may cross into the next event.
if ~isfield(stage13, 'pending_impact_records')
    return
end
unstartedKeys = operation_keys(unstarted);
historical = stage13.pending_impact_records;
for index = 1:numel(historical)
    source = historical(index);
    key = [source.job, source.operation];
    if source.projected_end <= snapshotTime + 1e-9 || ...
            ~ismember(key, unstartedKeys, 'rows')
        continue
    end
    records(end + 1) = normalize_impact(source);
end
end

function merged = merge_impacts(historical, current)
template = impact_template();
merged = template([]);
sources = [historical, current];
for index = 1:numel(sources)
    record = normalize_impact(sources(index));
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
        merged(match).projected_start - merged(match).original_start;
    merged(match).source_event_ids = unique( ...
        [merged(match).source_event_ids, record.source_event_ids], ...
        'stable');
    merged(match).source_count = ...
        numel(merged(match).source_event_ids);
    merged(match).root_job_successor = ...
        merged(match).root_job_successor || record.root_job_successor;
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
if numel(merged) > 1
    [~, order] = sortrows(operation_keys(merged), [1, 2]);
    merged = merged(order);
end
end

function value = normalize_impact(source)
value = impact_template();
fields = fieldnames(value);
for index = 1:numel(fields)
    field = fields{index};
    if isfield(source, field)
        value.(field) = source.(field);
    end
end
value.source_event_ids = unique(value.source_event_ids, 'stable');
value.source_count = numel(value.source_event_ids);
end

function unaffected = remove_affected(unstarted, affected)
if isempty(affected)
    unaffected = unstarted;
    return
end
unaffected = unstarted(~ismember( ...
    operation_keys(unstarted), operation_keys(affected), 'rows'));
end

function index = find_operation(records, jobId, operationId)
if isempty(records)
    index = 0;
    return
end
match = find([records.job] == jobId & ...
    [records.operation] == operationId);
if numel(match) > 1
    error('build_stage_c_sequential_impact_context:DuplicateOperation', ...
        'J%d-O%d appears more than once.', jobId, operationId);
end
if isempty(match)
    index = 0;
else
    index = match;
end
end

function keys = operation_keys(records)
if isempty(records)
    keys = zeros(0, 2);
else
    keys = [[records.job].', [records.operation].'];
end
end

function result = validate_context(context, state)
keys = operation_keys(context.merged_affected_operations);
allEventIds = [context.cumulative_faults.event_id];
result = context.cumulative_unavailability.is_validated && ...
    context.new_event_impact.is_validated && ...
    size(unique(keys, 'rows'), 1) == size(keys, 1) && ...
    context.counts.merged_affected + ...
    context.counts.unaffected_unstarted == ...
    numel(state.unstarted_operations);
for index = 1:numel(context.merged_affected_operations)
    operation = context.merged_affected_operations(index);
    result = result && operation.projected_delay > 0 && ...
        operation.source_count == ...
        numel(operation.source_event_ids) && ...
        all(ismember(operation.source_event_ids, allEventIds));
end
if ~result
    error('build_stage_c_sequential_impact_context:InvalidContext', ...
        'Sequential repair and impact context is inconsistent.');
end
end

function value = impact_template()
value = struct('machine_id', [], 'table_index', [], 'job', [], ...
    'operation', [], 'original_start', [], 'original_end', [], ...
    'duration', [], 'projected_start', [], 'projected_end', [], ...
    'projected_delay', [], 'source_event_ids', [], ...
    'source_count', [], 'root_job_successor', false, ...
    'root_machine_successor', false, ...
    'job_precedence_conflict', false, ...
    'machine_sequence_conflict', false);
end
