function candidate = build_stage_c_simultaneous_agv_linked_right_shift( ...
        baseline, faults, machineCandidate, agvImpact)
%BUILD_STAGE_C_SIMULTANEOUS_AGV_LINKED_RIGHT_SHIFT Couple AGV and machines.
%   Machine and AGV assignments, routes, sequence, and durations remain
%   unchanged. Completed AGV activities are frozen. Every interrupted
%   operation keeps its two fixed processing segments.

if nargin < 4
    error('build_stage_c_simultaneous_agv_linked_right_shift:MissingInput', ...
        'baseline, faults, machineCandidate, and agvImpact are required.');
end
require_fields(baseline, {'machineTable', 'AGVTable', 'problem', ...
    'isFaultFreeBaseline'}, 'baseline');
require_fields(baseline.problem, {'operaNumVec'}, 'baseline.problem');
require_fields(machineCandidate, {'stage', 'step', ...
    'operation_records', 'interrupted_commitments', 'AGVTable', ...
    'is_machine_validated', 'is_agv_updated'}, 'machineCandidate');
require_fields(agvImpact, {'stage', 'step', 'is_validated', ...
    'requires_agv_adjustment'}, 'agvImpact');
validate_inputs(baseline, faults, machineCandidate, agvImpact);

operations = machineCandidate.operation_records;
activities = collect_agv_activities( ...
    baseline.AGVTable, faults(1).start_time);
[operations, activities, iterationCount] = propagate_times( ...
    operations, activities, baseline.problem.operaNumVec, ...
    faults, machineCandidate.interrupted_commitments);

processingSegments = build_processing_segments( ...
    operations, machineCandidate.interrupted_commitments);
machineTable = rebuild_machine_table( ...
    processingSegments, numel(baseline.machineTable));
AGVTable = rebuild_agv_table(activities, numel(baseline.AGVTable));
validation = validate_candidate(operations, processingSegments, ...
    activities, baseline.problem.operaNumVec, faults, ...
    machineCandidate.interrupted_commitments);

candidate = machineCandidate;
candidate.step = 8;
candidate.machineTable = machineTable;
candidate.AGVTable = AGVTable;
candidate.operation_records = operations;
candidate.processing_segments = processingSegments;
candidate.agv_activity_records = activities;
candidate.machine_makespan = max([operations.end]);
candidate.propagation_iterations = iterationCount;
candidate.machine_only_validation = machineCandidate.validation;
candidate.validation = validation;
candidate.is_agv_updated = any_activity_changed(activities);
candidate.is_agv_validated = true;
candidate.is_fully_validated = true;
candidate.agv_impact_required_adjustment = ...
    agvImpact.requires_agv_adjustment;
end

function [operations, activities, iterationCount] = propagate_times( ...
        operations, activities, operaNumVec, faults, commitments)
tolerance = 1e-9;
maximumIterations = 10000;
for iterationCount = 1:maximumIterations
    previousOperationStarts = [operations.start];
    previousActivityStarts = [activities.start];

    activities = update_agv_activities( ...
        activities, operations, operaNumVec);
    operations = update_operations( ...
        operations, activities, operaNumVec, faults, commitments);

    operationChange = max(abs( ...
        [operations.start] - previousOperationStarts));
    if isempty(activities)
        activityChange = 0;
    else
        activityChange = max(abs( ...
            [activities.start] - previousActivityStarts));
    end
    if operationChange <= tolerance && activityChange <= tolerance
        return
    end
end
error('build_stage_c_simultaneous_agv_linked_right_shift:NoConvergence', ...
    'Stage C simultaneous AGV-machine propagation did not converge.');
end

function activities = update_agv_activities( ...
        activities, operations, operaNumVec)
