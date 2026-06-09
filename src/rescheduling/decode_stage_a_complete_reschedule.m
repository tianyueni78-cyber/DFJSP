function candidate = decode_stage_a_complete_reschedule( ...
        baseline, frozen, decision)
%DECODE_STAGE_A_COMPLETE_RESCHEDULE Decode unstarted operations after fault.
%   The decision changes only unstarted operation order, machine choice,
%   AGV assignment, and transport speed. Frozen operations remain fixed.

if nargin < 3
    error('decode_stage_a_complete_reschedule:MissingInput', ...
        'baseline, frozen, and decision are required.');
end

require_fields(baseline, {'problem', 'machineData', 'agvData', ...
    'isFaultFreeBaseline'}, 'baseline');
require_fields(frozen, {'frozen_operations', ...
    'reschedulable_operations', 'job_boundaries', ...
    'machine_boundaries', 'agv_boundaries', ...
    'snapshot_time', 'is_validated'}, 'frozen');
require_fields(decision, {'operation_sequence', 'machine_choice', ...
    'agv_assignment', 'free_speed_choice', ...
    'load_speed_choice'}, 'decision');
validate_decision(baseline, frozen, decision);

operationRecords = initialize_operation_records(frozen);
transportRecords = transport_template();
transportRecords = transportRecords([]);
jobState = frozen.job_boundaries;
machineAvailable = [frozen.machine_boundaries.available_time];
agvAvailable = [frozen.agv_boundaries.available_time];
agvLocation = [frozen.agv_boundaries.location];
nextOperation = [frozen.job_boundaries.completed_prefix] + 1;

for sequenceIndex = 1:numel(decision.operation_sequence)
    jobId = decision.operation_sequence(sequenceIndex);
    operationId = nextOperation(jobId);
    sourceIndex = find_reschedulable_operation( ...
        frozen.reschedulable_operations, jobId, operationId);
    source = frozen.reschedulable_operations(sourceIndex);

    machineChoice = decision.machine_choice(sourceIndex);
    machineId = source.candidate_machines(machineChoice);
    processingTime = source.processing_times(machineChoice);
    agvId = decision.agv_assignment(sourceIndex);
    freeSpeed = baseline.agvData.AGVSpeed( ...
        decision.free_speed_choice(sourceIndex));
    loadSpeed = baseline.agvData.AGVSpeed( ...
        decision.load_speed_choice(sourceIndex));

    jobReady = jobState(jobId).release_time;
    sourceMachine = jobState(jobId).source_machine;
    transportReady = jobReady;

    if sourceMachine ~= machineId
        [emptyRecord, loadedRecord] = schedule_transport_pair( ...
            baseline.machineData.distance_matrix, agvId, ...
            agvAvailable(agvId), agvLocation(agvId), ...
            jobId, operationId, jobReady, sourceMachine, ...
            machineId, freeSpeed, loadSpeed);
        if emptyRecord.duration > 1e-9
            transportRecords(end + 1) = emptyRecord;
        end
        transportRecords(end + 1) = loadedRecord;
        agvAvailable(agvId) = loadedRecord.end;
        agvLocation(agvId) = machineId;
        transportReady = loadedRecord.end;
    end

    startTime = max([jobReady, transportReady, ...
        machineAvailable(machineId)]);
    endTime = startTime + processingTime;

    operation = operation_template();
    operation.machine_id = machineId;
    operation.job = jobId;
    operation.operation = operationId;
    operation.start = startTime;
    operation.end = endTime;
    operation.duration = processingTime;
    operation.status = 'rescheduled';
    operation.baseline_machine_id = source.baseline_machine_id;
    operation.baseline_start = source.baseline_start;
    operation.baseline_end = source.baseline_end;
    operationRecords(end + 1) = operation;

    machineAvailable(machineId) = endTime;
    jobState(jobId).release_time = endTime;
    jobState(jobId).source_machine = machineId;
    nextOperation(jobId) = operationId + 1;
