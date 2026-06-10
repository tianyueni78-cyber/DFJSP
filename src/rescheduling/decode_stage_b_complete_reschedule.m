function candidate = decode_stage_b_complete_reschedule( ...
        baseline, frozen, decision)
%DECODE_STAGE_B_COMPLETE_RESCHEDULE Decode a Stage B complete candidate.
%   Future unstarted work uses the established Stage A scheduling core.
%   This adapter then restores the interrupted operation as two physical
%   processing segments, corrects its effective processing duration,
%   rebuilds the machine table, and recalculates machine energy.

if nargin < 3
    error('decode_stage_b_complete_reschedule:MissingInput', ...
        'baseline, frozen, and decision are required.');
end
require_fields(baseline, {'problem', 'machineData', ...
    'isFaultFreeBaseline'}, 'baseline');
require_fields(frozen, {'stage', 'step', 'interrupted_commitment', ...
    'frozen_operations', 'reschedulable_operations', ...
    'decoder_requirement', 'stage_a_decoder_compatible', ...
    'is_validated'}, 'frozen');
validate_inputs(baseline, frozen);

coreCandidate = decode_stage_a_complete_reschedule( ...
    baseline, frozen, decision);
operations = restore_stage_b_operation( ...
    coreCandidate.operation_records, frozen.interrupted_commitment);
segments = build_processing_segments( ...
    operations, frozen.interrupted_commitment);
machineTable = rebuild_machine_table( ...
    segments, baseline.problem.machineNum);
machineEnergy = calculate_machine_energy( ...
    operations, baseline);
validation = validate_stage_b_candidate( ...
    operations, segments, coreCandidate, frozen, baseline.problem);

candidate = coreCandidate;
candidate.stage = 'B';
candidate.step = 8;
candidate.decoder = 'stage_b_split_operation_decoder';
candidate.operation_records = operations;
candidate.processing_segments = segments;
candidate.machineTable = machineTable;
candidate.machine_makespan = max([operations.end]);
candidate.machine_energy = machineEnergy;
candidate.total_energy = machineEnergy + candidate.agv_energy;
candidate.interrupted_commitment = frozen.interrupted_commitment;
candidate.core_validation = coreCandidate.validation;
candidate.validation = validation;
candidate.is_search_executed = false;
candidate.is_complete_reschedule_decoded = true;
candidate.is_stage_b_split_operation_decoded = true;
candidate.is_validated = true;
end

function operations = restore_stage_b_operation(operations, commitment)
match = find([operations.job] == commitment.job & ...
    [operations.operation] == commitment.operation);
if numel(match) ~= 1
    error('decode_stage_b_complete_reschedule:InterruptedNotUnique', ...
        'Interrupted operation must appear exactly once.');
end
operation = operations(match);
if operation.machine_id ~= commitment.machine_id || ...
        abs(operation.start - commitment.original_start) > 1e-9 || ...
        abs(operation.end - commitment.revised_completion_time) > 1e-9
    error('decode_stage_b_complete_reschedule:InterruptedChanged', ...
        'The scheduling core changed the interrupted commitment.');
end
operations(match).duration = commitment.original_duration;
operations(match).status = 'interrupted_committed';
operations(match).is_interrupted = true;

for index = setdiff(1:numel(operations), match)
    operations(index).is_interrupted = false;
end
end

function segments = build_processing_segments(operations, commitment)
template = segment_template();
segments = template([]);
for index = 1:numel(operations)
    operation = operations(index);
    if operation.is_interrupted
        segments(end + 1) = segment_from_commitment( ...
            operation, commitment.completed_segment, 1);
        segments(end + 1) = segment_from_commitment( ...
            operation, commitment.resumed_segment, 2);
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
        operation, source, segmentOrder)
segment = segment_template();
segment.machine_id = operation.machine_id;
segment.segment_order = segmentOrder;
segment.segment_type = source.segment_type;
segment.job = operation.job;
segment.operation = operation.operation;
segment.start = source.start;
segment.end = source.end;
segment.processing_time = source.processing_time;
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

function machineEnergy = calculate_machine_energy(operations, baseline)
machineCount = baseline.problem.machineNum;
work = zeros(machineCount, 1);
idle = zeros(machineCount, 1);
for machineId = 1:machineCount
    records = operations([operations.machine_id] == machineId);
    if isempty(records)
        continue
    end
    work(machineId) = sum([records.duration]);
    idle(machineId) = max([records.end]) - work(machineId);
    if idle(machineId) < -1e-9
        error('decode_stage_b_complete_reschedule:NegativeIdle', ...
            'Machine %d has negative idle time.', machineId);
    end
end
rates = baseline.machineData.machineEnergy;
machineEnergy = rates.work(1:machineCount)' * work + ...
    rates.free(1:machineCount)' * idle;
end

function validation = validate_stage_b_candidate( ...
        operations, segments, coreCandidate, frozen, problem)
tolerance = 1e-9;
validate_operation_partition(operations, problem.operaNumVec);
validate_frozen_operations(operations, frozen, tolerance);
validate_interrupted_commitment( ...
    operations, segments, frozen.interrupted_commitment, tolerance);
