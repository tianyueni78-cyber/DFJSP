function candidate = build_stage_c_simultaneous_machine_right_shift( ...
        baseline, faults, state, impact)
%BUILD_STAGE_C_SIMULTANEOUS_MACHINE_RIGHT_SHIFT Build machine candidate.
%   Every interrupted operation preserves completed progress and resumes
%   its remaining processing on the original machine after repair.
%   Projected successor times from Stage C Step 5 are written into a
%   copied machine schedule. AGV tasks remain unchanged.

if nargin < 4
    error('build_stage_c_simultaneous_machine_right_shift:MissingInput', ...
        'baseline, faults, state, and impact are required.');
end
validate_inputs(baseline, faults, state, impact);

records = collect_operations(baseline.machineTable);
[records, commitments] = apply_interrupted_commitments( ...
    records, faults, state.fault_in_progress_operations);
records = apply_affected_times(records, impact.affected_operations);
segments = build_processing_segments(records, commitments);
machineTable = rebuild_machine_table( ...
    segments, numel(baseline.machineTable));
validation = validate_candidate(baseline, faults, impact, ...
    commitments, records, segments, machineTable);

candidate = struct();
candidate.strategy = 'partial_right_shift';
candidate.stage = 'C';
candidate.step = 6;
candidate.interruption_rule = 'resume_remaining';
candidate.machineTable = machineTable;
candidate.AGVTable = baseline.AGVTable;
candidate.operation_records = records;
candidate.processing_segments = segments;
candidate.interrupted_commitments = commitments;
candidate.unavailable_intervals = build_unavailable_intervals(faults);
candidate.machine_makespan = max([records.end]);
candidate.validation = validation;
candidate.is_machine_validated = true;
candidate.is_agv_updated = false;
candidate.is_agv_validated = false;
candidate.is_fully_validated = false;
end

function records = collect_operations(machineTable)
template = operation_template();
records = template([]);
for machineId = 1:numel(machineTable)
    blocks = machineTable{machineId};
    for tableIndex = 1:numel(blocks)
        block = blocks(tableIndex);
        if block.job <= 0 || block.opera <= 0 || ~isfinite(block.end)
            continue
        end
        record = template;
        record.machine_id = machineId;
        record.original_table_index = tableIndex;
        record.job = block.job;
        record.operation = block.opera;
        record.original_start = block.start;
        record.original_end = block.end;
        record.start = block.start;
        record.end = block.end;
        record.processing_duration = block.end - block.start;
        record.calendar_span = block.end - block.start;
        records(end + 1) = record;
    end
end
end

function [records, commitments] = apply_interrupted_commitments( ...
        records, faults, interrupted)
template = commitment_template();
commitments = repmat(template, 1, numel(interrupted));
for index = 1:numel(interrupted)
    root = interrupted(index);
    fault = find_root_fault(faults, root);
    match = find_operation(records, root.job, root.operation);
    if records(match).machine_id ~= fault.machine_id
        error(['build_stage_c_simultaneous_machine_right_shift:', ...
            'InterruptedMachineChanged'], ...
            'An interrupted operation must resume on its original machine.');
    end

    commitment = template;
    commitment.event_ids = root.source_event_ids;
    commitment.machine_id = root.machine_id;
    commitment.job = root.job;
    commitment.operation = root.operation;
    commitment.original_start = root.start;
    commitment.original_end = root.end;
    commitment.original_duration = root.original_duration;
    commitment.completed_segment = segment_value( ...
        root, root.start, fault.start_time, ...
        'processed_before_fault');
    commitment.resumed_segment = segment_value( ...
        root, fault.repair_end_time, ...
        fault.repair_end_time + root.remaining_processing_time, ...
        'resumed_after_repair');
    commitment.revised_completion_time = ...
        commitment.resumed_segment.end;
    commitment.is_validated = validate_commitment( ...
        commitment, root, fault);
    commitments(index) = commitment;

    records(match).end = commitment.revised_completion_time;
    records(match).calendar_span = ...
        records(match).end - records(match).start;
    records(match).is_affected = true;
    records(match).is_interrupted = true;
    records(match).source_event_ids = commitment.event_ids;
