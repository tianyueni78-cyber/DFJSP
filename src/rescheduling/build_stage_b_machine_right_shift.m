function candidate = build_stage_b_machine_right_shift( ...
        baseline, fault, state, resumePlan, impact)
%BUILD_STAGE_B_MACHINE_RIGHT_SHIFT Build the Stage B machine candidate.
%   The interrupted operation remains one logical operation, but its
%   physical machine occupancy is split into a processed segment before
%   the fault and a resumed segment after repair. Affected unstarted
%   operations use the projected times from Stage B Step 3.
%
%   AGV tasks are copied unchanged. They are intentionally not validated
%   in this machine-only step.

if nargin < 5
    error('build_stage_b_machine_right_shift:MissingInput', ...
        'baseline, fault, state, resumePlan, and impact are required.');
end
require_fields(baseline, {'machineTable', 'AGVTable', 'problem', ...
    'isFaultFreeBaseline'}, 'baseline');
require_fields(fault, {'stage', 'machine_id', 'start_time', ...
    'repair_end_time', 'is_validated'}, 'fault');
require_fields(state, {'stage', 'interrupted_operation', ...
    'is_validated', 'is_rescheduled'}, 'state');
require_fields(resumePlan, {'stage', 'rule', 'machine_id', 'job', ...
    'operation', 'completed_segment', 'resumed_segment', ...
    'revised_completion_time', 'is_validated'}, 'resumePlan');
require_fields(impact, {'stage', 'step', 'affected_operations', ...
    'baseline_modified', 'is_rescheduled', 'is_validated'}, 'impact');
validate_inputs(baseline, fault, state, resumePlan, impact);

operationRecords = collect_operations(baseline.machineTable);
operationRecords = apply_resume_plan(operationRecords, resumePlan);
operationRecords = apply_affected_times( ...
    operationRecords, impact.affected_operations);
processingSegments = build_processing_segments( ...
    operationRecords, resumePlan);
machineTable = rebuild_machine_table( ...
    processingSegments, numel(baseline.machineTable));

validation = validate_candidate(baseline, fault, resumePlan, ...
    impact, operationRecords, processingSegments, machineTable);

candidate = struct();
candidate.strategy = 'partial_right_shift';
candidate.stage = 'B';
candidate.step = 4;
candidate.interruption_rule = resumePlan.rule;
candidate.machineTable = machineTable;
candidate.AGVTable = baseline.AGVTable;
candidate.operation_records = operationRecords;
candidate.processing_segments = processingSegments;
candidate.resume_plan = resumePlan;
candidate.unavailable_interval = struct( ...
    'machine_id', fault.machine_id, ...
    'start_time', fault.start_time, ...
    'end_time', fault.repair_end_time);
candidate.machine_makespan = max([operationRecords.end]);
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

function records = apply_resume_plan(records, resumePlan)
match = find_operation_index( ...
    records, resumePlan.job, resumePlan.operation);
if records(match).machine_id ~= resumePlan.machine_id
    error('build_stage_b_machine_right_shift:InterruptedMachineChanged', ...
        'The interrupted operation must resume on its original machine.');
end

records(match).end = resumePlan.revised_completion_time;
records(match).calendar_span = ...
    records(match).end - records(match).start;
records(match).is_affected = true;
records(match).is_interrupted = true;
end

function records = apply_affected_times(records, affectedOperations)
for affectedIndex = 1:numel(affectedOperations)
    affected = affectedOperations(affectedIndex);
    match = find_operation_index( ...
        records, affected.job, affected.operation);
    if records(match).machine_id ~= affected.machine_id
        error('build_stage_b_machine_right_shift:MachineChanged', ...
            'Partial right shift cannot change machine assignment.');
    end
    if records(match).is_interrupted
        error('build_stage_b_machine_right_shift:RootDuplicated', ...
            'The interrupted root must not appear in the successor set.');
    end

    records(match).start = affected.projected_start;
    records(match).end = affected.projected_end;
    records(match).calendar_span = ...
        affected.projected_end - affected.projected_start;
    records(match).is_affected = true;
end
end

function segments = build_processing_segments(records, resumePlan)
template = segment_template();
segments = template([]);
for index = 1:numel(records)
    record = records(index);
    if record.is_interrupted
        segments(end + 1) = segment_from_plan( ...
            record, resumePlan.completed_segment, 1);
        segments(end + 1) = segment_from_plan( ...
            record, resumePlan.resumed_segment, 2);
    else
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
        segments(end + 1) = segment;
    end
end
end

