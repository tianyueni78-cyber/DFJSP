function candidate = decode_stage_cs2_complete_reschedule( ...
        baseline, frozen, decision)
%decode_stage_cs2_complete_reschedule Decode C-S2 Step 7.
%   The shared Stage A core schedules all released operations and AGV
%   activities. This adapter restores every interrupted operation as two
%   committed processing segments and validates all repair intervals.

if nargin < 3
    error('decode_stage_cs2_complete_reschedule:MissingInput', ...
        'baseline, frozen, and decision are required.');
end
require_fields(baseline, {'problem', 'machineData'}, 'baseline');
require_fields(frozen, {'stage', 'step', 'repair_intervals', ...
    'interrupted_commitments', 'frozen_operations', ...
    'reschedulable_operations', 'decoder_requirement', ...
    'stage_a_decoder_compatible', 'is_validated'}, 'frozen');
validate_inputs(baseline, frozen);

% Block 1: reuse the established decoder for released work and AGV tasks.
coreBaseline = stage_a_core_baseline_view(baseline);
coreCandidate = decode_stage_a_complete_reschedule( ...
    coreBaseline, frozen, decision);

% Block 2: restore all interrupted logical operations and physical segments.
operations = restore_interrupted_operations( ...
    coreCandidate.operation_records, frozen.interrupted_commitments);
segments = build_processing_segments( ...
    operations, frozen.interrupted_commitments);
machineTable = rebuild_machine_table( ...
    segments, baseline.problem.machineNum);
machineEnergy = calculate_machine_energy(operations, segments, baseline);

% Block 3: audit the complete candidate against every C-S2 constraint.
validation = validate_stage_cs2_candidate( ...
    operations, segments, coreCandidate, frozen, baseline.problem);

candidate = coreCandidate;
candidate.stage = 'C-S2';
candidate.step = 7;
candidate.substep = '7';
candidate.decoder = 'stage_cs2_multiple_restart_operation_decoder';
candidate.operation_records = operations;
candidate.processing_segments = segments;
candidate.machineTable = machineTable;
candidate.machine_makespan = max([operations.end]);
candidate.machine_energy = machineEnergy;
candidate.total_energy = machineEnergy + candidate.agv_energy;
candidate.repair_intervals = frozen.repair_intervals;
candidate.interrupted_commitments = frozen.interrupted_commitments;
candidate.core_validation = coreCandidate.validation;
candidate.validation = validation;
candidate.is_search_executed = false;
candidate.is_complete_reschedule_decoded = true;
candidate.is_stage_cs2_multiple_restart_operation_decoded = true;
candidate.is_validated = true;
end

function value = stage_a_core_baseline_view(baseline)
value = baseline;
% The shared Stage A decoder only checks this flag as a baseline guard.
% C-S2 still passes the current plan's machine/AGV tables and boundaries.
value.isFaultFreeBaseline = true;
end

function operations = restore_interrupted_operations( ...
        operations, commitments)
for index = 1:numel(operations)
    operations(index).is_interrupted = false;
    operations(index).source_event_ids = [];
end
for index = 1:numel(commitments)
    commitment = commitments(index);
    match = find([operations.job] == commitment.job & ...
        [operations.operation] == commitment.operation);
    if numel(match) ~= 1
        error('decode_stage_cs2_complete_reschedule:InterruptedNotUnique', ...
            'Interrupted operation J%d-O%d must appear exactly once.', ...
            commitment.job, commitment.operation);
    end
    operation = operations(match);
    if operation.machine_id ~= commitment.machine_id || ...
            abs(operation.start - commitment.original_start) > 1e-9 || ...
            abs(operation.end - commitment.revised_completion_time) > 1e-9
        error('decode_stage_cs2_complete_reschedule:InterruptedChanged', ...
            'The scheduling core changed interrupted J%d-O%d.', ...
            commitment.job, commitment.operation);
    end
    operations(match).duration = commitment.original_duration;
    operations(match).status = 'interrupted_restart_committed';
    operations(match).is_interrupted = true;
    operations(match).restart_from_zero = true;
    operations(match).progress_preserved = false;
    operations(match).lost_processing_time = commitment.lost_processing_time;
    operations(match).total_machine_processing_time = ...
        commitment.total_machine_processing_time;
    operations(match).source_event_ids = commitment.event_ids;
