function frozen = build_stage_br_frozen_problem( ...
        baseline, fault, state, restartPlan)
%BUILD_STAGE_BR_FROZEN_PROBLEM Define the Stage B-R search boundary.
%   Completed operations and all operations active at the fault time are
%   frozen. The interrupted operation keeps its lost pre-fault segment
%   and its full restart segment as a fixed two-segment commitment.
%   Only operations and transports not started at the fault time are
%   released for later complete rescheduling.

if nargin < 4
    error('build_stage_br_frozen_problem:MissingInput', ...
        'baseline, fault, state, and restartPlan are required.');
end
require_fields(baseline, {'machineTable', 'AGVTable', 'agvEGRecord', ...
    'problem', 'agvData', 'energyConfig', ...
    'isFaultFreeBaseline'}, 'baseline');
require_fields(baseline.problem, {'jobNum', 'jobInfo', ...
    'operaNumVec', 'machineNum', 'candidateMachine'}, ...
    'baseline.problem');
require_fields(baseline.agvData, {'AGVNum'}, 'baseline.agvData');
require_fields(fault, {'stage', 'machine_id', 'start_time', ...
    'repair_end_time', 'is_validated'}, 'fault');
require_fields(state, {'stage', 'snapshot_time', ...
    'completed_operations', 'in_progress_operations', ...
    'unstarted_operations', 'interrupted_operation', ...
    'is_validated', 'is_rescheduled'}, 'state');
require_fields(restartPlan, {'stage', 'step', 'rule', 'machine_id', ...
    'job', 'operation', 'original_start', 'original_end', ...
    'original_duration', 'lost_processing_segment', ...
    'lost_processing_time', 'restart_segment', ...
    'total_machine_processing_time', 'revised_completion_time', ...
    'restart_from_zero', 'progress_preserved', ...
    'is_validated'}, 'restartPlan');
validate_inputs(baseline, fault, state, restartPlan);

[completedTransports, inProgressTransports, unstartedTransports] = ...
    classify_transports(baseline.AGVTable, state.snapshot_time);
frozenOperations = build_frozen_operations(state, restartPlan);
reschedulableOperations = build_reschedulable_operations( ...
    state.unstarted_operations, baseline.problem);
jobBoundaries = build_job_boundaries( ...
    baseline.problem, frozenOperations, state.snapshot_time);
machineBoundaries = build_machine_boundaries( ...
    baseline.problem.machineNum, state, fault, restartPlan);
agvBoundaries = build_agv_boundaries( ...
    baseline.AGVTable, baseline.agvEGRecord, ...
    baseline.energyConfig.AGVEG_MAX, state.snapshot_time);

frozen = struct();
frozen.stage = 'B-R';
frozen.step = 6;
frozen.strategy = 'complete_rescheduling';
frozen.snapshot_time = state.snapshot_time;
frozen.repair_interval = struct( ...
    'machine_id', fault.machine_id, ...
    'start_time', fault.start_time, ...
    'end_time', fault.repair_end_time);
frozen.interrupted_commitment = build_interrupted_commitment( ...
    restartPlan);
frozen.frozen_operations = frozenOperations;
frozen.reschedulable_operations = reschedulableOperations;
frozen.frozen_completed_transports = completedTransports;
frozen.frozen_in_progress_transports = inProgressTransports;
frozen.released_baseline_transports = unstartedTransports;
frozen.job_boundaries = jobBoundaries;
frozen.machine_boundaries = machineBoundaries;
frozen.agv_boundaries = agvBoundaries;
frozen.counts = struct( ...
    'frozen_operations', numel(frozenOperations), ...
    'reschedulable_operations', numel(reschedulableOperations), ...
    'frozen_completed_transports', numel(completedTransports), ...
    'frozen_in_progress_transports', numel(inProgressTransports), ...
    'released_baseline_transports', numel(unstartedTransports));
frozen.decoder_requirement = 'stage_br_restart_operation_decoder';
frozen.stage_a_decoder_compatible = false;
frozen.baseline_modified = false;
frozen.is_search_executed = false;
frozen.is_validated = validate_frozen_problem( ...
    frozen, baseline.problem, baseline.AGVTable, state, restartPlan);
end

function records = build_frozen_operations(state, restartPlan)
template = frozen_operation_template();
records = template([]);
for index = 1:numel(state.completed_operations)
    source = state.completed_operations(index);
    record = operation_from_state(source, template);
    record.processing_duration = source.end - source.start;
    record.calendar_span = record.processing_duration;
    record.status = 'completed';
    records(end + 1) = record;