end
end

function fault = find_root_fault(faults, root)
matches = find([faults.machine_id] == root.machine_id & ...
    ismember([faults.event_id], root.source_event_ids));
if numel(matches) ~= 1
    error(['build_stage_c_simultaneous_machine_right_shift:', ...
        'RootFaultMismatch'], ...
        'Each interrupted operation must match exactly one fault.');
end
fault = faults(matches);
end

function segment = segment_value(root, startTime, endTime, segmentType)
segment = segment_template();
segment.machine_id = root.machine_id;
segment.original_table_index = root.table_index;
segment.segment_order = double(strcmp(segmentType, ...
    'resumed_after_repair')) + 1;
segment.segment_type = segmentType;
segment.job = root.job;
segment.operation = root.operation;
segment.start = startTime;
segment.end = endTime;
segment.processing_time = endTime - startTime;
segment.source_event_ids = root.source_event_ids;
end

function result = validate_commitment(commitment, root, fault)
tolerance = 1e-9;
result = strcmp(fault.interruption_rule, 'resume_remaining') && ...
    commitment.completed_segment.start == root.start && ...
    abs(commitment.completed_segment.end - fault.start_time) <= ...
    tolerance && ...
    abs(commitment.resumed_segment.start - ...
    fault.repair_end_time) <= tolerance && ...
    abs(commitment.resumed_segment.processing_time - ...
    root.remaining_processing_time) <= tolerance && ...
    abs(commitment.completed_segment.processing_time + ...
    commitment.resumed_segment.processing_time - ...
    root.original_duration) <= tolerance;
if ~result
    error(['build_stage_c_simultaneous_machine_right_shift:', ...
        'InvalidCommitment'], ...
        'An interrupted-operation commitment is inconsistent.');
end
end

function records = apply_affected_times(records, affected)
for index = 1:numel(affected)
    source = affected(index);
    match = find_operation(records, source.job, source.operation);
    if records(match).machine_id ~= source.machine_id
        error(['build_stage_c_simultaneous_machine_right_shift:', ...
            'MachineChanged'], ...
            'Partial right shift cannot change machine assignment.');
    end
    if records(match).is_interrupted
        error(['build_stage_c_simultaneous_machine_right_shift:', ...
            'RootDuplicated'], ...
            'An interrupted root must not appear in the successor set.');
    end
    records(match).start = source.projected_start;
    records(match).end = source.projected_end;
    records(match).calendar_span = source.projected_end - ...
        source.projected_start;
    records(match).is_affected = true;
    records(match).source_event_ids = source.source_event_ids;
end
end

function segments = build_processing_segments(records, commitments)
template = segment_template();
segments = template([]);
for index = 1:numel(records)
    record = records(index);
    if record.is_interrupted
        commitment = find_commitment( ...
            commitments, record.job, record.operation);
        segments(end + 1) = commitment.completed_segment;
        segments(end + 1) = commitment.resumed_segment;
        continue
    end
    segment = template;
    segment.machine_id = record.machine_id;
    segment.original_table_index = record.original_table_index;
    segment.segment_order = 1;
    segment.segment_type = 'complete_operation';
    segment.job = record.job;
    segment.operation = record.operation;
    segment.start = record.start;
    segment.end = record.end;
    segment.processing_time = record.processing_duration;
    segment.source_event_ids = record.source_event_ids;
    segments(end + 1) = segment;
end
end

function commitment = find_commitment(commitments, job, operation)
matches = find([commitments.job] == job & ...
    [commitments.operation] == operation);