end

machineTable = rebuild_machine_table( ...
    operationRecords, baseline.problem.machineNum);
validation = validate_candidate( ...
    operationRecords, transportRecords, frozen, baseline.problem);

candidate = struct();
candidate.stage = 'A';
candidate.strategy = 'complete_rescheduling';
candidate.decision = decision;
candidate.operation_records = operationRecords;
candidate.transport_records = transportRecords;
candidate.machineTable = machineTable;
candidate.machine_makespan = max([operationRecords.end]);
candidate.final_job_state = jobState;
candidate.final_machine_available = machineAvailable;
candidate.final_agv_available = agvAvailable;
candidate.final_agv_location = agvLocation;
candidate.validation = validation;
candidate.is_search_executed = false;
candidate.is_complete_reschedule_decoded = true;
candidate.is_validated = true;
end

function records = initialize_operation_records(frozen)
template = operation_template();
records = repmat(template, 1, numel(frozen.frozen_operations));
for index = 1:numel(frozen.frozen_operations)
    source = frozen.frozen_operations(index);
    records(index).machine_id = source.machine_id;
    records(index).job = source.job;
    records(index).operation = source.operation;
    records(index).start = source.start;
    records(index).end = source.end;
    records(index).duration = source.end - source.start;
    records(index).status = source.status;
    records(index).baseline_machine_id = source.machine_id;
    records(index).baseline_start = source.start;
    records(index).baseline_end = source.end;
end
end

function [emptyRecord, loadedRecord] = schedule_transport_pair( ...
        distanceMatrix, agvId, agvReady, agvLocation, ...
        jobId, operationId, jobReady, sourceMachine, ...
        targetMachine, freeSpeed, loadSpeed)
emptyDuration = spare_transfer_time_compute( ...
    agvLocation, sourceMachine, distanceMatrix, freeSpeed);
emptyRecord = transport_template();
emptyRecord.agv_id = agvId;
emptyRecord.job = jobId;
emptyRecord.operation = operationId;
emptyRecord.load_status = -1;
emptyRecord.from_machine = agvLocation;
emptyRecord.to_machine = sourceMachine;
emptyRecord.start = agvReady;
emptyRecord.end = agvReady + emptyDuration;
emptyRecord.duration = emptyDuration;
emptyRecord.speed = freeSpeed;

loadedDuration = load_transfer_time_compute( ...
    sourceMachine, targetMachine, distanceMatrix, loadSpeed);
loadedRecord = transport_template();
loadedRecord.agv_id = agvId;
loadedRecord.job = jobId;
loadedRecord.operation = operationId;
loadedRecord.load_status = -2;
loadedRecord.from_machine = sourceMachine;
loadedRecord.to_machine = targetMachine;
loadedRecord.start = max(emptyRecord.end, jobReady);
loadedRecord.end = loadedRecord.start + loadedDuration;
loadedRecord.duration = loadedDuration;
loadedRecord.speed = loadSpeed;
end

function index = find_reschedulable_operation(records, jobId, operationId)
index = find([records.job] == jobId & ...
    [records.operation] == operationId);
if numel(index) ~= 1
    error('decode_stage_a_complete_reschedule:OperationNotAvailable', ...
        'J%d-O%d is not a unique reschedulable operation.', ...
        jobId, operationId);
end
end

function machineTable = rebuild_machine_table(records, machineCount)
machineTable = cell(1, machineCount);
for machineId = 1:machineCount
    machineRecords = records([records.machine_id] == machineId);
    [~, order] = sort([machineRecords.start]);
    machineRecords = machineRecords(order);
    blockTemplate = machine_block_template();
    blocks = blockTemplate([]);
    cursor = 0;
    for index = 1:numel(machineRecords)
        if machineRecords(index).start > cursor
            blocks(end + 1) = machine_idle_block( ...
                cursor, machineRecords(index).start);
        end
        blocks(end + 1) = machine_operation_block( ...
            machineRecords(index));
        cursor = machineRecords(index).end;
    end
    blocks(end + 1) = machine_idle_block(cursor, Inf);
    machineTable{machineId} = blocks;
