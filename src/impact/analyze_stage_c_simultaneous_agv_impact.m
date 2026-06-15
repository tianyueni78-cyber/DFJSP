function analysis = analyze_stage_c_simultaneous_agv_impact( ...
        baseline, faults, candidate)
%ANALYZE_STAGE_C_SIMULTANEOUS_AGV_IMPACT Identify invalid transports.
%   The machine-only candidate is inspected without changing AGV times,
%   routes, assignments, charging, or energy records.

if nargin < 3
    error('analyze_stage_c_simultaneous_agv_impact:MissingInput', ...
        'baseline, faults, and candidate are required.');
end
validate_inputs(baseline, faults, candidate);

changedOperations = find_changed_operations(candidate.operation_records);
transports = collect_job_transports(baseline.AGVTable);
[directlyAffected, reasons, directSources] = ...
    find_direct_violations(transports, ...
    candidate.operation_records, baseline.problem.operaNumVec);
[sequenceAffected, sequenceSources] = propagate_sequence_review( ...
    transports, directlyAffected, directSources);
needsAdjustment = directlyAffected | sequenceAffected;
affectedTransports = build_affected_transports( ...
    transports, needsAdjustment, directlyAffected, ...
    sequenceAffected, reasons, directSources, sequenceSources);

analysis = struct();
analysis.stage = 'C';
analysis.step = 7;
analysis.event_group = faults(1).event_group;
analysis.fault_event_ids = [faults.event_id];
analysis.interrupted_operations = interrupted_summary( ...
    candidate.interrupted_commitments);
analysis.changed_operations = changedOperations;
analysis.directly_affected_transports = affectedTransports( ...
    [affectedTransports.direct_constraint_violation]);
analysis.sequence_review_transports = affectedTransports( ...
    [affectedTransports.agv_sequence_review]);
analysis.affected_transports = affectedTransports;
analysis.unaffected_transports = transports(~needsAdjustment);
analysis.counts = struct( ...
    'changed_operations', numel(changedOperations), ...
    'directly_affected_transports', ...
    numel(analysis.directly_affected_transports), ...
    'sequence_review_transports', ...
    numel(analysis.sequence_review_transports), ...
    'affected_transports_total', numel(affectedTransports), ...
    'unaffected_transports', sum(~needsAdjustment), ...
    'multi_source_transports', ...
    sum([affectedTransports.source_count] > 1));
analysis.requires_agv_adjustment = ~isempty(affectedTransports);
analysis.source_agv_table_unchanged = ...
    isequaln(candidate.AGVTable, baseline.AGVTable);
analysis.is_agv_updated = false;
analysis.is_validated = validate_analysis( ...
    analysis, transports, candidate);
end

function changed = find_changed_operations(records)
tolerance = 1e-9;
changed = records(abs([records.start] - [records.original_start]) > ...
    tolerance | abs([records.end] - [records.original_end]) > tolerance);
end

function records = collect_job_transports(AGVTable)
template = transport_template();
records = template([]);
for agvId = 1:numel(AGVTable)
    blocks = AGVTable{agvId};
    for tableIndex = 1:numel(blocks)
        block = blocks(tableIndex);
        if block.job <= 0 || block.charge ~= 0 || ...
                ~any(block.load_status == [-1, -2]) || ...
                ~isfinite(block.end)
            continue
        end
        record = template;
        record.agv_id = agvId;
        record.table_index = tableIndex;
        record.job = block.job;
        record.operation = block.opera;
        record.load_status = block.load_status;
        record.transfer_type = transfer_type(block.load_status);
        record.from_machine = block.from_machine;
        record.to_machine = block.to_machine;
        record.start = block.start;
        record.end = block.end;
        records(end + 1) = record;
    end
end
end

function [affected, reasons, sources] = find_direct_violations( ...
        transports, operations, operaNumVec)
tolerance = 1e-9;
affected = false(1, numel(transports));
reasons = cell(1, numel(transports));
sources = repmat({[]}, 1, numel(transports));
for index = 1:numel(reasons)
    reasons{index} = {};
end