end
for index = 1:numel(state.in_progress_operations)
    source = state.in_progress_operations(index);
    record = operation_from_state(source, template);
    if source.job == restartPlan.job && ...
            source.operation == restartPlan.operation
        record.end = restartPlan.revised_completion_time;
        record.processing_duration = restartPlan.original_duration;
        record.calendar_span = record.end - record.start;
        record.status = 'interrupted_restart_committed';
        record.is_interrupted = true;
        record.restart_from_zero = true;
        record.lost_processing_time = ...
            restartPlan.lost_processing_time;
        record.total_machine_processing_time = ...
            restartPlan.total_machine_processing_time;
    else
        record.processing_duration = source.end - source.start;
        record.calendar_span = record.processing_duration;
        record.status = 'in_progress';
    end
    records(end + 1) = record;
end
end

function record = operation_from_state(source, template)
record = template;
record.machine_id = source.machine_id;
record.job = source.job;
record.operation = source.operation;
record.start = source.start;
record.end = source.end;
end

function commitment = build_interrupted_commitment(restartPlan)
commitment = struct();
commitment.rule = restartPlan.rule;
commitment.machine_id = restartPlan.machine_id;
commitment.job = restartPlan.job;
commitment.operation = restartPlan.operation;
commitment.original_start = restartPlan.original_start;
commitment.original_end = restartPlan.original_end;
commitment.original_duration = restartPlan.original_duration;
commitment.lost_processing_segment = restartPlan.lost_processing_segment;
commitment.lost_processing_time = restartPlan.lost_processing_time;
commitment.restart_segment = restartPlan.restart_segment;
commitment.total_machine_processing_time = ...
    restartPlan.total_machine_processing_time;
commitment.revised_completion_time = ...
    restartPlan.revised_completion_time;
commitment.machine_migration_allowed = false;
commitment.restart_from_zero = true;
commitment.progress_preserved = false;
end

function records = build_reschedulable_operations(unstarted, problem)
template = reschedulable_operation_template();
records = repmat(template, 1, numel(unstarted));
for index = 1:numel(unstarted)
    jobId = unstarted(index).job;
    operationId = unstarted(index).operation;
    candidates = problem.candidateMachine{jobId, operationId};
    if isempty(candidates)
        error('build_stage_br_frozen_problem:NoCandidateMachine', ...
            'J%d-O%d has no candidate machine.', jobId, operationId);
    end
    records(index).job = jobId;
    records(index).operation = operationId;
    records(index).baseline_machine_id = unstarted(index).machine_id;
    records(index).baseline_start = unstarted(index).start;
    records(index).baseline_end = unstarted(index).end;
    records(index).candidate_machines = candidates(:).';
    records(index).processing_times = ...
        problem.jobInfo{jobId}(operationId, candidates);
end
end

function boundaries = build_job_boundaries( ...
        problem, frozenOperations, snapshotTime)
template = job_boundary_template();
boundaries = repmat(template, 1, problem.jobNum);
for jobId = 1:problem.jobNum
    operations = frozenOperations([frozenOperations.job] == jobId);
    boundaries(jobId).job = jobId;
    boundaries(jobId).release_time = snapshotTime;
    boundaries(jobId).source_machine = -1;
    boundaries(jobId).completed_prefix = 0;
    boundaries(jobId).contains_interrupted_commitment = false;
    if isempty(operations)
        continue
    end
    [~, order] = sort([operations.operation]);
    operations = operations(order);
    if ~isequal([operations.operation], 1:numel(operations))
        error('build_stage_br_frozen_problem:NonPrefixFrozenJob', ...
            'Frozen operations for job %d must form a prefix.', jobId);
    end
    last = operations(end);
    boundaries(jobId).completed_prefix = last.operation;
    boundaries(jobId).release_time = max(snapshotTime, last.end);
    boundaries(jobId).source_machine = last.machine_id;
    boundaries(jobId).contains_interrupted_commitment = ...
        any([operations.is_interrupted]);
end
end

function boundaries = build_machine_boundaries( ...
        machineCount, state, fault, restartPlan)
template = machine_boundary_template();
boundaries = repmat(template, 1, machineCount);
for machineId = 1:machineCount
    availableTime = state.snapshot_time;
    active = state.in_progress_operations( ...
        [state.in_progress_operations.machine_id] == machineId);
    for index = 1:numel(active)
        if active(index).job == restartPlan.job && ...
                active(index).operation == restartPlan.operation
            availableTime = max( ...
                availableTime, restartPlan.revised_completion_time);
        else
            availableTime = max(availableTime, active(index).end);
        end
    end
    if machineId == fault.machine_id
        availableTime = max(availableTime, fault.repair_end_time);
    end
    boundaries(machineId).machine_id = machineId;
    boundaries(machineId).available_time = availableTime;
    boundaries(machineId).has_repair_constraint = ...
        machineId == fault.machine_id;
    boundaries(machineId).has_interrupted_commitment = ...
        machineId == restartPlan.machine_id;
end
end

function boundaries = build_agv_boundaries( ...
        AGVTable, agvEGRecord, maximumEnergy, snapshotTime)
