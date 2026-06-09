function frozen = build_stage_a_frozen_problem(baseline, fault, state)
%BUILD_STAGE_A_FROZEN_PROBLEM Build the post-fault rescheduling boundary.
%   Completed and in-progress operations are frozen. Unstarted operations
%   remain decision variables. Baseline unstarted transports are released
%   because the complete-rescheduling search may reassign AGVs.

if nargin < 3
    error('build_stage_a_frozen_problem:MissingInput', ...
        'baseline, fault, and state are required.');
end

require_fields(baseline, {'machineTable', 'AGVTable', 'problem', ...
    'agvData', 'isFaultFreeBaseline'}, 'baseline');
require_fields(fault, {'machine_id', 'start_time', ...
    'repair_end_time', 'is_validated'}, 'fault');
require_fields(state, {'snapshot_time', 'completed_operations', ...
    'in_progress_operations', 'unstarted_operations', ...
    'unstarted_transports', 'is_validated', 'is_rescheduled'}, 'state');
require_fields(baseline.problem, {'jobNum', 'jobInfo', ...
    'operaNumVec', 'machineNum', 'candidateMachine'}, ...
    'baseline.problem');
require_fields(baseline.agvData, {'AGVNum'}, 'baseline.agvData');
validate_inputs(baseline, fault, state);

frozenOperations = build_frozen_operations(state);
reschedulableOperations = build_reschedulable_operations( ...
    state.unstarted_operations, baseline.problem);
jobBoundaries = build_job_boundaries( ...
    baseline.problem, frozenOperations, state.snapshot_time);
machineBoundaries = build_machine_boundaries( ...
    baseline.machineTable, fault, state.snapshot_time);
agvBoundaries = build_agv_boundaries( ...
    baseline.AGVTable, state.snapshot_time);

frozen = struct();
frozen.stage = 'A';
frozen.strategy = 'complete_rescheduling';
frozen.snapshot_time = state.snapshot_time;
frozen.repair_interval = struct( ...
    'machine_id', fault.machine_id, ...
    'start_time', fault.start_time, ...
    'end_time', fault.repair_end_time);
frozen.frozen_operations = frozenOperations;
frozen.reschedulable_operations = reschedulableOperations;
frozen.released_baseline_transports = state.unstarted_transports;
frozen.job_boundaries = jobBoundaries;
frozen.machine_boundaries = machineBoundaries;
frozen.agv_boundaries = agvBoundaries;
frozen.counts = struct( ...
    'frozen_operations', numel(frozenOperations), ...
    'reschedulable_operations', numel(reschedulableOperations), ...
    'released_baseline_transports', numel(state.unstarted_transports));
frozen.baseline_modified = false;
frozen.is_search_executed = false;
frozen.is_validated = validate_frozen_problem( ...
    frozen, baseline.problem, state);
end

function records = build_frozen_operations(state)
template = frozen_operation_template();
records = template([]);
categories = {'completed_operations', 'in_progress_operations'};
statusValues = {'completed', 'in_progress'};

for categoryIndex = 1:numel(categories)
    tasks = state.(categories{categoryIndex});
    for index = 1:numel(tasks)
        record = template;
        record.machine_id = tasks(index).machine_id;
        record.job = tasks(index).job;
        record.operation = tasks(index).operation;
        record.start = tasks(index).start;
        record.end = tasks(index).end;
        record.status = statusValues{categoryIndex};
        records(end + 1) = record;
    end
end
end

function records = build_reschedulable_operations(unstarted, problem)
template = reschedulable_operation_template();
records = repmat(template, 1, numel(unstarted));

