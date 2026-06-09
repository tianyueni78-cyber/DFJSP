function candidate = build_stage_a_machine_right_shift( ...
        baseline, fault, state, impact)
%BUILD_STAGE_A_MACHINE_RIGHT_SHIFT Build a machine-only right-shift plan.
%   Affected operation times are applied to a copy of the baseline.
%   Machine assignments and unaffected operation times remain unchanged.
%   AGV tasks are copied without adjustment and are not validated here.

if nargin < 4
    error('build_stage_a_machine_right_shift:MissingInput', ...
        'baseline, fault, state, and impact are required.');
end

require_fields(baseline, {'machineTable', 'AGVTable', 'problem', ...
    'isFaultFreeBaseline'}, 'baseline');
require_fields(fault, {'machine_id', 'start_time', ...
    'repair_end_time', 'is_validated'}, 'fault');
require_fields(state, {'is_validated'}, 'state');
require_fields(impact, {'unavailable_interval', ...
    'affected_operations', 'is_validated'}, 'impact');
validate_inputs(baseline, fault, state, impact);

operationRecords = collect_operations(baseline.machineTable);
operationRecords = apply_affected_times( ...
    operationRecords, impact.affected_operations);
machineTable = rebuild_machine_table( ...
    operationRecords, numel(baseline.machineTable));

validation = validate_machine_candidate( ...
    baseline, machineTable, operationRecords, fault, impact);

candidate = struct();
candidate.strategy = 'partial_right_shift';
candidate.stage = 'A';
candidate.machineTable = machineTable;
candidate.AGVTable = baseline.AGVTable;
candidate.operation_records = operationRecords;
candidate.unavailable_interval = impact.unavailable_interval;
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
        record.duration = block.end - block.start;
        record.is_affected = false;
        records(end + 1) = record;
    end
end
end

function records = apply_affected_times(records, affectedOperations)
for affectedIndex = 1:numel(affectedOperations)
    affected = affectedOperations(affectedIndex);
    match = find([records.job] == affected.job & ...
        [records.operation] == affected.operation);
    if numel(match) ~= 1
        error('build_stage_a_machine_right_shift:OperationNotUnique', ...
            'Affected operation J%d-O%d appears %d times.', ...
            affected.job, affected.operation, numel(match));
    end
    if records(match).machine_id ~= affected.machine_id
        error('build_stage_a_machine_right_shift:MachineChanged', ...
            'Partial right shift cannot change machine assignment.');
    end

    records(match).start = affected.projected_start;
    records(match).end = affected.projected_end;
    records(match).is_affected = true;
end
end