template = agv_boundary_template();
boundaries = repmat(template, 1, numel(AGVTable));
for agvId = 1:numel(AGVTable)
    blocks = AGVTable{agvId};
    availableTime = snapshotTime;
    location = -1;
    lastEnd = -Inf;
    hasInProgress = false;
    for index = 1:numel(blocks)
        block = blocks(index);
        if ~is_real_agv_activity(block)
            continue
        end
        if block.end <= snapshotTime && block.end >= lastEnd
            lastEnd = block.end;
            location = block.to_machine;
        elseif block.start < snapshotTime && snapshotTime < block.end
            availableTime = block.end;
            location = block.to_machine;
            hasInProgress = true;
        end
    end
    boundaries(agvId).agv_id = agvId;
    boundaries(agvId).available_time = availableTime;
    boundaries(agvId).location = location;
    boundaries(agvId).energy = energy_at_time( ...
        agvEGRecord{agvId}, availableTime, maximumEnergy);
    boundaries(agvId).consumed_energy = energy_consumed_at_time( ...
        agvEGRecord{agvId}, availableTime);
    boundaries(agvId).charge_count = count_completed_charges( ...
        blocks, availableTime);
    boundaries(agvId).has_in_progress_activity = hasInProgress;
end
end

function [completed, inProgress, unstarted] = ...
        classify_transports(AGVTable, snapshotTime)
template = transport_template();
completed = template([]);
inProgress = template([]);
unstarted = template([]);
for agvId = 1:numel(AGVTable)
    blocks = AGVTable{agvId};
    for tableIndex = 1:numel(blocks)
        block = blocks(tableIndex);
        if ~is_job_transport(block)
            continue
        end
        record = template;
        record.agv_id = agvId;
        record.table_index = tableIndex;
        record.job = block.job;
        record.operation = block.opera;
        record.load_status = block.load_status;
        record.from_machine = block.from_machine;
        record.to_machine = block.to_machine;
        record.start = block.start;
        record.end = block.end;
        if block.end <= snapshotTime
            completed(end + 1) = record;
        elseif block.start < snapshotTime && snapshotTime < block.end
            inProgress(end + 1) = record;
        else
            unstarted(end + 1) = record;
        end
    end
end
end

function consumed = energy_consumed_at_time(records, boundaryTime)
consumed = 0;
if size(records, 1) < 2
    return
end
eligible = records(records(:, 1) <= boundaryTime + 1e-9, :);
for index = 2:size(eligible, 1)
    drop = eligible(index - 1, 2) - eligible(index, 2);
    if drop > 0
        consumed = consumed + drop;
    end
end
end

function energy = energy_at_time(records, boundaryTime, maximumEnergy)
energy = maximumEnergy;
if isempty(records)
    return
end
eligible = find(records(:, 1) <= boundaryTime + 1e-9);
if ~isempty(eligible)
    energy = records(eligible(end), 2);
end
end

function count = count_completed_charges(blocks, boundaryTime)
count = 0;
for index = 1:numel(blocks)
    if blocks(index).charge == 1 && isfinite(blocks(index).end) && ...
            blocks(index).end <= boundaryTime + 1e-9
        count = count + 1;
    end
end
end

function result = is_real_agv_activity(block)
result = isfinite(block.end) && ...
    ~(block.job == 0 && block.opera == 0 && ...
    block.load_status == 0 && block.charge == 0);
end

function result = is_job_transport(block)
result = block.job > 0 && block.charge == 0 && ...
    any(block.load_status == [-1, -2]) && isfinite(block.end);
end

function result = validate_frozen_problem( ...
        frozen, problem, AGVTable, state, restartPlan)
expectedOperations = sum(problem.operaNumVec);
if frozen.counts.frozen_operations + ...
        frozen.counts.reschedulable_operations ~= expectedOperations
    error('build_stage_br_frozen_problem:OperationPartitionMismatch', ...
        'Frozen and reschedulable operations must partition the problem.');
end
interrupted = frozen.frozen_operations( ...
    [frozen.frozen_operations.is_interrupted]);
if numel(interrupted) ~= 1 || ...
        interrupted.job ~= restartPlan.job || ...
        interrupted.operation ~= restartPlan.operation || ...
        abs(interrupted.end - ...
        restartPlan.revised_completion_time) > 1e-9 || ...
        abs(interrupted.processing_duration - ...
        restartPlan.original_duration) > 1e-9 || ...
        ~interrupted.restart_from_zero || ...
        abs(interrupted.lost_processing_time - ...
        restartPlan.lost_processing_time) > 1e-9 || ...
        abs(interrupted.total_machine_processing_time - ...
        restartPlan.total_machine_processing_time) > 1e-9
    error('build_stage_br_frozen_problem:InterruptedMismatch', ...
        'Interrupted commitment is not represented correctly.');