function segment = segment_from_plan(record, source, segmentOrder)
segment = segment_template();
segment.machine_id = source.machine_id;
segment.original_table_index = record.original_table_index;
segment.segment_order = segmentOrder;
segment.segment_type = source.segment_type;
segment.job = source.job;
segment.operation = source.operation;
segment.start = source.start;
segment.end = source.end;
segment.processing_time = source.processing_time;
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

function validation = validate_candidate(baseline, fault, resumePlan, ...
        impact, records, segments, machineTable)
tolerance = 1e-9;
validate_operation_identity(baseline.machineTable, records, tolerance);
validate_interrupted_operation(records, segments, resumePlan, tolerance);
validate_affected_times(records, impact.affected_operations, ...
    resumePlan, tolerance);
validate_machine_non_overlap(segments, numel(machineTable), tolerance);
validate_machine_table_structure(machineTable, tolerance);
validate_job_precedence(records, baseline.problem.operaNumVec, tolerance);
validate_repair_interval(segments, fault, tolerance);

validation = struct();
validation.operation_identity_preserved = true;
validation.machine_assignments_preserved = true;
validation.processing_durations_preserved = true;
validation.interrupted_operation_split = true;
validation.affected_times_applied = true;
validation.unaffected_operations_preserved = true;
validation.machine_non_overlap = true;
validation.machine_table_structure = true;
validation.job_precedence = true;
validation.repair_interval_respected = true;
end

function validate_operation_identity(baselineTable, records, tolerance)
baselineRecords = collect_operations(baselineTable);
if numel(baselineRecords) ~= numel(records)
    error('build_stage_b_machine_right_shift:OperationCountChanged', ...
        'The candidate must preserve every logical operation.');
end
for index = 1:numel(baselineRecords)
    source = baselineRecords(index);
    match = find_operation_index(records, source.job, source.operation);
    if records(match).machine_id ~= source.machine_id
        error('build_stage_b_machine_right_shift:AssignmentChanged', ...
            'An operation changed machine assignment.');
    end
    if abs(records(match).processing_duration - ...
            source.processing_duration) > tolerance
        error('build_stage_b_machine_right_shift:DurationChanged', ...
            'Effective processing duration must remain unchanged.');
    end
end
end

function validate_interrupted_operation(records, segments, ...
        resumePlan, tolerance)
match = find_operation_index( ...
    records, resumePlan.job, resumePlan.operation);
record = records(match);
if ~record.is_interrupted || ...
        abs(record.start - resumePlan.original_start) > tolerance || ...
        abs(record.end - resumePlan.revised_completion_time) > tolerance
    error('build_stage_b_machine_right_shift:InterruptedTimeMismatch', ...
        'Interrupted logical operation does not match the resume plan.');
end

segmentMatches = find([segments.job] == resumePlan.job & ...
    [segments.operation] == resumePlan.operation);
if numel(segmentMatches) ~= 2
    error('build_stage_b_machine_right_shift:InterruptedSegmentCount', ...
        'Interrupted operation must have exactly two processing segments.');
end
selected = segments(segmentMatches);
[~, order] = sort([selected.segment_order]);
selected = selected(order);
if abs(selected(1).start - resumePlan.completed_segment.start) > ...
        tolerance || ...
        abs(selected(1).end - resumePlan.completed_segment.end) > ...
        tolerance || ...
        abs(selected(2).start - resumePlan.resumed_segment.start) > ...
        tolerance || ...
        abs(selected(2).end - resumePlan.resumed_segment.end) > ...
        tolerance || ...
        abs(sum([selected.processing_time]) - ...
        resumePlan.original_duration) > tolerance
    error('build_stage_b_machine_right_shift:InterruptedSegmentMismatch', ...
        'Interrupted processing segments do not match the resume plan.');
end
end

function validate_affected_times(records, affectedOperations, ...
        resumePlan, tolerance)
for index = 1:numel(records)
    record = records(index);
    if record.job == resumePlan.job && ...
            record.operation == resumePlan.operation
        continue
    end
    affectedMatch = find([affectedOperations.job] == record.job & ...
        [affectedOperations.operation] == record.operation);
    if isempty(affectedMatch)
        if abs(record.start - record.original_start) > tolerance || ...
                abs(record.end - record.original_end) > tolerance
            error('build_stage_b_machine_right_shift:UnaffectedChanged', ...
                'An unaffected operation time was changed.');
        end
    elseif numel(affectedMatch) ~= 1 || ...
            abs(record.start - ...
            affectedOperations(affectedMatch).projected_start) > ...
            tolerance || ...
            abs(record.end - ...
            affectedOperations(affectedMatch).projected_end) > tolerance
        error('build_stage_b_machine_right_shift:AffectedTimeMismatch', ...
            'An affected operation does not use its projected time.');
    end