function machineTable = rebuild_machine_table(records, machineCount)
machineTable = cell(1, machineCount);
for machineId = 1:machineCount
    indices = find([records.machine_id] == machineId);
    if isempty(indices)
        machineTable{machineId} = idle_block(0, Inf);
        continue
    end

    ordering = [[records(indices).start].', ...
        [records(indices).original_table_index].'];
    [~, order] = sortrows(ordering, [1, 2]);
    ordered = records(indices(order));

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

function validation = validate_machine_candidate( ...
        baseline, machineTable, records, fault, impact)
tolerance = 1e-9;
validate_durations_and_assignments(baseline.machineTable, records, tolerance);
validate_affected_and_unaffected(records, ...
    impact.affected_operations, tolerance);
validate_machine_non_overlap(records, numel(machineTable), tolerance);
validate_machine_table_structure(machineTable, tolerance);
validate_job_precedence(records, baseline.problem.operaNumVec, tolerance);
validate_repair_interval(records, fault, tolerance);

validation = struct();
validation.durations_preserved = true;
validation.machine_assignments_preserved = true;
validation.unaffected_operations_preserved = true;
validation.affected_times_applied = true;
validation.machine_non_overlap = true;
validation.machine_table_structure = true;
validation.job_precedence = true;
validation.repair_interval_respected = true;
end

function validate_durations_and_assignments( ...
        baselineTable, records, tolerance)
baselineRecords = collect_operations(baselineTable);
if numel(baselineRecords) ~= numel(records)
    error('build_stage_a_machine_right_shift:OperationCountChanged', ...
        'The candidate must preserve every baseline operation.');
end

for index = 1:numel(baselineRecords)
    match = find([records.job] == baselineRecords(index).job & ...
        [records.operation] == baselineRecords(index).operation);
    if numel(match) ~= 1 || ...
            records(match).machine_id ~= baselineRecords(index).machine_id
        error('build_stage_a_machine_right_shift:AssignmentChanged', ...
            'Operation assignment was changed or duplicated.');
    end
    if abs(records(match).duration - baselineRecords(index).duration) > ...
            tolerance
        error('build_stage_a_machine_right_shift:DurationChanged', ...
            'Operation duration was changed.');
    end
end
end

function validate_affected_and_unaffected( ...
        records, affectedOperations, tolerance)
for index = 1:numel(records)
    affectedMatch = find([affectedOperations.job] == records(index).job & ...
        [affectedOperations.operation] == records(index).operation);
    if isempty(affectedMatch)
        if abs(records(index).start - records(index).original_start) > ...
                tolerance || ...
                abs(records(index).end - records(index).original_end) > ...
                tolerance
            error('build_stage_a_machine_right_shift:UnaffectedChanged', ...
                'An unaffected operation time was changed.');
        end
    else
        if numel(affectedMatch) ~= 1 || ...
                abs(records(index).start - ...
                affectedOperations(affectedMatch).projected_start) > ...
                tolerance || ...
                abs(records(index).end - ...
                affectedOperations(affectedMatch).projected_end) > tolerance
            error('build_stage_a_machine_right_shift:AffectedTimeMismatch', ...
                'An affected operation does not use the projected time.');
        end
    end
end
end

function validate_machine_non_overlap(records, machineCount, tolerance)
for machineId = 1:machineCount
    operations = records([records.machine_id] == machineId);
    if numel(operations) < 2
        continue
    end
    [~, order] = sort([operations.start]);
    operations = operations(order);
    for index = 1:numel(operations) - 1
        if operations(index).end > operations(index + 1).start + tolerance
            error('build_stage_a_machine_right_shift:MachineOverlap', ...
                'Machine %d has overlapping operations.', machineId);
        end
    end
end
end

function validate_machine_table_structure(machineTable, tolerance)
for machineId = 1:numel(machineTable)
    blocks = machineTable{machineId};
    if isempty(blocks) || abs(blocks(1).start) > tolerance || ...
            ~isinf(blocks(end).end) || blocks(end).job ~= 0
        error('build_stage_a_machine_right_shift:InvalidMachineTable', ...
            'Machine %d has invalid boundary blocks.', machineId);
    end
    for index = 1:numel(blocks) - 1
        if blocks(index).end > blocks(index + 1).start + tolerance || ...
                abs(blocks(index).end - blocks(index + 1).start) > ...
                tolerance
            error('build_stage_a_machine_right_shift:InvalidMachineTable', ...
                'Machine %d has a gap or overlap between table blocks.', ...
                machineId);
        end
    end
end
end

function validate_job_precedence(records, operaNumVec, tolerance)
for jobId = 1:numel(operaNumVec)
    for operationId = 1:operaNumVec(jobId) - 1
        current = find_operation(records, jobId, operationId);
        successor = find_operation(records, jobId, operationId + 1);
        if current.end > successor.start + tolerance
            error('build_stage_a_machine_right_shift:JobPrecedence', ...
                'J%d-O%d finishes after its successor starts.', ...
                jobId, operationId);
        end
    end
end
end

function validate_repair_interval(records, fault, tolerance)
operations = records([records.machine_id] == fault.machine_id);
for index = 1:numel(operations)
    overlaps = operations(index).start < ...
        fault.repair_end_time - tolerance && ...
        fault.start_time < operations(index).end - tolerance;
    if overlaps
        error('build_stage_a_machine_right_shift:RepairOverlap', ...
            'The failed machine processes an operation during repair.');
    end
end
end

function operation = find_operation(records, jobId, operationId)
match = find([records.job] == jobId & ...
    [records.operation] == operationId);
if numel(match) ~= 1
    error('build_stage_a_machine_right_shift:OperationNotUnique', ...
        'Operation J%d-O%d must appear exactly once.', ...
        jobId, operationId);
end
operation = records(match);
end

function value = operation_template()
value = struct('machine_id', [], 'original_table_index', [], ...
    'job', [], 'operation', [], 'original_start', [], ...
    'original_end', [], 'start', [], 'end', [], 'duration', [], ...
    'is_affected', false);
end

function value = machine_block_template()
value = struct('start', [], 'end', [], 'job', [], 'opera', []);
end

function value = operation_block(operation)
value = machine_block_template();
value.start = operation.start;
value.end = operation.end;
value.job = operation.job;
value.opera = operation.operation;
end

function value = idle_block(startTime, endTime)
value = machine_block_template();
value.start = startTime;
value.end = endTime;
value.job = 0;
value.opera = 0;
end

function validate_inputs(baseline, fault, state, impact)
if ~baseline.isFaultFreeBaseline || ~fault.is_validated || ...
        ~state.is_validated || ~impact.is_validated
    error('build_stage_a_machine_right_shift:InvalidInput', ...
        'Validated Stage A inputs are required.');
end
if impact.unavailable_interval.machine_id ~= fault.machine_id || ...
        abs(impact.unavailable_interval.start_time - ...
        fault.start_time) > 1e-9 || ...
        abs(impact.unavailable_interval.end_time - ...
        fault.repair_end_time) > 1e-9
    error('build_stage_a_machine_right_shift:IntervalMismatch', ...
        'Impact interval does not match the fault event.');
end
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('build_stage_a_machine_right_shift:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