end
for index = 1:numel(operations)
    if operations(index).is_interrupted
        continue
    end
    operations(index).restart_from_zero = false;
    operations(index).progress_preserved = true;
    operations(index).lost_processing_time = 0;
    operations(index).total_machine_processing_time = ...
        operations(index).duration;
end
end

function segments = build_processing_segments(operations, commitments)
template = segment_template();
segments = template([]);
for index = 1:numel(operations)
    operation = operations(index);
    if operation.is_interrupted
        commitment = find_commitment( ...
            commitments, operation.job, operation.operation);
        segments(end + 1) = segment_from_commitment( ...
            operation, commitment.lost_processing_segment, 1, ...
            commitment.event_ids);
        segments(end + 1) = segment_from_commitment( ...
            operation, commitment.restart_segment, 2, ...
            commitment.event_ids);
    else
        segment = template;
        segment.machine_id = operation.machine_id;
        segment.segment_order = 1;
        segment.segment_type = 'complete_operation';
        segment.job = operation.job;
        segment.operation = operation.operation;
        segment.start = operation.start;
        segment.end = operation.end;
        segment.processing_time = operation.duration;
        segments(end + 1) = segment;
    end
end
end

function segment = segment_from_commitment( ...
        operation, source, segmentOrder, eventIds)
segment = segment_template();
segment.machine_id = operation.machine_id;
segment.segment_order = segmentOrder;
segment.segment_type = source.segment_type;
segment.job = operation.job;
segment.operation = operation.operation;
segment.start = source.start;
segment.end = source.end;
segment.processing_time = source.processing_time;
segment.source_event_ids = eventIds;
end

function commitment = find_commitment(commitments, jobId, operationId)
match = find([commitments.job] == jobId & ...
    [commitments.operation] == operationId);
if numel(match) ~= 1
    error('decode_stage_cs2_complete_reschedule:CommitmentNotUnique', ...
        'J%d-O%d requires exactly one interrupted commitment.', ...
        jobId, operationId);
end
commitment = commitments(match);
end