for agvId = unique([activities.agv_id])
    indices = find([activities.agv_id] == agvId);
    [~, order] = sort([activities(indices).original_table_index]);
    indices = indices(order);
    previousEnd = 0;
    for position = 1:numel(indices)
        index = indices(position);
        if activities(index).is_frozen
            if activities(index).start < previousEnd - 1e-9
                error('build_stage_c_simultaneous_agv_linked_right_shift:FrozenOverlap', ...
                    'A frozen AGV activity conflicts with its predecessor.');
            end
        else
            earliest = max(activities(index).original_start, previousEnd);
            if activities(index).load_status == -2
                earliest = max(earliest, job_ready_time( ...
                    activities(index), operations, operaNumVec));
            end
            activities(index).start = earliest;
            activities(index).end = earliest + activities(index).duration;
        end
        previousEnd = activities(index).end;
    end
end
end
function readyTime = job_ready_time(activity, operations, operaNumVec)
if activity.job <= 0
    readyTime = 0;
elseif activity.operation == -1
    operation = find_operation( ...
        operations, activity.job, operaNumVec(activity.job));
    readyTime = operation.end;
elseif activity.operation <= 1
    readyTime = 0;
else
    operation = find_operation( ...
        operations, activity.job, activity.operation - 1);
    readyTime = operation.end;
end
end

function operations = update_operations( ...
        operations, activities, operaNumVec, faults, commitments)
machineOrders = build_machine_orders(operations);
jobOrders = build_job_orders(operations, operaNumVec);
operationOrder = topological_operation_order( ...
    operations, machineOrders, jobOrders);

for orderIndex = 1:numel(operationOrder)
    index = operationOrder(orderIndex);
    operation = operations(index);
    if operation.is_interrupted
        validate_interrupted_root(operation, commitments);
        continue
    end

    earliest = operation.start;
    machinePredecessor = predecessor_index( ...
        machineOrders{operation.machine_id}, index);
    if machinePredecessor > 0
        earliest = max(earliest, operations(machinePredecessor).end);
    end
    if operation.operation > 1
        jobPredecessor = jobOrders{operation.job}( ...
            operation.operation - 1);
        earliest = max(earliest, operations(jobPredecessor).end);
    end
    transportEnd = loaded_transport_end( ...
        activities, operation.job, operation.operation);
    if ~isempty(transportEnd)
        earliest = max(earliest, transportEnd);
    end
    earliest = move_after_repairs(earliest, ...
        operation.processing_duration, operation.machine_id, faults);

    operations(index).start = earliest;
    operations(index).end = earliest + operation.processing_duration;
    operations(index).calendar_span = operation.processing_duration;
    operations(index).is_affected = ...
        abs(earliest - operation.original_start) > 1e-9;
end
end

function validate_interrupted_root(operation, commitments)
commitment = find_commitment( ...
    commitments, operation.job, operation.operation);
if abs(operation.start - commitment.original_start) > 1e-9 || ...
        abs(operation.end - ...
        commitment.revised_completion_time) > 1e-9
    error('build_stage_c_simultaneous_agv_linked_right_shift:InterruptedRootChanged', ...
        'AGV feedback must not alter the fixed interrupted operation.');
end
end

function earliest = move_after_repairs( ...
        earliest, duration, machineId, faults)
matching = faults([faults.machine_id] == machineId);
for index = 1:numel(matching)
    fault = matching(index);
    if earliest < fault.repair_end_time && ...
            earliest + duration > fault.start_time
        earliest = fault.repair_end_time;
    end
end
end

function commitment = find_commitment(commitments, job, operation)
match = find([commitments.job] == job & ...
    [commitments.operation] == operation);
if numel(match) ~= 1
    error('build_stage_c_simultaneous_agv_linked_right_shift:CommitmentNotUnique', ...
        'Interrupted operation J%d-O%d requires one commitment.', ...
        job, operation);
end
commitment = commitments(match);
end

function order = topological_operation_order( ...
        operations, machineOrders, jobOrders)
count = numel(operations);
indegree = zeros(1, count);
successors = cell(1, count);
for machineId = 1:numel(machineOrders)
    sequence = machineOrders{machineId};
    for position = 1:numel(sequence) - 1
        [successors, indegree] = add_edge(successors, indegree, ...
            sequence(position), sequence(position + 1));
    end
