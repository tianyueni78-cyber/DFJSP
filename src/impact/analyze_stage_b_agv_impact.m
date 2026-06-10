function analysis = analyze_stage_b_agv_impact( ...
        baseline, fault, candidate)
%ANALYZE_STAGE_B_AGV_IMPACT Identify transports invalidated by Step 4.
%   The baseline AGV table is read only. Direct violations include a
%   loaded transport leaving before its predecessor completes, arriving
%   after its target operation starts, or final unloading starting before
%   the job completes. Later tasks on the same AGV are marked for review.

if nargin < 3
    error('analyze_stage_b_agv_impact:MissingInput', ...
        'baseline, fault, and candidate are required.');
end
require_fields(baseline, {'AGVTable', 'problem', ...
    'isFaultFreeBaseline'}, 'baseline');
require_fields(baseline.problem, {'operaNumVec'}, 'baseline.problem');
require_fields(fault, {'stage', 'machine_id', 'start_time', ...
    'repair_end_time', 'is_validated'}, 'fault');
require_fields(candidate, {'stage', 'step', 'operation_records', ...
    'resume_plan', 'AGVTable', 'is_machine_validated', ...
    'is_agv_updated'}, 'candidate');
validate_inputs(baseline, fault, candidate);

changedOperations = find_changed_operations(candidate.operation_records);
transportRecords = collect_job_transports(baseline.AGVTable);
[directlyAffected, reasons] = find_direct_transport_violations( ...
    transportRecords, candidate.operation_records, ...
    baseline.problem.operaNumVec);
sequenceAffected = propagate_agv_sequence_review( ...
    transportRecords, directlyAffected);
needsAdjustment = directlyAffected | sequenceAffected;

affectedTransports = build_affected_transports( ...
    transportRecords, needsAdjustment, directlyAffected, ...
    sequenceAffected, reasons);
unaffectedTransports = transportRecords(~needsAdjustment);
interruptedJobTransports = affectedTransports( ...
    [affectedTransports.job] == candidate.resume_plan.job);

analysis = struct();
analysis.stage = 'B';
analysis.step = 5;
analysis.interrupted_operation = struct( ...
    'machine_id', candidate.resume_plan.machine_id, ...
    'job', candidate.resume_plan.job, ...
    'operation', candidate.resume_plan.operation, ...
    'revised_completion_time', ...
    candidate.resume_plan.revised_completion_time);
analysis.changed_operations = changedOperations;
analysis.directly_affected_transports = affectedTransports( ...
    [affectedTransports.direct_constraint_violation]);
analysis.interrupted_job_affected_transports = interruptedJobTransports;
analysis.affected_transports = affectedTransports;
analysis.unaffected_transports = unaffectedTransports;
analysis.counts = struct( ...
    'changed_operations', numel(changedOperations), ...
    'directly_affected_transports', ...
    numel(analysis.directly_affected_transports), ...
    'interrupted_job_affected_transports', ...
    numel(interruptedJobTransports), ...
    'affected_transports_total', numel(affectedTransports), ...
    'unaffected_transports', numel(unaffectedTransports));
analysis.requires_agv_adjustment = ~isempty(affectedTransports);
analysis.source_agv_table_unchanged = ...
    isequaln(candidate.AGVTable, baseline.AGVTable);
analysis.is_agv_updated = false;
analysis.is_validated = validate_analysis( ...
    analysis, transportRecords, candidate);
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

function [affected, reasons] = find_direct_transport_violations( ...
        transports, operations, operaNumVec)
tolerance = 1e-9;
affected = false(1, numel(transports));
reasons = repmat({''}, 1, numel(transports));

for index = 1:numel(transports)
    transport = transports(index);
    if transport.load_status ~= -2
        continue
    end

    if transport.operation == -1
        lastOperation = find_operation(operations, transport.job, ...
            operaNumVec(transport.job));
        if transport.start < lastOperation.end - tolerance
            affected(index) = true;
            reasons{index} = ...
                'final_unload_starts_before_job_completion';
        end
        continue
    end

    target = find_operation( ...
        operations, transport.job, transport.operation);
    if transport.end > target.start + tolerance
        affected(index) = true;
        reasons{index} = ...
            'loaded_transport_arrives_after_operation_start';
        continue
    end

    if transport.operation > 1
        predecessor = find_operation( ...
            operations, transport.job, transport.operation - 1);
        if transport.start < predecessor.end - tolerance
            affected(index) = true;
            reasons{index} = ...
                'loaded_transport_starts_before_predecessor_completion';
        end
    end