end
end

function validate_machine_non_overlap(segments, machineCount, tolerance)
for machineId = 1:machineCount
    selected = segments([segments.machine_id] == machineId);
    if numel(selected) < 2
        continue
    end
    [~, order] = sort([selected.start]);
    selected = selected(order);
    for index = 1:numel(selected) - 1
        if selected(index).end > selected(index + 1).start + tolerance
            error('build_stage_b_machine_right_shift:MachineOverlap', ...
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
        error('build_stage_b_machine_right_shift:InvalidMachineTable', ...
            'Machine %d has invalid boundary blocks.', machineId);
    end
    for index = 1:numel(blocks) - 1
        if abs(blocks(index).end - blocks(index + 1).start) > tolerance
            error('build_stage_b_machine_right_shift:InvalidMachineTable', ...
                'Machine %d has a gap or overlap between blocks.', ...
                machineId);
        end
    end
end
end

function validate_job_precedence(records, operaNumVec, tolerance)
for jobId = 1:numel(operaNumVec)
    for operationId = 1:operaNumVec(jobId) - 1
        current = records(find_operation_index( ...
            records, jobId, operationId));
        successor = records(find_operation_index( ...
            records, jobId, operationId + 1));
        if current.end > successor.start + tolerance
            error('build_stage_b_machine_right_shift:JobPrecedence', ...
                'J%d-O%d finishes after its successor starts.', ...
                jobId, operationId);
        end
    end
end
end

function validate_repair_interval(segments, fault, tolerance)
selected = segments([segments.machine_id] == fault.machine_id);
for index = 1:numel(selected)
    overlaps = selected(index).start < ...
        fault.repair_end_time - tolerance && ...
        fault.start_time < selected(index).end - tolerance;
    if overlaps
        error('build_stage_b_machine_right_shift:RepairOverlap', ...
            'The failed machine processes during the repair interval.');
    end
end
end

function index = find_operation_index(records, jobId, operationId)
index = find([records.job] == jobId & ...
    [records.operation] == operationId);
if numel(index) ~= 1
    error('build_stage_b_machine_right_shift:OperationNotUnique', ...
        'Operation J%d-O%d must appear exactly once.', ...
        jobId, operationId);
end
end

function value = operation_template()
value = struct('machine_id', [], 'original_table_index', [], ...
    'job', [], 'operation', [], 'original_start', [], ...
    'original_end', [], 'start', [], 'end', [], ...
    'processing_duration', [], 'calendar_span', [], ...
    'is_affected', false, 'is_interrupted', false);
end

function value = segment_template()
value = struct('machine_id', [], 'original_table_index', [], ...
    'segment_order', [], 'segment_type', '', 'job', [], ...
    'operation', [], 'start', [], 'end', [], ...
    'processing_time', []);
end

function value = machine_block_template()
value = struct('start', [], 'end', [], 'job', [], 'opera', [], ...
    'segment_type', '');
end

function value = operation_block(segment)
value = machine_block_template();
value.start = segment.start;
value.end = segment.end;
value.job = segment.job;
value.opera = segment.operation;
value.segment_type = segment.segment_type;
end

function value = idle_block(startTime, endTime)
value = machine_block_template();
value.start = startTime;
value.end = endTime;
value.job = 0;
value.opera = 0;
value.segment_type = 'idle';
end

function validate_inputs(baseline, fault, state, resumePlan, impact)
if ~baseline.isFaultFreeBaseline || ~fault.is_validated || ...
        ~state.is_validated || state.is_rescheduled || ...
        ~resumePlan.is_validated || ~impact.is_validated || ...
        ~strcmp(fault.stage, 'B') || ~strcmp(state.stage, 'B') || ...
        ~strcmp(resumePlan.stage, 'B') || ~strcmp(impact.stage, 'B') || ...
        impact.step ~= 3 || impact.baseline_modified || ...
        impact.is_rescheduled || ...
        ~strcmp(resumePlan.rule, 'resume_on_original_machine')
    error('build_stage_b_machine_right_shift:InvalidInput', ...
        'Validated Stage B Step 3 inputs are required.');
end
if fault.machine_id ~= resumePlan.machine_id || ...
        fault.machine_id ~= state.interrupted_operation.machine_id || ...
        resumePlan.job ~= state.interrupted_operation.job || ...
        resumePlan.operation ~= state.interrupted_operation.operation
    error('build_stage_b_machine_right_shift:RootMismatch', ...
        'Fault, state, and resume plan identify different roots.');
end
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('build_stage_b_machine_right_shift:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