end
for index = 1:numel(frozen.reschedulable_operations)
    operation = frozen.reschedulable_operations(index);
    if numel(operation.candidate_machines) ~= ...
            numel(operation.processing_times) || ...
            any(operation.processing_times <= 0)
        error('build_stage_br_frozen_problem:CandidateDataMismatch', ...
            'Candidate machine data is invalid.');
    end
end
transportCount = frozen.counts.frozen_completed_transports + ...
    frozen.counts.frozen_in_progress_transports + ...
    frozen.counts.released_baseline_transports;
partitionCount = count_state_transports( ...
    frozen.frozen_completed_transports, ...
    frozen.frozen_in_progress_transports, ...
    frozen.released_baseline_transports);
if transportCount ~= partitionCount || ...
        transportCount ~= count_job_transports(AGVTable)
    error('build_stage_br_frozen_problem:TransportPartitionMismatch', ...
        'Transport sets do not form a complete partition.');
end
if frozen.counts.reschedulable_operations ~= ...
        numel(state.unstarted_operations) || ...
        frozen.stage_a_decoder_compatible || ...
        ~strcmp(frozen.decoder_requirement, ...
        'stage_br_restart_operation_decoder')
    error('build_stage_br_frozen_problem:InvalidBoundary', ...
        'Stage B-R decoder boundary is inconsistent.');
end
result = true;
end

function count = count_job_transports(AGVTable)
count = 0;
for agvId = 1:numel(AGVTable)
    blocks = AGVTable{agvId};
    for index = 1:numel(blocks)
        if is_job_transport(blocks(index))
            count = count + 1;
        end
    end
end
end

function count = count_state_transports(completed, inProgress, unstarted)
allRecords = [completed, inProgress, unstarted];
identities = cell(1, numel(allRecords));
for index = 1:numel(allRecords)
    identities{index} = sprintf('%d:%d', ...
        allRecords(index).agv_id, allRecords(index).table_index);
end
if numel(unique(identities)) ~= numel(identities)
    error('build_stage_br_frozen_problem:DuplicateTransport', ...
        'A transport appears in more than one state set.');
end
count = numel(allRecords);
end

function value = frozen_operation_template()
value = struct('machine_id', [], 'job', [], 'operation', [], ...
    'start', [], 'end', [], 'processing_duration', [], ...
    'calendar_span', [], 'status', '', 'is_interrupted', false, ...
    'restart_from_zero', false, 'lost_processing_time', 0, ...
    'total_machine_processing_time', []);
end

function value = reschedulable_operation_template()
value = struct('job', [], 'operation', [], ...
    'baseline_machine_id', [], 'baseline_start', [], ...
    'baseline_end', [], 'candidate_machines', [], ...
    'processing_times', []);
end

function value = job_boundary_template()
value = struct('job', [], 'completed_prefix', [], ...
    'release_time', [], 'source_machine', [], ...
    'contains_interrupted_commitment', false);
end

function value = machine_boundary_template()
value = struct('machine_id', [], 'available_time', [], ...
    'has_repair_constraint', false, ...
    'has_interrupted_commitment', false);
end

function value = agv_boundary_template()
value = struct('agv_id', [], 'available_time', [], 'location', [], ...
    'energy', [], 'consumed_energy', [], 'charge_count', [], ...
    'has_in_progress_activity', false);
end

function value = transport_template()
value = struct('agv_id', [], 'table_index', [], 'job', [], ...
    'operation', [], 'load_status', [], 'from_machine', [], ...
    'to_machine', [], 'start', [], 'end', []);
end

function validate_inputs(baseline, fault, state, restartPlan)
if ~baseline.isFaultFreeBaseline || ~fault.is_validated || ...
        ~state.is_validated || state.is_rescheduled || ...
        ~restartPlan.is_validated || ~strcmp(fault.stage, 'B') || ...
        ~strcmp(state.stage, 'B') || ...
        ~strcmp(restartPlan.stage, 'B-R') || restartPlan.step ~= 1 || ...
        ~strcmp(restartPlan.rule, 'restart_on_original_machine') || ...
        ~restartPlan.restart_from_zero || restartPlan.progress_preserved
    error('build_stage_br_frozen_problem:InvalidInput', ...
        'Validated Stage B snapshot and Stage B-R restart plan are required.');
end
if abs(state.snapshot_time - fault.start_time) > 1e-9 || ...
        restartPlan.machine_id ~= fault.machine_id || ...
        restartPlan.job ~= state.interrupted_operation.job || ...
        restartPlan.operation ~= state.interrupted_operation.operation
    error('build_stage_br_frozen_problem:BoundaryMismatch', ...
        'Fault, state, and restart plan boundaries do not match.');
end
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('build_stage_br_frozen_problem:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end