for index = 1:numel(transports)
    transport = transports(index);
    if transport.load_status ~= -2
        continue
    end
    if transport.operation == -1
        finalOperation = find_operation(operations, transport.job, ...
            operaNumVec(transport.job));
        if transport.start < finalOperation.end - tolerance
            affected(index) = true;
            reasons{index}{end + 1} = ...
                'final_unload_starts_before_job_completion';
            sources{index} = merge_sources( ...
                sources{index}, finalOperation.source_event_ids);
        end
        continue
    end

    target = find_operation( ...
        operations, transport.job, transport.operation);
    if transport.end > target.start + tolerance
        affected(index) = true;
        reasons{index}{end + 1} = ...
            'loaded_transport_arrives_after_operation_start';
        sources{index} = merge_sources( ...
            sources{index}, target.source_event_ids);
    end
    if transport.operation > 1
        predecessor = find_operation(operations, transport.job, ...
            transport.operation - 1);
        if transport.start < predecessor.end - tolerance
            affected(index) = true;
            reasons{index}{end + 1} = ...
                'loaded_transport_starts_before_predecessor_completion';
            sources{index} = merge_sources( ...
                sources{index}, predecessor.source_event_ids);
        end
    end
    if affected(index) && isempty(sources{index})
        sources{index} = infer_job_sources( ...
            operations, transport.job, transport.operation);
    end
end
end

function sources = infer_job_sources(operations, job, operation)
selected = operations([operations.job] == job & ...
    [operations.operation] <= operation);
sources = [];
for index = 1:numel(selected)
    sources = merge_sources(sources, selected(index).source_event_ids);
end
end

function [sequenceAffected, sequenceSources] = ...
        propagate_sequence_review(transports, directlyAffected, ...
        directSources)
sequenceAffected = false(1, numel(transports));
sequenceSources = repmat({[]}, 1, numel(transports));
for directIndex = find(directlyAffected)
    sameAgvLater = find([transports.agv_id] == ...
        transports(directIndex).agv_id & ...
        [transports.table_index] > transports(directIndex).table_index);
    sameTransportGroup = find([transports.agv_id] == ...
        transports(directIndex).agv_id & ...
        [transports.job] == transports(directIndex).job & ...
        [transports.operation] == transports(directIndex).operation);
    targets = unique([sameAgvLater, sameTransportGroup]);
    targets(targets == directIndex) = [];
    for target = targets
        sequenceAffected(target) = true;
        sequenceSources{target} = merge_sources( ...
            sequenceSources{target}, directSources{directIndex});
    end
end
sequenceAffected(directlyAffected) = false;
end

function records = build_affected_transports(transports, affected, ...
        directlyAffected, sequenceAffected, reasons, directSources, ...
        sequenceSources)
template = affected_transport_template();
indices = find(affected);
records = repmat(template, 1, numel(indices));
sourceFields = fieldnames(transport_template());
for outputIndex = 1:numel(indices)
    sourceIndex = indices(outputIndex);
    for fieldIndex = 1:numel(sourceFields)
        field = sourceFields{fieldIndex};
        records(outputIndex).(field) = transports(sourceIndex).(field);
    end
    records(outputIndex).direct_constraint_violation = ...
        directlyAffected(sourceIndex);
    records(outputIndex).agv_sequence_review = ...
        sequenceAffected(sourceIndex);
    records(outputIndex).reasons = reasons{sourceIndex};
    if sequenceAffected(sourceIndex)
        records(outputIndex).reasons{end + 1} = ...
            'follows_affected_task_on_same_agv';
    end
    records(outputIndex).source_event_ids = merge_sources( ...
        directSources{sourceIndex}, sequenceSources{sourceIndex});
    records(outputIndex).source_count = ...
        numel(records(outputIndex).source_event_ids);
end
end

function result = validate_analysis(analysis, transports, candidate)
if analysis.counts.affected_transports_total + ...
        analysis.counts.unaffected_transports ~= numel(transports)
    error(['analyze_stage_c_simultaneous_agv_impact:', ...
        'PartitionMismatch'], ...
        'Affected and unaffected sets must partition all transports.');
end
keys = transport_keys(analysis.affected_transports);
if size(unique(keys, 'rows'), 1) ~= size(keys, 1)
    error(['analyze_stage_c_simultaneous_agv_impact:', ...
        'DuplicateAffectedTransport'], ...
        'An affected AGV task appears more than once.');