end
end

function validation = validate_candidate( ...
        operations, transports, frozen, problem)
tolerance = 1e-9;
validate_operation_partition(operations, problem.operaNumVec);
validate_frozen_operations(operations, frozen, tolerance);
validate_machine_non_overlap(operations, problem.machineNum, tolerance);
validate_job_precedence(operations, problem.operaNumVec, tolerance);
validate_transport_constraints(operations, transports, tolerance);

validation = struct();
validation.operation_partition = true;
validation.frozen_operations_preserved = true;
validation.machine_non_overlap = true;
validation.job_precedence = true;
validation.agv_non_overlap = true;
validation.transport_job_readiness = true;
validation.transport_arrival_before_processing = true;
end

function validate_operation_partition(operations, operaNumVec)
if numel(operations) ~= sum(operaNumVec)
    error('decode_stage_a_complete_reschedule:OperationCount', ...
        'Candidate operation count does not match the problem.');
end
for jobId = 1:numel(operaNumVec)
    for operationId = 1:operaNumVec(jobId)
        match = find([operations.job] == jobId & ...
            [operations.operation] == operationId);
        if numel(match) ~= 1
            error('decode_stage_a_complete_reschedule:OperationPartition', ...
                'J%d-O%d must appear exactly once.', jobId, operationId);
        end
    end
end
end

function validate_frozen_operations(operations, frozen, tolerance)
for index = 1:numel(frozen.frozen_operations)
    source = frozen.frozen_operations(index);
    match = find([operations.job] == source.job & ...
        [operations.operation] == source.operation);
    target = operations(match);
    if target.machine_id ~= source.machine_id || ...
            abs(target.start - source.start) > tolerance || ...
            abs(target.end - source.end) > tolerance
        error('decode_stage_a_complete_reschedule:FrozenChanged', ...
            'Frozen operation J%d-O%d was changed.', ...
            source.job, source.operation);
    end
end
end

function validate_machine_non_overlap(operations, machineCount, tolerance)
for machineId = 1:machineCount
    records = operations([operations.machine_id] == machineId);
    [~, order] = sort([records.start]);
    records = records(order);
    for index = 1:numel(records) - 1
        if records(index).end > records(index + 1).start + tolerance
            error('decode_stage_a_complete_reschedule:MachineOverlap', ...
                'Machine %d has overlapping operations.', machineId);
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
            error('decode_stage_a_complete_reschedule:JobPrecedence', ...
                'J%d-O%d finishes after its successor starts.', ...
                jobId, operationId);
        end
    end
end
end

function validate_transport_constraints(operations, transports, tolerance)
for agvId = unique([transports.agv_id])
    records = transports([transports.agv_id] == agvId);
    [~, order] = sort([records.start]);
    records = records(order);
    for index = 1:numel(records) - 1
        if records(index).end > records(index + 1).start + tolerance
            error('decode_stage_a_complete_reschedule:AGVOverlap', ...
                'AGV %d has overlapping transports.', agvId);
        end
    end
end

for index = 1:numel(transports)
    transport = transports(index);
    if transport.load_status ~= -2
        continue
    end
    operation = find_operation( ...
        operations, transport.job, transport.operation);
    if transport.end > operation.start + tolerance
        error('decode_stage_a_complete_reschedule:LateTransport', ...
            'Transport for J%d-O%d arrives after processing starts.', ...
            transport.job, transport.operation);
    end
    if transport.operation > 1
        predecessor = find_operation( ...
            operations, transport.job, transport.operation - 1);
        if transport.start < predecessor.end - tolerance
            error('decode_stage_a_complete_reschedule:EarlyTransport', ...
                'Transport for J%d-O%d starts before job readiness.', ...
                transport.job, transport.operation);
        end
    end