end
for jobId = 1:numel(jobOrders)
    sequence = jobOrders{jobId};
    for position = 1:numel(sequence) - 1
        [successors, indegree] = add_edge(successors, indegree, ...
            sequence(position), sequence(position + 1));
    end
end

ready = find(indegree == 0);
order = zeros(1, count);
for outputIndex = 1:count
    if isempty(ready)
        error('build_stage_c_simultaneous_agv_linked_right_shift:OperationCycle', ...
            'Machine and job precedence constraints contain a cycle.');
    end
    [~, choice] = min([operations(ready).original_start]);
    current = ready(choice);
    ready(choice) = [];
    order(outputIndex) = current;
    for successor = successors{current}
        indegree(successor) = indegree(successor) - 1;
        if indegree(successor) == 0
            ready(end + 1) = successor;
        end
    end
end
end

function [successors, indegree] = add_edge( ...
        successors, indegree, source, target)
if any(successors{source} == target)
    return
end
successors{source}(end + 1) = target;
indegree(target) = indegree(target) + 1;
end

function orders = build_machine_orders(operations)
machineCount = max([operations.machine_id]);
orders = cell(1, machineCount);
for machineId = 1:machineCount
    indices = find([operations.machine_id] == machineId);
    ordering = [[operations(indices).original_start].', ...
        [operations(indices).original_table_index].'];
    [~, order] = sortrows(ordering, [1, 2]);
    orders{machineId} = indices(order);
end
end

function orders = build_job_orders(operations, operaNumVec)
orders = cell(1, numel(operaNumVec));
for jobId = 1:numel(operaNumVec)
    orders{jobId} = zeros(1, operaNumVec(jobId));
    for operationId = 1:operaNumVec(jobId)
        match = find([operations.job] == jobId & ...
            [operations.operation] == operationId);
        if numel(match) ~= 1
            error('build_stage_c_simultaneous_agv_linked_right_shift:OperationNotUnique', ...
                'Operation J%d-O%d must appear exactly once.', ...
                jobId, operationId);
        end
        orders{jobId}(operationId) = match;
    end
end
end

function predecessor = predecessor_index(sequence, current)
position = find(sequence == current);
if numel(position) ~= 1
    error('build_stage_c_simultaneous_agv_linked_right_shift:MachineOrder', ...
        'Operation must appear once in its machine order.');
end
if position == 1
    predecessor = 0;
else
    predecessor = sequence(position - 1);
end
end

function transferEnd = loaded_transport_end(activities, jobId, operationId)
match = find([activities.job] == jobId & ...
    [activities.operation] == operationId & ...
    [activities.load_status] == -2);
if isempty(match)
    transferEnd = [];
elseif numel(match) == 1
    transferEnd = activities(match).end;
else
    error('build_stage_c_simultaneous_agv_linked_right_shift:TransportNotUnique', ...
        'Loaded transport for J%d-O%d appears more than once.', ...
        jobId, operationId);
end
end

function activities = collect_agv_activities(AGVTable, faultTime)
template = activity_template();
activities = template([]);
for agvId = 1:numel(AGVTable)
    blocks = AGVTable{agvId};
    for tableIndex = 1:numel(blocks)
        block = blocks(tableIndex);
        isIdle = block.job == 0 && block.opera == 0 && ...
            block.load_status == 0 && block.charge == 0;
        if isIdle || ~isfinite(block.end)
            continue
        end
        activity = template;
        activity.agv_id = agvId;
        activity.original_table_index = tableIndex;
        activity.job = block.job;
        activity.operation = block.opera;
        activity.load_status = block.load_status;
        activity.from_machine = block.from_machine;
        activity.to_machine = block.to_machine;
        activity.charge = block.charge;
        activity.original_start = block.start;
        activity.original_end = block.end;
        activity.start = block.start;
        activity.end = block.end;
        activity.duration = block.end - block.start;
        activity.is_frozen = block.start < faultTime - 1e-9;
        activities(end + 1) = activity;
    end
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
        segments(end + 1) = segment_from_plan( ...
            operation, commitment.completed_segment, 1);
        segments(end + 1) = segment_from_plan( ...
            operation, commitment.resumed_segment, 2);
    else
        segment = template;
        segment.machine_id = operation.machine_id;
        segment.original_table_index = operation.original_table_index;
        segment.segment_order = 1;
        segment.segment_type = 'complete_operation';
        segment.job = operation.job;
        segment.operation = operation.operation;
        segment.start = operation.start;
        segment.end = operation.end;
        segment.processing_time = operation.processing_duration;
        segment.source_event_ids = operation.source_event_ids;
        segments(end + 1) = segment;
    end
end
end

function segment = segment_from_plan(operation, source, segmentOrder)
segment = segment_template();
segment.machine_id = source.machine_id;
segment.original_table_index = operation.original_table_index;
segment.segment_order = segmentOrder;
segment.segment_type = source.segment_type;
segment.job = source.job;
segment.operation = source.operation;
segment.start = source.start;
segment.end = source.end;
segment.processing_time = source.processing_time;
segment.source_event_ids = source.source_event_ids;
end

function machineTable = rebuild_machine_table(segments, machineCount)
machineTable = cell(1, machineCount);
for machineId = 1:machineCount
    indices = find([segments.machine_id] == machineId);
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
            blocks(end + 1) = machine_idle_block( ...
                cursor, ordered(index).start);
        end
        blocks(end + 1) = machine_operation_block(ordered(index));
        cursor = ordered(index).end;
    end
    blocks(end + 1) = machine_idle_block(cursor, Inf);
    machineTable{machineId} = blocks;
end
end

function AGVTable = rebuild_agv_table(activities, agvCount)
AGVTable = cell(1, agvCount);
for agvId = 1:agvCount
    indices = find([activities.agv_id] == agvId);
    [~, order] = sort([activities(indices).original_table_index]);
    ordered = activities(indices(order));
    template = agv_block_template();
    blocks = template([]);
    cursor = 0;
    location = -1;
    for index = 1:numel(ordered)
        if ordered(index).start > cursor
            blocks(end + 1) = agv_idle_block( ...
                cursor, ordered(index).start, location);
        end
        blocks(end + 1) = agv_activity_block(ordered(index));
        cursor = ordered(index).end;
        location = ordered(index).to_machine;
    end
    blocks(end + 1) = agv_idle_block(cursor, Inf, location);
    AGVTable{agvId} = blocks;
end
end

function validation = validate_candidate(operations, segments, ...
        activities, operaNumVec, faults, commitments)
tolerance = 1e-9;
validate_machine_constraints(segments, faults, tolerance);
validate_job_and_transport_constraints( ...
    operations, activities, operaNumVec, tolerance);
validate_agv_constraints(activities, operations, operaNumVec, tolerance);
validate_interrupted_segments(segments, commitments, tolerance);

validation = struct();
validation.machine_assignments_preserved = true;
validation.processing_durations_preserved = true;
validation.interrupted_segments_preserved = true;
validation.all_resume_commitments_preserved = true;
validation.completed_agv_activities_frozen = true;
validation.agv_assignments_preserved = true;
validation.agv_routes_preserved = true;
validation.agv_durations_preserved = true;
validation.agv_non_overlap = true;
validation.transport_job_readiness = true;
validation.transport_arrival_before_processing = true;
validation.machine_non_overlap_after_agv_feedback = true;
validation.job_precedence_after_agv_feedback = true;
validation.repair_intervals_after_agv_feedback = true;
end

function validate_machine_constraints(segments, faults, tolerance)
for machineId = unique([segments.machine_id])
    selected = segments([segments.machine_id] == machineId);
    [~, order] = sort([selected.start]);
    selected = selected(order);
    for index = 1:numel(selected) - 1
        if selected(index).end > selected(index + 1).start + tolerance
            error('build_stage_c_simultaneous_agv_linked_right_shift:MachineOverlap', ...
                'Machine %d has overlapping processing segments.', ...
                machineId);
        end
    end
end
for faultIndex = 1:numel(faults)
    fault = faults(faultIndex);
    failed = segments([segments.machine_id] == fault.machine_id);
    for index = 1:numel(failed)
        overlaps = failed(index).start < ...
            fault.repair_end_time - tolerance && ...
            fault.start_time < failed(index).end - tolerance;
        if overlaps
            error('build_stage_c_simultaneous_agv_linked_right_shift:RepairOverlap', ...
                'Failed machine %d processes during repair.', ...
                fault.machine_id);
        end
    end
end
end

function validate_job_and_transport_constraints( ...
        operations, activities, operaNumVec, tolerance)
for jobId = 1:numel(operaNumVec)
    for operationId = 1:operaNumVec(jobId)
        operation = find_operation(operations, jobId, operationId);
        if operationId > 1
            predecessor = find_operation( ...
                operations, jobId, operationId - 1);
            if predecessor.end > operation.start + tolerance
                error('build_stage_c_simultaneous_agv_linked_right_shift:JobPrecedence', ...
                    'J%d-O%d starts before its predecessor completes.', ...
                    jobId, operationId);
            end
        end
        arrival = loaded_transport_end( ...
            activities, jobId, operationId);
        if ~isempty(arrival) && arrival > operation.start + tolerance
            error('build_stage_c_simultaneous_agv_linked_right_shift:LateTransport', ...
                'Transport for J%d-O%d arrives after processing starts.', ...
                jobId, operationId);
        end
    end
end
end

function validate_agv_constraints( ...
        activities, operations, operaNumVec, tolerance)
for agvId = unique([activities.agv_id])
    records = activities([activities.agv_id] == agvId);
    [~, order] = sort([records.original_table_index]);
    records = records(order);
    for index = 1:numel(records) - 1
        if records(index).end > records(index + 1).start + tolerance
            error('build_stage_c_simultaneous_agv_linked_right_shift:AGVOverlap', ...
                'AGV %d has overlapping activities.', agvId);
        end
    end
end
for index = 1:numel(activities)
    activity = activities(index);
    if activity.is_frozen && ...
            (abs(activity.start - activity.original_start) > tolerance || ...
            abs(activity.end - activity.original_end) > tolerance)
        error('build_stage_c_simultaneous_agv_linked_right_shift:FrozenActivityChanged', ...
            'A completed AGV activity was changed.');
    end
    if activity.load_status == -2 && activity.job > 0
        ready = job_ready_time(activity, operations, operaNumVec);
        if activity.start < ready - tolerance
            error('build_stage_c_simultaneous_agv_linked_right_shift:EarlyTransport', ...
                'Loaded transport starts before its job is ready.');
        end
    end
end
end

function validate_interrupted_segments(segments, commitments, tolerance)
for commitmentIndex = 1:numel(commitments)
    commitment = commitments(commitmentIndex);
    selected = segments([segments.job] == commitment.job & ...
        [segments.operation] == commitment.operation);
    if numel(selected) ~= 2
        error('build_stage_c_simultaneous_agv_linked_right_shift:InterruptedSegments', ...
            'Interrupted operation must retain two segments.');
    end
    [~, order] = sort([selected.segment_order]);
    selected = selected(order);
    if abs(selected(1).start - ...
            commitment.completed_segment.start) > tolerance || ...
            abs(selected(1).end - ...
            commitment.completed_segment.end) > tolerance || ...
            abs(selected(2).start - ...
            commitment.resumed_segment.start) > tolerance || ...
            abs(selected(2).end - ...
            commitment.resumed_segment.end) > tolerance
        error('build_stage_c_simultaneous_agv_linked_right_shift:InterruptedSegments', ...
            'Interrupted processing segments changed during AGV feedback.');
    end
end
end

function changed = any_activity_changed(activities)
if isempty(activities)
    changed = false;
else
    changed = any(abs([activities.start] - ...
        [activities.original_start]) > 1e-9);
end
end

function operation = find_operation(records, jobId, operationId)
match = find([records.job] == jobId & ...
    [records.operation] == operationId);
if numel(match) ~= 1
    error('build_stage_c_simultaneous_agv_linked_right_shift:OperationNotUnique', ...
        'Operation J%d-O%d must appear exactly once.', ...
        jobId, operationId);
end
operation = records(match);
end

function value = activity_template()
value = struct('agv_id', [], 'original_table_index', [], ...
    'job', [], 'operation', [], 'load_status', [], ...
    'from_machine', [], 'to_machine', [], 'charge', [], ...
    'original_start', [], 'original_end', [], ...
    'start', [], 'end', [], 'duration', [], 'is_frozen', false);
end

function value = segment_template()
value = struct('machine_id', [], 'original_table_index', [], ...
    'segment_order', [], 'segment_type', '', 'job', [], ...
    'operation', [], 'start', [], 'end', [], ...
    'processing_time', [], 'source_event_ids', []);
end

function value = machine_block_template()
value = struct('start', [], 'end', [], 'job', [], 'opera', [], ...
    'segment_type', '', 'source_event_ids', []);
end

function value = machine_operation_block(segment)
value = machine_block_template();
value.start = segment.start;
value.end = segment.end;
value.job = segment.job;
value.opera = segment.operation;
value.segment_type = segment.segment_type;
value.source_event_ids = segment.source_event_ids;
end

function value = machine_idle_block(startTime, endTime)
value = machine_block_template();
value.start = startTime;
value.end = endTime;
value.job = 0;
value.opera = 0;
value.segment_type = 'idle';
end

function value = agv_block_template()
value = struct('start', [], 'end', [], 'job', [], 'opera', [], ...
    'load_status', [], 'from_machine', [], 'to_machine', [], ...
    'charge', []);
end

function value = agv_activity_block(activity)
value = agv_block_template();
value.start = activity.start;
value.end = activity.end;
value.job = activity.job;
value.opera = activity.operation;
value.load_status = activity.load_status;
value.from_machine = activity.from_machine;
value.to_machine = activity.to_machine;
value.charge = activity.charge;
end

function value = agv_idle_block(startTime, endTime, location)
value = agv_block_template();
value.start = startTime;
value.end = endTime;
value.job = 0;
value.opera = 0;
value.load_status = 0;
value.from_machine = location;
value.to_machine = 0;
value.charge = 0;
end

function validate_inputs(baseline, faults, machineCandidate, agvImpact)
for index = 1:numel(faults)
    require_fields(faults(index), {'event_id', 'stage', ...
        'machine_id', 'start_time', 'repair_end_time', ...
        'event_group', 'is_validated'}, 'faults');
end
if ~baseline.isFaultFreeBaseline || numel(faults) < 2 || ...
        ~all([faults.is_validated]) || ...
        ~machineCandidate.is_machine_validated || ...
        machineCandidate.is_agv_updated || ~agvImpact.is_validated || ...
        ~all(strcmp({faults.stage}, 'C')) || ...
        numel(unique([faults.event_group])) ~= 1 || ...
        max(abs([faults.start_time] - faults(1).start_time)) > 1e-9 || ...
        ~strcmp(machineCandidate.stage, 'C') || ...
        machineCandidate.step ~= 6 || ...
        ~strcmp(agvImpact.stage, 'C') || agvImpact.step ~= 7 || ...
        numel(machineCandidate.interrupted_commitments) ~= numel(faults)
    error('build_stage_c_simultaneous_agv_linked_right_shift:InvalidInput', ...
        'Validated Stage C Steps 6 and 7 are required.');
end
if ~isequaln(machineCandidate.AGVTable, baseline.AGVTable)
    error('build_stage_c_simultaneous_agv_linked_right_shift:AGVTableChanged', ...
        'Input candidate must still use the baseline AGV table.');
end
end

function require_fields(value, fields, valueName)
for index = 1:numel(fields)
    if ~isfield(value, fields{index})
        error('build_stage_c_simultaneous_agv_linked_right_shift:MissingField', ...
            '%s.%s is required.', valueName, fields{index});
    end
end
end