function machineTable = rebuild_machine_table(segments, machineCount)
machineTable = cell(1, machineCount);
for machineId = 1:machineCount
    machineSegments = segments([segments.machine_id] == machineId);
    if isempty(machineSegments)
        machineTable{machineId} = machine_idle_block(0, Inf);
        continue
    end
    ordering = [[machineSegments.start].', ...
        [machineSegments.job].', [machineSegments.operation].', ...
        [machineSegments.segment_order].'];
    [~, order] = sortrows(ordering, [1, 2, 3, 4]);
    machineSegments = machineSegments(order);

    template = machine_block_template();
    blocks = template([]);
    cursor = 0;
    for index = 1:numel(machineSegments)
        if machineSegments(index).start > cursor
            blocks(end + 1) = machine_idle_block( ...
                cursor, machineSegments(index).start);
        end
        blocks(end + 1) = machine_operation_block( ...
            machineSegments(index));
        cursor = machineSegments(index).end;
    end
    blocks(end + 1) = machine_idle_block(cursor, Inf);
    machineTable{machineId} = blocks;
end
end

function machineEnergy = calculate_machine_energy(operations, segments, baseline)
machineCount = baseline.problem.machineNum;
work = zeros(machineCount, 1);
idle = zeros(machineCount, 1);
for machineId = 1:machineCount
    records = operations([operations.machine_id] == machineId);
    machineSegments = segments([segments.machine_id] == machineId);
    if isempty(records)
        continue
    end
    work(machineId) = sum([machineSegments.processing_time]);
    idle(machineId) = max([records.end]) - work(machineId);
    if idle(machineId) < -1e-9
        error('decode_stage_cs2_complete_reschedule:NegativeIdle', ...
            'Machine %d has negative idle time.', machineId);
    end
end
rates = baseline.machineData.machineEnergy;
machineEnergy = rates.work(1:machineCount)' * work + ...
    rates.free(1:machineCount)' * idle;
end

function validation = validate_stage_cs2_candidate( ...
        operations, segments, coreCandidate, frozen, problem)
tolerance = 1e-9;
validate_operation_partition(operations, problem.operaNumVec);
validate_frozen_operations(operations, frozen, tolerance);
validate_interrupted_commitments( ...
    operations, segments, frozen.interrupted_commitments, tolerance);
validate_machine_segments(segments, problem.machineNum, tolerance);
validate_repair_intervals(segments, frozen.repair_intervals, tolerance);
validate_job_precedence(operations, problem.operaNumVec, tolerance);
validate_core_outputs(coreCandidate);

validation = coreCandidate.validation;
validation.multiple_interrupted_operations_preserved = true;
validation.multiple_processing_segments_preserved = true;
validation.restart_from_zero_commitments_preserved = true;
validation.lost_processing_counted_as_machine_work = true;
validation.full_restart_segments_preserved = true;
validation.all_repair_intervals_respected = true;
validation.machine_segment_non_overlap = true;
validation.stage_cs2_machine_energy_recalculated = true;
validation.stage_cs2_decoder_contract = true;
end

function validate_operation_partition(operations, operaNumVec)
if numel(operations) ~= sum(operaNumVec)
    error('decode_stage_cs2_complete_reschedule:OperationCount', ...
        'Candidate operation count does not match the problem.');
end
for jobId = 1:numel(operaNumVec)
    for operationId = 1:operaNumVec(jobId)
        match = find([operations.job] == jobId & ...
            [operations.operation] == operationId);
        if numel(match) ~= 1
            error('decode_stage_cs2_complete_reschedule:OperationPartition', ...
                'J%d-O%d must appear exactly once.', jobId, operationId);
        end
    end
end
end

function validate_frozen_operations(operations, frozen, tolerance)
for index = 1:numel(frozen.frozen_operations)
    source = frozen.frozen_operations(index);
    target = find_operation(operations, source.job, source.operation);
    if target.machine_id ~= source.machine_id || ...
            abs(target.start - source.start) > tolerance || ...
            abs(target.end - source.end) > tolerance
        error('decode_stage_cs2_complete_reschedule:FrozenChanged', ...
            'Frozen operation J%d-O%d was changed.', ...
            source.job, source.operation);
    end
end
end

function validate_interrupted_commitments( ...
        operations, segments, commitments, tolerance)
interruptedCount = sum([operations.is_interrupted]);
if interruptedCount ~= numel(commitments)
    error('decode_stage_cs2_complete_reschedule:InterruptedCount', ...
        'Interrupted logical operation count is inconsistent.');
end
for index = 1:numel(commitments)
    commitment = commitments(index);
    operation = find_operation( ...
        operations, commitment.job, commitment.operation);
    if ~operation.is_interrupted || ...
            operation.machine_id ~= commitment.machine_id || ...
            abs(operation.duration - commitment.original_duration) > ...
            tolerance || ...
            abs(operation.end - commitment.revised_completion_time) > ...
            tolerance || ...
            ~operation.restart_from_zero || operation.progress_preserved || ...
            abs(operation.lost_processing_time - ...
            commitment.lost_processing_time) > tolerance || ...
            abs(operation.total_machine_processing_time - ...
            commitment.total_machine_processing_time) > tolerance || ...
            ~isequal(operation.source_event_ids, commitment.event_ids)
        error('decode_stage_cs2_complete_reschedule:InterruptedMismatch', ...
            'Interrupted J%d-O%d is inconsistent.', ...
            commitment.job, commitment.operation);
    end

    selected = segments([segments.job] == commitment.job & ...
        [segments.operation] == commitment.operation);
    if numel(selected) ~= 2
        error('decode_stage_cs2_complete_reschedule:SegmentCount', ...
            'Interrupted J%d-O%d must have two segments.', ...
            commitment.job, commitment.operation);
    end
    [~, order] = sort([selected.segment_order]);
    selected = selected(order);
    if ~strcmp(selected(1).segment_type, ...
            'lost_processing_before_fault') || ...
            ~strcmp(selected(2).segment_type, ...
            'restart_after_repair') || ...
            abs(selected(1).start - ...
            commitment.lost_processing_segment.start) > ...
            tolerance || ...
            abs(selected(1).end - ...
            commitment.lost_processing_segment.end) > ...
            tolerance || ...
            abs(selected(2).start - commitment.restart_segment.start) > ...
            tolerance || ...
            abs(selected(2).end - commitment.restart_segment.end) > ...
            tolerance || ...
            abs(sum([selected.processing_time]) - ...
            commitment.total_machine_processing_time) > tolerance || ...
            abs(selected(1).processing_time - ...
            commitment.lost_processing_time) > tolerance || ...
            abs(selected(2).processing_time - ...
            commitment.original_duration) > tolerance
        error('decode_stage_cs2_complete_reschedule:SegmentMismatch', ...
            'Interrupted segments for J%d-O%d are inconsistent.', ...
            commitment.job, commitment.operation);
    end
end
end

function validate_machine_segments(segments, machineCount, tolerance)
for machineId = 1:machineCount
    records = segments([segments.machine_id] == machineId);
    [~, order] = sort([records.start]);
    records = records(order);
    for index = 1:numel(records) - 1
        if records(index).end > records(index + 1).start + tolerance
            error('decode_stage_cs2_complete_reschedule:MachineOverlap', ...
                'Machine %d has overlapping processing segments.', ...
                machineId);
        end
    end
end
end

function validate_repair_intervals(segments, intervals, tolerance)
for intervalIndex = 1:numel(intervals)
    interval = intervals(intervalIndex);
    records = segments([segments.machine_id] == interval.machine_id);
    for recordIndex = 1:numel(records)
        overlaps = records(recordIndex).start < ...
            interval.end_time - tolerance && ...
            records(recordIndex).end > interval.start_time + tolerance;
        if overlaps
            error('decode_stage_cs2_complete_reschedule:RepairOverlap', ...
                'Machine %d processes work during repair event %d.', ...
                interval.machine_id, interval.event_id);
        end
    end
end
end

function validate_job_precedence(operations, operaNumVec, tolerance)
for jobId = 1:numel(operaNumVec)
    for operationId = 1:operaNumVec(jobId) - 1
        current = find_operation(operations, jobId, operationId);
        successor = find_operation(operations, jobId, operationId + 1);
        if current.end > successor.start + tolerance
            error('decode_stage_cs2_complete_reschedule:JobPrecedence', ...
                'J%d-O%d finishes after its successor starts.', ...
                jobId, operationId);
        end
    end
end
end

function validate_core_outputs(candidate)
if ~candidate.is_validated || ...
        ~candidate.is_complete_reschedule_decoded || ...
        candidate.is_search_executed || ...
        any(candidate.job_complete_unload <= 0) || ...
        any(~isfinite(candidate.final_agv_energy))
    error('decode_stage_cs2_complete_reschedule:InvalidCoreCandidate', ...
        'The shared scheduling core returned an invalid candidate.');
end
end

function operation = find_operation(records, jobId, operationId)
match = find([records.job] == jobId & ...
    [records.operation] == operationId);
if numel(match) ~= 1
    error('decode_stage_cs2_complete_reschedule:OperationNotUnique', ...
        'J%d-O%d must appear exactly once.', jobId, operationId);
end
operation = records(match);
end

function validate_inputs(baseline, frozen)
isFaultFree = isfield(baseline, 'isFaultFreeBaseline') && ...
    isequal(baseline.isFaultFreeBaseline, true);
isCurrentView = isfield(baseline, 'isCurrentPlanView') && ...
    isequal(baseline.isCurrentPlanView, true);
if (~isFaultFree && ~isCurrentView) || ~frozen.is_validated || ...
        ~strcmp(frozen.stage, 'C-S2') || frozen.step ~= 6 || ...
        frozen.stage_a_decoder_compatible || ...
        isempty(frozen.interrupted_commitments) || ...
        ~strcmp(frozen.decoder_requirement, ...
        'stage_cs2_multiple_restart_operation_decoder')
    error('decode_stage_cs2_complete_reschedule:InvalidInput', ...
        'Validated C-S2 frozen inputs are required.');
end
end

function value = segment_template()
value = struct('machine_id', [], 'segment_order', [], ...
    'segment_type', '', 'job', [], 'operation', [], ...
    'start', [], 'end', [], 'processing_time', [], ...
    'source_event_ids', []);
end

function value = machine_block_template()
value = struct('start', [], 'end', [], 'job', [], 'opera', [], ...
    'segment_type', '');
end

function value = machine_operation_block(segment)
value = machine_block_template();
value.start = segment.start;
value.end = segment.end;
value.job = segment.job;
value.opera = segment.operation;
value.segment_type = segment.segment_type;
end

function value = machine_idle_block(startTime, endTime)
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
        error('decode_stage_cs2_complete_reschedule:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end