end
end

function operation = find_operation(records, jobId, operationId)
match = find([records.job] == jobId & ...
    [records.operation] == operationId);
if numel(match) ~= 1
    error('decode_stage_a_complete_reschedule:OperationNotUnique', ...
        'J%d-O%d must appear exactly once.', jobId, operationId);
end
operation = records(match);
end

function validate_decision(baseline, frozen, decision)
if ~baseline.isFaultFreeBaseline || ~frozen.is_validated
    error('decode_stage_a_complete_reschedule:InvalidInput', ...
        'Validated baseline and frozen problem are required.');
end

operationCount = numel(frozen.reschedulable_operations);
fields = {'machine_choice', 'agv_assignment', ...
    'free_speed_choice', 'load_speed_choice'};
if numel(decision.operation_sequence) ~= operationCount
    error('decode_stage_a_complete_reschedule:SequenceLength', ...
        'Operation sequence length must match reschedulable operations.');
end
for index = 1:numel(fields)
    if numel(decision.(fields{index})) ~= operationCount
        error('decode_stage_a_complete_reschedule:DecisionLength', ...
            '%s length must match reschedulable operations.', fields{index});
    end
end

expectedCounts = zeros(1, baseline.problem.jobNum);
for index = 1:operationCount
    expectedCounts(frozen.reschedulable_operations(index).job) = ...
        expectedCounts(frozen.reschedulable_operations(index).job) + 1;
end
actualCounts = zeros(1, baseline.problem.jobNum);
for jobId = decision.operation_sequence
    if jobId < 1 || jobId > baseline.problem.jobNum || ...
            jobId ~= floor(jobId)
        error('decode_stage_a_complete_reschedule:InvalidSequenceJob', ...
            'Operation sequence contains an invalid job id.');
    end
    actualCounts(jobId) = actualCounts(jobId) + 1;
end
if ~isequal(actualCounts, expectedCounts)
    error('decode_stage_a_complete_reschedule:SequenceCounts', ...
        'Operation sequence job counts do not match the frozen problem.');
end

speedCount = numel(baseline.agvData.AGVSpeed);
for index = 1:operationCount
    source = frozen.reschedulable_operations(index);
    assert_integer_range(decision.machine_choice(index), ...
        1, numel(source.candidate_machines), 'machine_choice');
    assert_integer_range(decision.agv_assignment(index), ...
        1, baseline.agvData.AGVNum, 'agv_assignment');
    assert_integer_range(decision.free_speed_choice(index), ...
        1, speedCount, 'free_speed_choice');
    assert_integer_range(decision.load_speed_choice(index), ...
        1, speedCount, 'load_speed_choice');
end
end

function assert_integer_range(value, lower, upper, field)
if ~isscalar(value) || value ~= floor(value) || ...
        value < lower || value > upper
    error('decode_stage_a_complete_reschedule:DecisionRange', ...
        '%s contains an out-of-range value.', field);
end
end

function value = operation_template()
value = struct('machine_id', [], 'job', [], 'operation', [], ...
    'start', [], 'end', [], 'duration', [], 'status', '', ...
    'baseline_machine_id', [], 'baseline_start', [], ...
    'baseline_end', []);
end

function value = transport_template()
value = struct('agv_id', [], 'job', [], 'operation', [], ...
    'load_status', [], 'from_machine', [], 'to_machine', [], ...
    'start', [], 'end', [], 'duration', [], 'speed', []);
end

function value = machine_block_template()
value = struct('start', [], 'end', [], 'job', [], 'opera', []);
end

function value = machine_operation_block(operation)
value = machine_block_template();
value.start = operation.start;
value.end = operation.end;
value.job = operation.job;
value.opera = operation.operation;
end

function value = machine_idle_block(startTime, endTime)
value = machine_block_template();
value.start = startTime;
value.end = endTime;
value.job = 0;
value.opera = 0;
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('decode_stage_a_complete_reschedule:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
