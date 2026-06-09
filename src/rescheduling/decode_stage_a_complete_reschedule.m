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
    'energyConfig', 'isFaultFreeBaseline'}, 'baseline');
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
activityRecords = transport_template();
activityRecords = activityRecords([]);
jobState = frozen.job_boundaries;
machineAvailable = [frozen.machine_boundaries.available_time];
agvAvailable = [frozen.agv_boundaries.available_time];
agvLocation = [frozen.agv_boundaries.location];
agvEnergy = [frozen.agv_boundaries.energy];
agvConsumedEnergy = [frozen.agv_boundaries.consumed_energy];
agvChargeCount = [frozen.agv_boundaries.charge_count];
nextOperation = [frozen.job_boundaries.completed_prefix] + 1;
jobCompleteUnload = initialize_frozen_unloads( ...
    baseline.AGVTable, frozen.snapshot_time, baseline.problem.jobNum);

for sequenceIndex = 1:numel(decision.operation_sequence)
    [activityRecords, agvAvailable, agvLocation, agvEnergy, ...
        agvConsumedEnergy, agvChargeCount] = ...
        charge_low_energy_agvs(activityRecords, ...
        agvAvailable, agvLocation, agvEnergy, ...
        agvConsumedEnergy, agvChargeCount, baseline);

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
    freeEnergyRate = baseline.agvData.AGVEnergy.free( ...
        decision.free_speed_choice(sourceIndex));
    loadEnergyRate = baseline.agvData.AGVEnergy.load( ...
        decision.load_speed_choice(sourceIndex));

    jobReady = jobState(jobId).release_time;
    sourceMachine = jobState(jobId).source_machine;
    transportReady = jobReady;

    if sourceMachine ~= machineId
        [emptyRecord, loadedRecord] = schedule_transport_pair( ...
            baseline.machineData.distance_matrix, agvId, ...
            agvAvailable(agvId), agvLocation(agvId), ...
            jobId, operationId, jobReady, sourceMachine, ...
            machineId, freeSpeed, loadSpeed, ...
            freeEnergyRate, loadEnergyRate);
        if emptyRecord.duration > 1e-9
            transportRecords(end + 1) = emptyRecord;
            activityRecords(end + 1) = emptyRecord;
            agvEnergy(agvId) = agvEnergy(agvId) - ...
                emptyRecord.energy_use;
            agvConsumedEnergy(agvId) = ...
                agvConsumedEnergy(agvId) + emptyRecord.energy_use;
        end
        transportRecords(end + 1) = loadedRecord;
        activityRecords(end + 1) = loadedRecord;
        agvEnergy(agvId) = agvEnergy(agvId) - ...
            loadedRecord.energy_use;
        agvConsumedEnergy(agvId) = ...
            agvConsumedEnergy(agvId) + loadedRecord.energy_use;
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

    if operationId == baseline.problem.operaNumVec(jobId)
        [emptyUnload, loadedUnload, returnAgv] = ...
            schedule_final_unload(baseline, agvAvailable, ...
            agvLocation, jobId, machineId, endTime);
        if emptyUnload.duration > 1e-9
            transportRecords(end + 1) = emptyUnload;
            activityRecords(end + 1) = emptyUnload;
            agvEnergy(returnAgv) = agvEnergy(returnAgv) - ...
                emptyUnload.energy_use;
            agvConsumedEnergy(returnAgv) = ...
                agvConsumedEnergy(returnAgv) + ...
                emptyUnload.energy_use;
        end
        transportRecords(end + 1) = loadedUnload;
        activityRecords(end + 1) = loadedUnload;
        agvEnergy(returnAgv) = agvEnergy(returnAgv) - ...
            loadedUnload.energy_use;
        agvConsumedEnergy(returnAgv) = ...
            agvConsumedEnergy(returnAgv) + ...
            loadedUnload.energy_use;
        agvAvailable(returnAgv) = loadedUnload.end;
        agvLocation(returnAgv) = -2;
        jobCompleteUnload(jobId) = loadedUnload.end;
    end
end

for jobId = find(jobCompleteUnload == 0)
    lastOperation = find_operation(operationRecords, jobId, ...
        baseline.problem.operaNumVec(jobId));
    [emptyUnload, loadedUnload, returnAgv] = ...
        schedule_final_unload(baseline, agvAvailable, ...
        agvLocation, jobId, lastOperation.machine_id, ...
        lastOperation.end);
    if emptyUnload.duration > 1e-9
        transportRecords(end + 1) = emptyUnload;
        activityRecords(end + 1) = emptyUnload;
        agvEnergy(returnAgv) = agvEnergy(returnAgv) - ...
            emptyUnload.energy_use;
        agvConsumedEnergy(returnAgv) = agvConsumedEnergy(returnAgv) + ...
            emptyUnload.energy_use;
    end
    transportRecords(end + 1) = loadedUnload;
    activityRecords(end + 1) = loadedUnload;
    agvEnergy(returnAgv) = agvEnergy(returnAgv) - ...
        loadedUnload.energy_use;
    agvConsumedEnergy(returnAgv) = agvConsumedEnergy(returnAgv) + ...
        loadedUnload.energy_use;
    agvAvailable(returnAgv) = loadedUnload.end;
    agvLocation(returnAgv) = -2;
    jobCompleteUnload(jobId) = loadedUnload.end;