if numel(matches) ~= 1
    error(['build_stage_c_simultaneous_machine_right_shift:', ...
        'CommitmentNotUnique'], ...
        'Each interrupted operation requires one commitment.');
end
commitment = commitments(matches);
end

function machineTable = rebuild_machine_table(segments, machineCount)
machineTable = cell(1, machineCount);
for machineId = 1:machineCount
    indices = find([segments.machine_id] == machineId);
    if isempty(indices)
        machineTable{machineId} = idle_block(0, Inf);
        continue
    end
    ordering = [[segments(indices).start].', ...
        [segments(indices).original_table_index].', ...
        [segments(indices).segment_order].'];
    [~, order] = sortrows(ordering, [1, 2, 3]);
    ordered = segments(indices(order));
    template = machine_block_template();
    blocks = template([]);
    cursor = 0;
    for index = 1:numel(ordered)
        if ordered(index).start > cursor
            blocks(end + 1) = idle_block(cursor, ordered(index).start);
        end
        blocks(end + 1) = operation_block(ordered(index));
        cursor = ordered(index).end;
    end
    blocks(end + 1) = idle_block(cursor, Inf);
    machineTable{machineId} = blocks;
end
end

function validation = validate_candidate(baseline, faults, impact, ...
        commitments, records, segments, machineTable)
tolerance = 1e-9;
validate_operation_identity(baseline.machineTable, records, tolerance);
validate_commitments(commitments, records, segments, tolerance);
validate_affected_times(records, impact.affected_operations, ...
    commitments, tolerance);
validate_machine_non_overlap(segments, numel(machineTable), tolerance);
validate_machine_table_structure(machineTable, tolerance);
validate_job_precedence(records, baseline.problem.operaNumVec, tolerance);
validate_repair_intervals(segments, faults, tolerance);

validation = struct();
validation.operation_identity_preserved = true;
validation.machine_assignments_preserved = true;
validation.processing_durations_preserved = true;
validation.interrupted_operations_split = true;
validation.resume_commitments_respected = true;
validation.affected_times_applied = true;
validation.unaffected_operations_preserved = true;
validation.machine_non_overlap = true;
validation.machine_table_structure = true;
validation.job_precedence = true;
validation.repair_intervals_respected = true;
end

function validate_operation_identity(baselineTable, records, tolerance)
source = collect_operations(baselineTable);
if numel(source) ~= numel(records)
    error(['build_stage_c_simultaneous_machine_right_shift:', ...
        'OperationCountChanged'], ...
        'The candidate must preserve every logical operation.');
end
for index = 1:numel(source)
    match = find_operation(records, source(index).job, ...
        source(index).operation);
    if records(match).machine_id ~= source(index).machine_id || ...
            abs(records(match).processing_duration - ...
            source(index).processing_duration) > tolerance
        error(['build_stage_c_simultaneous_machine_right_shift:', ...
            'OperationIdentityChanged'], ...
            'Machine assignment or processing duration changed.');
    end
end
end

function validate_commitments(commitments, records, segments, tolerance)
for index = 1:numel(commitments)
    commitment = commitments(index);
    match = find_operation(records, commitment.job, ...
        commitment.operation);
    if ~records(match).is_interrupted || ...
            abs(records(match).end - ...
            commitment.revised_completion_time) > tolerance
        error(['build_stage_c_simultaneous_machine_right_shift:', ...
            'CommitmentTimeMismatch'], ...
            'Interrupted logical operation violates its commitment.');
    end
    selected = segments([segments.job] == commitment.job & ...
        [segments.operation] == commitment.operation);
    if numel(selected) ~= 2 || ...
            abs(sum([selected.processing_time]) - ...
            commitment.original_duration) > tolerance
        error(['build_stage_c_simultaneous_machine_right_shift:', ...
            'CommitmentSegmentMismatch'], ...
            'Interrupted operation must contain two valid segments.');
    end
end
end

function validate_affected_times(records, affected, commitments, tolerance)
for index = 1:numel(records)
    record = records(index);
    if any([commitments.job] == record.job & ...
            [commitments.operation] == record.operation)
        continue
    end
    match = find([affected.job] == record.job & ...
        [affected.operation] == record.operation);
    if isempty(match)
        valid = abs(record.start - record.original_start) <= tolerance && ...
            abs(record.end - record.original_end) <= tolerance;
    else
        valid = numel(match) == 1 && ...
            abs(record.start - affected(match).projected_start) <= ...
            tolerance && ...
            abs(record.end - affected(match).projected_end) <= tolerance;
    end
    if ~valid
        error(['build_stage_c_simultaneous_machine_right_shift:', ...
            'OperationTimeMismatch'], ...
            'Affected or unaffected operation time is inconsistent.');
    end
end
end

function validate_machine_non_overlap(segments, machineCount, tolerance)
for machineId = 1:machineCount
    selected = segments([segments.machine_id] == machineId);
    if numel(selected) < 2
        continue
    end
    ordering = [[selected.start].', [selected.end].'];
    [~, order] = sortrows(ordering, [1, 2]);
    selected = selected(order);
    for index = 1:numel(selected) - 1
        if selected(index).end > selected(index + 1).start + tolerance
            error(['build_stage_c_simultaneous_machine_right_shift:', ...
                'MachineOverlap'], ...
                'Machine %d has overlapping processing segments.', ...
                machineId);
        end
    end
end
end

function validate_machine_table_structure(machineTable, tolerance)
for machineId = 1:numel(machineTable)
    blocks = machineTable{machineId};
    if isempty(blocks) || abs(blocks(1).start) > tolerance || ...
            ~isinf(blocks(end).end) || blocks(end).job ~= 0
        error(['build_stage_c_simultaneous_machine_right_shift:', ...
            'InvalidMachineTable'], ...
            'Machine %d has invalid boundary blocks.', machineId);
    end
    for index = 1:numel(blocks) - 1
        if abs(blocks(index).end - blocks(index + 1).start) > tolerance
            error(['build_stage_c_simultaneous_machine_right_shift:', ...
                'InvalidMachineTable'], ...
                'Machine %d has a gap or overlap.', machineId);
        end
    end
end
end

function validate_job_precedence(records, operaNumVec, tolerance)
for job = 1:numel(operaNumVec)
    for operation = 1:operaNumVec(job) - 1
        current = records(find_operation(records, job, operation));
        successor = records(find_operation(records, job, operation + 1));
        if current.end > successor.start + tolerance
            error(['build_stage_c_simultaneous_machine_right_shift:', ...
                'JobPrecedence'], ...
                'J%d-O%d finishes after its successor starts.', ...
                job, operation);
        end
    end
end
end

function validate_repair_intervals(segments, faults, tolerance)
for faultIndex = 1:numel(faults)
    fault = faults(faultIndex);
    selected = segments([segments.machine_id] == fault.machine_id);
    for index = 1:numel(selected)
        overlaps = selected(index).start < ...
            fault.repair_end_time - tolerance && ...
            fault.start_time < selected(index).end - tolerance;
        if overlaps
            error(['build_stage_c_simultaneous_machine_right_shift:', ...
                'RepairOverlap'], ...
                'Machine %d processes during repair.', fault.machine_id);
        end
    end
end
end

function intervals = build_unavailable_intervals(faults)
template = struct('event_id', [], 'machine_id', [], ...
    'start_time', [], 'end_time', []);
intervals = repmat(template, 1, numel(faults));
for index = 1:numel(faults)
    intervals(index).event_id = faults(index).event_id;
    intervals(index).machine_id = faults(index).machine_id;
    intervals(index).start_time = faults(index).start_time;
    intervals(index).end_time = faults(index).repair_end_time;
end
end

function index = find_operation(records, job, operation)
index = find([records.job] == job & ...
    [records.operation] == operation);
if numel(index) ~= 1
    error(['build_stage_c_simultaneous_machine_right_shift:', ...
        'OperationNotUnique'], ...
        'Operation J%d-O%d must appear exactly once.', job, operation);
end
end

function validate_inputs(baseline, faults, state, impact)
requiredBaseline = {'machineTable', 'AGVTable', 'problem', ...
    'isFaultFreeBaseline'};
require_fields(baseline, requiredBaseline, 'baseline');
require_fields(state, {'stage', 'fault_in_progress_operations', ...
    'is_validated', 'is_rescheduled'}, 'state');
require_fields(impact, {'stage', 'step', 'affected_operations', ...
    'baseline_modified', 'is_rescheduled', 'is_validated'}, 'impact');
for index = 1:numel(faults)
    require_fields(faults(index), {'event_id', 'stage', ...
        'trigger_type', 'machine_id', 'start_time', ...
        'repair_end_time', 'interruption_rule', 'event_group', ...
        'is_validated'}, 'faults');
end
if ~baseline.isFaultFreeBaseline || ~state.is_validated || ...
        state.is_rescheduled || ~impact.is_validated || ...
        impact.step ~= 5 || impact.baseline_modified || ...
        impact.is_rescheduled || ~strcmp(state.stage, 'C') || ...
        ~strcmp(impact.stage, 'C') || numel(faults) < 2 || ...
        ~all([faults.is_validated]) || ...
        ~all(strcmp({faults.stage}, 'C')) || ...
        ~all(strcmp({faults.trigger_type}, 'machine_failure')) || ...
        ~all(strcmp({faults.interruption_rule}, 'resume_remaining')) || ...
        numel(unique([faults.machine_id])) ~= numel(faults) || ...
        numel(unique([faults.event_group])) ~= 1 || ...
        max(abs([faults.start_time] - faults(1).start_time)) > 1e-9 || ...
        numel(state.fault_in_progress_operations) ~= numel(faults)
    error(['build_stage_c_simultaneous_machine_right_shift:', ...
        'InvalidInput'], ...
        'Validated Stage C Step 5 simultaneous-fault inputs are required.');
end
end

function value = operation_template()
value = struct('machine_id', [], 'original_table_index', [], ...
    'job', [], 'operation', [], 'original_start', [], ...
    'original_end', [], 'start', [], 'end', [], ...
    'processing_duration', [], 'calendar_span', [], ...
    'is_affected', false, 'is_interrupted', false, ...
    'source_event_ids', []);
end

function value = segment_template()
value = struct('machine_id', [], 'original_table_index', [], ...
    'segment_order', [], 'segment_type', '', 'job', [], ...
    'operation', [], 'start', [], 'end', [], ...
    'processing_time', [], 'source_event_ids', []);
end

function value = commitment_template()
segment = segment_template();
value = struct('event_ids', [], 'machine_id', [], 'job', [], ...
    'operation', [], 'original_start', [], 'original_end', [], ...
    'original_duration', [], 'completed_segment', segment, ...
    'resumed_segment', segment, 'revised_completion_time', [], ...
    'is_validated', false);
end

function value = machine_block_template()
value = struct('start', [], 'end', [], 'job', [], 'opera', [], ...
    'segment_type', '', 'source_event_ids', []);
end

function value = operation_block(segment)
value = machine_block_template();
value.start = segment.start;
value.end = segment.end;
value.job = segment.job;
value.opera = segment.operation;
value.segment_type = segment.segment_type;
value.source_event_ids = segment.source_event_ids;
end

function value = idle_block(startTime, endTime)
value = machine_block_template();
value.start = startTime;
value.end = endTime;
value.job = 0;
value.opera = 0;
value.segment_type = 'idle';
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error(['build_stage_c_simultaneous_machine_right_shift:', ...
            'MissingField'], '%s.%s is required.', ...
            valueName, fields{index});
    end
end
end