for index = 1:numel(unstarted)
    jobId = unstarted(index).job;
    operationId = unstarted(index).operation;
    candidates = problem.candidateMachine{jobId, operationId};
    if isempty(candidates)
        error('build_stage_a_frozen_problem:NoCandidateMachine', ...
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

    if isempty(operations)
        continue
    end

    [~, order] = sort([operations.operation]);
    operations = operations(order);
    expected = 1:numel(operations);
    if ~isequal([operations.operation], expected)
        error('build_stage_a_frozen_problem:NonPrefixFrozenJob', ...
            'Frozen operations for job %d must form a prefix.', jobId);
    end

    last = operations(end);
    boundaries(jobId).completed_prefix = last.operation;
    boundaries(jobId).release_time = max(snapshotTime, last.end);
    boundaries(jobId).source_machine = last.machine_id;
end
end

function boundaries = build_machine_boundaries( ...
        machineTable, fault, snapshotTime)
template = machine_boundary_template();
boundaries = repmat(template, 1, numel(machineTable));

for machineId = 1:numel(machineTable)
    availableTime = snapshotTime;
    blocks = machineTable{machineId};
    for index = 1:numel(blocks)
        block = blocks(index);
        if block.job > 0 && block.opera > 0 && ...
                block.start < snapshotTime && snapshotTime < block.end
            availableTime = max(availableTime, block.end);
        end
    end
    if machineId == fault.machine_id
        availableTime = max(availableTime, fault.repair_end_time);
    end

    boundaries(machineId).machine_id = machineId;
    boundaries(machineId).available_time = availableTime;
    boundaries(machineId).has_repair_constraint = ...
        machineId == fault.machine_id;
end
end

function boundaries = build_agv_boundaries(AGVTable, snapshotTime)
template = agv_boundary_template();
boundaries = repmat(template, 1, numel(AGVTable));

for agvId = 1:numel(AGVTable)
    blocks = AGVTable{agvId};
    availableTime = snapshotTime;
    location = -1;
    lastEnd = -Inf;

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
        end
    end

    boundaries(agvId).agv_id = agvId;
    boundaries(agvId).available_time = availableTime;
    boundaries(agvId).location = location;
end
end

function result = is_real_agv_activity(block)
result = isfinite(block.end) && ...
    ~(block.job == 0 && block.opera == 0 && ...
    block.load_status == 0 && block.charge == 0);
end

function result = validate_frozen_problem(frozen, problem, state)
expectedOperations = sum(problem.operaNumVec);
if frozen.counts.frozen_operations + ...
        frozen.counts.reschedulable_operations ~= expectedOperations
    error('build_stage_a_frozen_problem:OperationPartitionMismatch', ...
        'Frozen and reschedulable operations must partition the problem.');
end

for index = 1:numel(frozen.reschedulable_operations)
    operation = frozen.reschedulable_operations(index);
    if numel(operation.candidate_machines) ~= ...
            numel(operation.processing_times)
        error('build_stage_a_frozen_problem:CandidateDataMismatch', ...
            'Candidate machines and processing times must align.');
    end
    if any(operation.processing_times <= 0)
        error('build_stage_a_frozen_problem:InvalidProcessingTime', ...
            'Candidate processing times must be positive.');
    end
end

if frozen.counts.released_baseline_transports ~= ...
        numel(state.unstarted_transports)
    error('build_stage_a_frozen_problem:TransportCountMismatch', ...
        'Released transport count does not match the state snapshot.');
end
result = true;
end

function value = frozen_operation_template()
value = struct('machine_id', [], 'job', [], 'operation', [], ...
    'start', [], 'end', [], 'status', '');
end

function value = reschedulable_operation_template()
value = struct('job', [], 'operation', [], ...
    'baseline_machine_id', [], 'baseline_start', [], ...
    'baseline_end', [], 'candidate_machines', [], ...
    'processing_times', []);
end

function value = job_boundary_template()
value = struct('job', [], 'completed_prefix', [], ...
    'release_time', [], 'source_machine', []);
end

function value = machine_boundary_template()
value = struct('machine_id', [], 'available_time', [], ...
    'has_repair_constraint', false);
end

function value = agv_boundary_template()
value = struct('agv_id', [], 'available_time', [], 'location', []);
end

function validate_inputs(baseline, fault, state)
if ~baseline.isFaultFreeBaseline || ~fault.is_validated || ...
        ~state.is_validated || state.is_rescheduled
    error('build_stage_a_frozen_problem:InvalidInput', ...
        'Validated baseline, fault, and unchanged snapshot are required.');
end
if abs(state.snapshot_time - fault.start_time) > 1e-9
    error('build_stage_a_frozen_problem:SnapshotMismatch', ...
        'State snapshot time must equal the fault start time.');
end
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('build_stage_a_frozen_problem:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
