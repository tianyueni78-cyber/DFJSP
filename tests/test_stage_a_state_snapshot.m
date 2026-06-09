clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'state'));

scenario = run_stage_a_state_snapshot();
state = scenario.state;
fault = scenario.fault;

requiredFields = {'stage', 'snapshot_time', 'completed_operations', ...
    'in_progress_operations', 'unstarted_operations', ...
    'completed_transports', 'in_progress_transports', ...
    'unstarted_transports', 'counts', 'is_validated', ...
    'is_rescheduled'};
for index = 1:numel(requiredFields)
    assert(isfield(state, requiredFields{index}), ...
        'Missing state field: %s', requiredFields{index});
end

assert(state.is_validated, 'State snapshot must be validated.');
assert(~state.is_rescheduled && ~scenario.is_rescheduled, ...
    'Stage A Step 3 must not perform rescheduling.');
assert(abs(state.snapshot_time - fault.start_time) <= 1e-9, ...
    'State snapshot time must equal the fault start time.');
assert(contains_operation(state.completed_operations, ...
    fault.trigger_job, fault.trigger_operation), ...
    'The trigger operation must be completed.');

operationCount = state.counts.completed_operations + ...
    state.counts.in_progress_operations + ...
    state.counts.unstarted_operations;
assert(operationCount == sum(scenario.baseline.problem.operaNumVec), ...
    'Every real operation must appear in exactly one state category.');

assert(all_ended_by(state.completed_operations, state.snapshot_time), ...
    'Completed operations must end by the snapshot time.');
assert(all_active_at(state.in_progress_operations, state.snapshot_time), ...
    'In-progress operations must contain the snapshot time.');
assert(all_start_at_or_after( ...
    state.unstarted_operations, state.snapshot_time), ...
    'Unstarted operations must start at or after the snapshot time.');
assert(all_ended_by(state.completed_transports, state.snapshot_time), ...
    'Completed transports must end by the snapshot time.');
assert(all_active_at(state.in_progress_transports, state.snapshot_time), ...
    'In-progress transports must contain the snapshot time.');
assert(all_start_at_or_after( ...
    state.unstarted_transports, state.snapshot_time), ...
    'Unstarted transports must start at or after the snapshot time.');

fprintf('test_stage_a_state_snapshot passed\n');

function result = contains_operation(tasks, jobId, operationId)
result = false;
for index = 1:numel(tasks)
    if tasks(index).job == jobId && ...
            tasks(index).operation == operationId
        result = true;
        return
    end
end
end

function result = all_ended_by(tasks, snapshotTime)
result = true;
for index = 1:numel(tasks)
    result = result && tasks(index).end <= snapshotTime;
end
end

function result = all_active_at(tasks, snapshotTime)
result = true;
for index = 1:numel(tasks)
    result = result && tasks(index).start < snapshotTime && ...
        snapshotTime < tasks(index).end;
end
end

function result = all_start_at_or_after(tasks, snapshotTime)
result = true;
for index = 1:numel(tasks)
    result = result && tasks(index).start >= snapshotTime;
end
end