end

machineTable = rebuild_machine_table( ...
    operationRecords, baseline.problem.machineNum);
validation = validate_candidate( ...
    operationRecords, transportRecords, activityRecords, ...
    frozen, baseline.problem, jobCompleteUnload, agvEnergy);
[machineEnergy, agvEnergyUse] = calculate_energy( ...
    operationRecords, baseline, agvConsumedEnergy);

candidate = struct();
candidate.stage = 'A';
candidate.strategy = 'complete_rescheduling';
candidate.decision = decision;
candidate.operation_records = operationRecords;
candidate.transport_records = transportRecords;
candidate.agv_activity_records = activityRecords;
candidate.machineTable = machineTable;
candidate.machine_makespan = max([operationRecords.end]);
candidate.job_complete_unload = jobCompleteUnload;
candidate.makespan = max(jobCompleteUnload);
candidate.machine_energy = machineEnergy;
candidate.agv_energy = agvEnergyUse;
candidate.total_energy = machineEnergy + agvEnergyUse;
candidate.final_agv_energy = agvEnergy;
candidate.agv_charge_count = agvChargeCount;
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
        targetMachine, freeSpeed, loadSpeed, ...
        freeEnergyRate, loadEnergyRate)
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
emptyRecord.energy_use = emptyDuration * freeEnergyRate;
emptyRecord.charge = 0;
emptyRecord.activity_type = 'empty_transport';

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
loadedRecord.energy_use = loadedDuration * loadEnergyRate;
loadedRecord.charge = 0;
loadedRecord.activity_type = 'loaded_transport';
end

function completion = initialize_frozen_unloads( ...
        AGVTable, snapshotTime, jobCount)
completion = zeros(1, jobCount);
for agvId = 1:numel(AGVTable)
    blocks = AGVTable{agvId};
    for index = 1:numel(blocks)
        block = blocks(index);
        if block.job > 0 && block.opera == -1 && ...
                block.load_status == -2 && block.charge == 0 && ...
                block.start < snapshotTime && isfinite(block.end)
            completion(block.job) = block.end;
        end
    end
end
end

function [records, available, location, energy, consumed, chargeCount] = ...
        charge_low_energy_agvs(records, available, location, energy, ...
        consumed, chargeCount, baseline)
maximumEnergy = baseline.energyConfig.AGVEG_MAX;
minimumEnergy = baseline.energyConfig.AGVEG_MIN;
chargeSpeed = baseline.energyConfig.eChargeSpeed;
fastestIndex = numel(baseline.agvData.AGVSpeed);
fastestSpeed = baseline.agvData.AGVSpeed(fastestIndex);
freeRate = baseline.agvData.AGVEnergy.free(fastestIndex);

for agvId = 1:numel(available)
    if energy(agvId) > minimumEnergy
        continue
    end
    if location(agvId) ~= -2
        duration = distance_to_unload( ...
            location(agvId), baseline.machineData.distance_matrix) / ...
            fastestSpeed;
        travel = transport_template();
        travel.agv_id = agvId;
        travel.load_status = -1;
        travel.from_machine = location(agvId);
        travel.to_machine = -2;
        travel.start = available(agvId);
        travel.end = travel.start + duration;
        travel.duration = duration;
        travel.speed = fastestSpeed;
        travel.energy_use = duration * freeRate;
        travel.charge = 2;
        travel.activity_type = 'travel_to_charge';
        records(end + 1) = travel;
        available(agvId) = travel.end;
        location(agvId) = -2;
        energy(agvId) = energy(agvId) - travel.energy_use;
        consumed(agvId) = consumed(agvId) + travel.energy_use;
    end

    chargeDuration = max(0, maximumEnergy - energy(agvId)) / ...
        chargeSpeed;
    charging = transport_template();
    charging.agv_id = agvId;
    charging.load_status = 0;
    charging.from_machine = -2;
    charging.to_machine = -2;
    charging.start = available(agvId);
    charging.end = charging.start + chargeDuration;
    charging.duration = chargeDuration;
    charging.speed = 0;
    charging.energy_use = 0;
    charging.charge = 1;
    charging.activity_type = 'charging';
    records(end + 1) = charging;
    available(agvId) = charging.end;
    energy(agvId) = maximumEnergy;
    chargeCount(agvId) = chargeCount(agvId) + 1;
end
end

function [emptyRecord, loadedRecord, returnAgv] = ...
        schedule_final_unload( ...
        baseline, agvAvailable, agvLocation, jobId, ...
        sourceMachine, jobReady)
