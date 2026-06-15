clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'fault'));
addpath(fullfile(projectRoot, 'src', 'state'));

baseline = run_normal_schedule_baseline();
[snapshotTime, activeMachines] = find_multi_machine_snapshot( ...
    baseline.machineTable);

raw = repmat(raw_fault_template(), 1, 2);
raw(1) = make_fault(1, activeMachines(1), snapshotTime);
raw(2) = make_fault(2, activeMachines(2), snapshotTime);
faults = normalize_stage_c_fault_events( ...
    raw, baseline.problem.machineNum);
state = extract_stage_c_event_group_state(baseline, faults, 1);

assert(state.is_validated);
assert(~state.is_rescheduled);
assert(strcmp(state.stage, 'C'));
assert(state.event_group == 1);
assert(isequal(state.event_ids, [1, 2]));
assert(abs(state.snapshot_time - snapshotTime) <= 1e-9);
assert(isequal(state.failed_machine_ids, activeMachines(1:2)));
assert(state.counts.fault_in_progress_operations == 2);
assert(all(ismember([state.fault_in_progress_operations.machine_id], ...
    activeMachines(1:2))));
assert(all([state.fault_in_progress_operations.elapsed_processing_time] > 0));
assert(all([state.fault_in_progress_operations.remaining_processing_time] > 0));

operationCount = state.counts.completed_operations + ...
    state.counts.normal_in_progress_operations + ...
    state.counts.fault_in_progress_operations + ...
    state.counts.unstarted_operations;
assert(operationCount == sum(baseline.problem.operaNumVec));
assert(all_ended_by(state.completed_operations, snapshotTime));
assert(all_active_at(state.normal_in_progress_operations, snapshotTime));
assert(all_active_at(state.fault_in_progress_operations, snapshotTime));
assert(all_start_at_or_after(state.unstarted_operations, snapshotTime));
assert(all_ended_by(state.completed_transports, snapshotTime));
assert(all_active_at(state.in_progress_transports, snapshotTime));
assert(all_start_at_or_after(state.unstarted_transports, snapshotTime));
assert(isequal(state.active_agv_ids, ...
    unique([state.in_progress_transports.agv_id], 'stable')));

expect_error(@() extract_stage_c_event_group_state( ...
    baseline, faults, 2), ...
    'extract_stage_c_event_group_state:UnknownEventGroup');

fprintf('test_stage_c_event_group_state passed\n');

function [snapshotTime, activeMachines] = ...
        find_multi_machine_snapshot(machineTable)
candidateTimes = [];
for machineId = 1:numel(machineTable)
    blocks = machineTable{machineId};
    for index = 1:numel(blocks)
        block = blocks(index);
        if block.job > 0 && block.opera > 0 && isfinite(block.end) && ...
                block.end > block.start
            candidateTimes(end + 1) = (block.start + block.end) / 2;
        end
    end
end
candidateTimes = unique(candidateTimes);
for index = 1:numel(candidateTimes)
    time = candidateTimes(index);
    machines = active_machine_ids(machineTable, time);
    if numel(machines) >= 2
        snapshotTime = time;
        activeMachines = machines;
        return
    end
end
error('test_stage_c_event_group_state:NoMultiMachineSnapshot', ...
    'The source baseline has no time with two active machines.');
end

function machines = active_machine_ids(machineTable, snapshotTime)
machines = [];
for machineId = 1:numel(machineTable)
    blocks = machineTable{machineId};
    active = false;
    for index = 1:numel(blocks)
        block = blocks(index);
        active = active || (block.job > 0 && block.opera > 0 && ...
            block.start < snapshotTime && snapshotTime < block.end);
    end
    if active
        machines(end + 1) = machineId;
    end
end
end

function value = raw_fault_template()
value = struct('event_id', [], 'machine_id', [], 'start_time', [], ...
    'repair_duration', [], 'repair_end_time', [], ...
    'interruption_rule', '');
end

function value = make_fault(eventId, machineId, startTime)
value = raw_fault_template();
value.event_id = eventId;
value.machine_id = machineId;
value.start_time = startTime;
value.repair_duration = 5;
value.interruption_rule = 'resume_remaining';
end

function result = all_ended_by(tasks, snapshotTime)
result = isempty(tasks) || all([tasks.end] <= snapshotTime);
end

function result = all_active_at(tasks, snapshotTime)
result = isempty(tasks) || all([tasks.start] < snapshotTime & ...
    snapshotTime < [tasks.end]);
end

function result = all_start_at_or_after(tasks, snapshotTime)
result = isempty(tasks) || all([tasks.start] >= snapshotTime);
end

function expect_error(action, expectedIdentifier)
try
    action();
catch errorInfo
    assert(strcmp(errorInfo.identifier, expectedIdentifier), ...
        'Expected %s but received %s.', ...
        expectedIdentifier, errorInfo.identifier);
    return
end
error('test_stage_c_event_group_state:ExpectedErrorNotRaised', ...
    'Expected error was not raised: %s', expectedIdentifier);
end