end
if analysis.counts.changed_operations == 0 && ...
        analysis.requires_agv_adjustment
    error(['analyze_stage_c_simultaneous_agv_impact:', ...
        'UnexpectedAdjustment'], ...
        'No operation changed, so no AGV adjustment is expected.');
end
if candidate.is_agv_updated
    error(['analyze_stage_c_simultaneous_agv_impact:', ...
        'AGVAlreadyUpdated'], ...
        'Stage C Step 7 requires the original AGV table.');
end
for index = 1:numel(analysis.affected_transports)
    transport = analysis.affected_transports(index);
    if ~(transport.direct_constraint_violation || ...
            transport.agv_sequence_review) || ...
            isempty(transport.reasons) || ...
            transport.source_count ~= ...
            numel(transport.source_event_ids) || ...
            transport.source_count < 1
        error(['analyze_stage_c_simultaneous_agv_impact:', ...
            'InvalidAffectedTransport'], ...
            'Every affected transport requires reasons and sources.');
    end
end
result = analysis.source_agv_table_unchanged && ...
    ~analysis.is_agv_updated;
end

function keys = transport_keys(transports)
if isempty(transports)
    keys = zeros(0, 2);
else
    keys = [[transports.agv_id].', [transports.table_index].'];
end
end

function summaries = interrupted_summary(commitments)
template = struct('event_ids', [], 'machine_id', [], 'job', [], ...
    'operation', [], 'revised_completion_time', []);
summaries = repmat(template, 1, numel(commitments));
for index = 1:numel(commitments)
    summaries(index).event_ids = commitments(index).event_ids;
    summaries(index).machine_id = commitments(index).machine_id;
    summaries(index).job = commitments(index).job;
    summaries(index).operation = commitments(index).operation;
    summaries(index).revised_completion_time = ...
        commitments(index).revised_completion_time;
end
end

function operation = find_operation(records, job, operationId)
match = find([records.job] == job & ...
    [records.operation] == operationId);
if numel(match) ~= 1
    error(['analyze_stage_c_simultaneous_agv_impact:', ...
        'OperationNotUnique'], ...
        'Operation J%d-O%d must appear exactly once.', ...
        job, operationId);
end
operation = records(match);
end

function value = merge_sources(first, second)
value = unique([first, second]);
end

function value = transfer_type(loadStatus)
if loadStatus == -1
    value = 'empty';
else
    value = 'loaded';
end
end

function value = transport_template()
value = struct('agv_id', [], 'table_index', [], 'job', [], ...
    'operation', [], 'load_status', [], 'transfer_type', '', ...
    'from_machine', [], 'to_machine', [], 'start', [], 'end', []);
end

function value = affected_transport_template()
value = transport_template();
value.direct_constraint_violation = false;
value.agv_sequence_review = false;
value.reasons = {};
value.source_event_ids = [];
value.source_count = [];
end

function validate_inputs(baseline, faults, candidate)
require_fields(baseline, {'AGVTable', 'problem', ...
    'isFaultFreeBaseline'}, 'baseline');
require_fields(baseline.problem, {'operaNumVec'}, 'baseline.problem');
require_fields(candidate, {'stage', 'step', 'operation_records', ...
    'interrupted_commitments', 'AGVTable', ...
    'is_machine_validated', 'is_agv_updated'}, 'candidate');
for index = 1:numel(faults)
    require_fields(faults(index), {'event_id', 'stage', ...
        'machine_id', 'event_group', 'is_validated'}, 'faults');
end
if ~baseline.isFaultFreeBaseline || numel(faults) < 2 || ...
        ~all([faults.is_validated]) || ...
        ~all(strcmp({faults.stage}, 'C')) || ...
        numel(unique([faults.event_group])) ~= 1 || ...
        ~candidate.is_machine_validated || ...
        ~strcmp(candidate.stage, 'C') || candidate.step ~= 6 || ...
        candidate.is_agv_updated || ...
        ~isequaln(candidate.AGVTable, baseline.AGVTable)
    error('analyze_stage_c_simultaneous_agv_impact:InvalidInput', ...
        'Validated Stage C Step 6 inputs are required.');
end
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('analyze_stage_c_simultaneous_agv_impact:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