fastestIndex = numel(baseline.agvData.AGVSpeed);
speed = baseline.agvData.AGVSpeed(fastestIndex);
freeRate = baseline.agvData.AGVEnergy.free(fastestIndex);
loadRate = baseline.agvData.AGVEnergy.load(fastestIndex);
arrival = zeros(1, numel(agvAvailable));
for agvId = 1:numel(agvAvailable)
    arrival(agvId) = agvAvailable(agvId) + ...
        spare_transfer_time_compute(agvLocation(agvId), ...
        sourceMachine, baseline.machineData.distance_matrix, speed);
end
leave = max(arrival, jobReady);
candidates = find(leave == min(leave));
if numel(candidates) > 1
    [~, latestArrival] = max(arrival(candidates));
    returnAgv = candidates(latestArrival);
else
    returnAgv = candidates(1);
end

emptyDuration = spare_transfer_time_compute( ...
    agvLocation(returnAgv), sourceMachine, ...
    baseline.machineData.distance_matrix, speed);
emptyRecord = transport_template();
emptyRecord.agv_id = returnAgv;
emptyRecord.job = jobId;
emptyRecord.operation = -1;
emptyRecord.load_status = -1;
emptyRecord.from_machine = agvLocation(returnAgv);
emptyRecord.to_machine = sourceMachine;
emptyRecord.start = agvAvailable(returnAgv);
emptyRecord.end = emptyRecord.start + emptyDuration;
emptyRecord.duration = emptyDuration;
emptyRecord.speed = speed;
emptyRecord.energy_use = emptyDuration * freeRate;
emptyRecord.charge = 0;
emptyRecord.activity_type = 'empty_final_unload';

loadedDuration = baseline.machineData.distance_matrix. ...
    machine_to_unload(sourceMachine) / speed;
loadedRecord = transport_template();
loadedRecord.agv_id = returnAgv;
loadedRecord.job = jobId;
loadedRecord.operation = -1;
loadedRecord.load_status = -2;
loadedRecord.from_machine = sourceMachine;
loadedRecord.to_machine = -2;
loadedRecord.start = max(emptyRecord.end, jobReady);
loadedRecord.end = loadedRecord.start + loadedDuration;
loadedRecord.duration = loadedDuration;
loadedRecord.speed = speed;
loadedRecord.energy_use = loadedDuration * loadRate;
loadedRecord.charge = 0;
loadedRecord.activity_type = 'loaded_final_unload';
end

function distance = distance_to_unload(location, distanceMatrix)
if location == -2
    distance = 0;
elseif location == -1
    distance = distanceMatrix.load_to_unload;
else
    distance = distanceMatrix.machine_to_unload(location);
end
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
        operations, transports, activities, frozen, problem, ...
        jobCompleteUnload, agvEnergy)
tolerance = 1e-9;
validate_operation_partition(operations, problem.operaNumVec);
validate_frozen_operations(operations, frozen, tolerance);
validate_machine_non_overlap(operations, problem.machineNum, tolerance);
validate_job_precedence(operations, problem.operaNumVec, tolerance);
validate_transport_constraints( ...
    operations, transports, activities, problem.operaNumVec, tolerance);
if any(jobCompleteUnload <= 0) || any(~isfinite(jobCompleteUnload))
    error('decode_stage_a_complete_reschedule:FinalUnload', ...
        'Every job must have one finite final-unload completion time.');
end
if any(~isfinite(agvEnergy))
    error('decode_stage_a_complete_reschedule:AGVEnergy', ...
        'Final AGV energy must be finite.');
end

validation = struct();
validation.operation_partition = true;
validation.frozen_operations_preserved = true;
validation.machine_non_overlap = true;
validation.job_precedence = true;
validation.agv_non_overlap = true;
validation.transport_job_readiness = true;
validation.transport_arrival_before_processing = true;
validation.final_unload_complete = true;
validation.agv_energy_tracked = true;
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

function validate_transport_constraints( ...
        operations, transports, activities, operaNumVec, tolerance)
for agvId = unique([activities.agv_id])
    records = activities([activities.agv_id] == agvId);
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
    if transport.operation == -1
        lastOperation = find_operation(operations, transport.job, ...
            operaNumVec(transport.job));
        if transport.start < lastOperation.end - tolerance
            error('decode_stage_a_complete_reschedule:EarlyFinalUnload', ...
                'Final unload starts before job completion.');
        end
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

function [machineEnergy, agvEnergy] = calculate_energy( ...
        operations, baseline, agvConsumedEnergy)
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
end
rates = baseline.machineData.machineEnergy;
machineEnergy = rates.work(1:machineCount)' * work + ...
    rates.free(1:machineCount)' * idle;
agvEnergy = sum(agvConsumedEnergy);
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
    'start', [], 'end', [], 'duration', [], 'speed', [], ...
    'energy_use', [], 'charge', [], 'activity_type', '');
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