end
end

function sequenceAffected = propagate_agv_sequence_review( ...
        transports, directlyAffected)
sequenceAffected = false(1, numel(transports));
for directIndex = find(directlyAffected)
    sameAgvLater = [transports.agv_id] == ...
        transports(directIndex).agv_id & ...
        [transports.table_index] > transports(directIndex).table_index;
    sequenceAffected = sequenceAffected | sameAgvLater;

    sameTransportGroup = [transports.agv_id] == ...
        transports(directIndex).agv_id & ...
        [transports.job] == transports(directIndex).job & ...
        [transports.operation] == transports(directIndex).operation;
    sequenceAffected = sequenceAffected | sameTransportGroup;
end
sequenceAffected(directlyAffected) = false;
end

function records = build_affected_transports(transports, affected, ...
        directlyAffected, sequenceAffected, reasons)
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
    records(outputIndex).reason = reasons{sourceIndex};
    if sequenceAffected(sourceIndex) && isempty(records(outputIndex).reason)
        records(outputIndex).reason = ...
            'follows_affected_task_on_same_agv';
    end
end
end

function result = validate_analysis(analysis, transports, candidate)
if analysis.counts.affected_transports_total + ...
        analysis.counts.unaffected_transports ~= numel(transports)
    error('analyze_stage_b_agv_impact:PartitionMismatch', ...
        'Affected and unaffected sets must partition all transports.');
end
if analysis.counts.changed_operations == 0 && ...
        analysis.requires_agv_adjustment
    error('analyze_stage_b_agv_impact:UnexpectedAdjustment', ...
        'No operation changed, so no AGV adjustment should be required.');
end
if candidate.is_agv_updated
    error('analyze_stage_b_agv_impact:AGVAlreadyUpdated', ...
        'Step 5 requires the unmodified baseline AGV table.');
end
for index = 1:numel(analysis.affected_transports)
    transport = analysis.affected_transports(index);
    if ~(transport.direct_constraint_violation || ...
            transport.agv_sequence_review) || isempty(transport.reason)
        error('analyze_stage_b_agv_impact:MissingImpactReason', ...
            'Every affected transport must have an impact source.');
    end
end
result = true;
end

function operation = find_operation(records, jobId, operationId)
match = find([records.job] == jobId & ...
    [records.operation] == operationId);
if numel(match) ~= 1
    error('analyze_stage_b_agv_impact:OperationNotUnique', ...
        'Operation J%d-O%d must appear exactly once.', ...
        jobId, operationId);
end
operation = records(match);
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
value.reason = '';
end

function validate_inputs(baseline, fault, candidate)
tolerance = 1e-9;
if ~baseline.isFaultFreeBaseline || ~fault.is_validated || ...
        ~candidate.is_machine_validated || ...
        ~strcmp(fault.stage, 'B') || ~strcmp(candidate.stage, 'B') || ...
        candidate.step ~= 4
    error('analyze_stage_b_agv_impact:InvalidInput', ...
        'Validated Stage B Step 4 inputs are required.');
end
if candidate.is_agv_updated || ...
        ~isequaln(candidate.AGVTable, baseline.AGVTable)
    error('analyze_stage_b_agv_impact:AGVTableChanged', ...
        'Candidate AGVTable must equal the baseline table.');
end
if candidate.resume_plan.machine_id ~= fault.machine_id || ...
        abs(candidate.resume_plan.repair_interval.start_time - ...
        fault.start_time) > tolerance || ...
        abs(candidate.resume_plan.repair_interval.end_time - ...
        fault.repair_end_time) > tolerance
    error('analyze_stage_b_agv_impact:FaultMismatch', ...
        'Candidate resume plan does not match the fault event.');
end
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('analyze_stage_b_agv_impact:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