validate_machine_segments(segments, problem.machineNum, tolerance);
validate_job_precedence(operations, problem.operaNumVec, tolerance);
validate_core_outputs(coreCandidate);

validation = coreCandidate.validation;
validation.interrupted_logical_operation_preserved = true;
validation.interrupted_processing_segments_preserved = true;
validation.repair_gap_excluded_from_processing_duration = true;
validation.machine_segment_non_overlap = true;
validation.stage_b_machine_energy_recalculated = true;
validation.stage_b_decoder_contract = true;
end

function validate_operation_partition(operations, operaNumVec)
if numel(operations) ~= sum(operaNumVec)
    error('decode_stage_b_complete_reschedule:OperationCount', ...
        'Candidate operation count does not match the problem.');
end
for jobId = 1:numel(operaNumVec)
    for operationId = 1:operaNumVec(jobId)
        match = find([operations.job] == jobId & ...
            [operations.operation] == operationId);
        if numel(match) ~= 1
            error('decode_stage_b_complete_reschedule:OperationPartition', ...
                'J%d-O%d must appear exactly once.', ...
                jobId, operationId);
        end
    end
end
end

function validate_frozen_operations(operations, frozen, tolerance)
for index = 1:numel(frozen.frozen_operations)
    source = frozen.frozen_operations(index);
    target = find_operation( ...
        operations, source.job, source.operation);
    if target.machine_id ~= source.machine_id || ...
            abs(target.start - source.start) > tolerance || ...
            abs(target.end - source.end) > tolerance
        error('decode_stage_b_complete_reschedule:FrozenChanged', ...
            'Frozen operation J%d-O%d was changed.', ...
            source.job, source.operation);
    end
end
end

function validate_interrupted_commitment( ...
        operations, segments, commitment, tolerance)
operation = find_operation( ...
    operations, commitment.job, commitment.operation);
if ~operation.is_interrupted || ...
        operation.machine_id ~= commitment.machine_id || ...
        abs(operation.duration - commitment.original_duration) > ...
        tolerance || ...
        abs(operation.end - commitment.revised_completion_time) > ...
        tolerance
    error('decode_stage_b_complete_reschedule:InterruptedMismatch', ...
        'Interrupted logical operation is inconsistent.');
end

selected = segments([segments.job] == commitment.job & ...
    [segments.operation] == commitment.operation);
if numel(selected) ~= 2
    error('decode_stage_b_complete_reschedule:SegmentCount', ...
        'Interrupted operation must have two processing segments.');
end
[~, order] = sort([selected.segment_order]);
selected = selected(order);
if abs(selected(1).start - commitment.completed_segment.start) > ...
        tolerance || ...
        abs(selected(1).end - commitment.completed_segment.end) > ...
        tolerance || ...
        abs(selected(2).start - commitment.resumed_segment.start) > ...
        tolerance || ...
        abs(selected(2).end - commitment.resumed_segment.end) > ...
        tolerance || ...
        abs(sum([selected.processing_time]) - ...
        commitment.original_duration) > tolerance
    error('decode_stage_b_complete_reschedule:SegmentMismatch', ...
        'Interrupted processing segments are inconsistent.');
end
end

function validate_machine_segments(segments, machineCount, tolerance)
for machineId = 1:machineCount
    records = segments([segments.machine_id] == machineId);
    [~, order] = sort([records.start]);
    records = records(order);
    for index = 1:numel(records) - 1
        if records(index).end > records(index + 1).start + tolerance
            error('decode_stage_b_complete_reschedule:MachineOverlap', ...
                'Machine %d has overlapping processing segments.', ...
                machineId);
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
            error('decode_stage_b_complete_reschedule:JobPrecedence', ...
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
    error('decode_stage_b_complete_reschedule:InvalidCoreCandidate', ...
        'The shared scheduling core returned an invalid candidate.');
end
end

function operation = find_operation(records, jobId, operationId)
match = find([records.job] == jobId & ...
    [records.operation] == operationId);
if numel(match) ~= 1
    error('decode_stage_b_complete_reschedule:OperationNotUnique', ...
        'J%d-O%d must appear exactly once.', jobId, operationId);
end
operation = records(match);
end

function validate_inputs(baseline, frozen)
if ~baseline.isFaultFreeBaseline || ~frozen.is_validated || ...
        ~strcmp(frozen.stage, 'B') || frozen.step ~= 7 || ...
        frozen.stage_a_decoder_compatible || ...
        ~strcmp(frozen.decoder_requirement, ...
        'stage_b_split_operation_decoder')
    error('decode_stage_b_complete_reschedule:InvalidInput', ...
        'Validated Stage B Step 7 inputs are required.');
end
end

function value = segment_template()
value = struct('machine_id', [], 'segment_order', [], ...
    'segment_type', '', 'job', [], 'operation', [], ...
    'start', [], 'end', [], 'processing_time', []);
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
        error('decode_stage_b_complete_reschedule:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
