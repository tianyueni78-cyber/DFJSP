clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

scenario = run_stage_c_simultaneous_frozen_problem();
frozen = scenario.frozen_problem;
tolerance = 1e-9;

assert(scenario.is_validated);
assert(scenario.step == 9);
assert(scenario.is_frozen_problem_built);
assert(~scenario.is_search_executed);
assert(frozen.is_validated);
assert(~frozen.baseline_modified);
assert(~frozen.is_search_executed);
assert(~frozen.stage_a_decoder_compatible);
assert(strcmp(frozen.decoder_requirement, ...
    'stage_c_multiple_split_operation_decoder'));

operationCount = frozen.counts.frozen_operations + ...
    frozen.counts.reschedulable_operations;
assert(operationCount == sum(scenario.baseline.problem.operaNumVec));
assert(frozen.counts.reschedulable_operations == ...
    scenario.state.counts.unstarted_operations);
assert(frozen.counts.frozen_operations == ...
    scenario.state.counts.completed_operations + ...
    scenario.state.counts.normal_in_progress_operations + ...
    scenario.state.counts.fault_in_progress_operations);
assert(numel(frozen.repair_intervals) == numel(scenario.faults));
assert(numel(frozen.interrupted_commitments) == ...
    numel(scenario.faults));

interrupted = frozen.frozen_operations( ...
    [frozen.frozen_operations.is_interrupted]);
assert(numel(interrupted) == numel(frozen.interrupted_commitments));
for index = 1:numel(frozen.interrupted_commitments)
    commitment = frozen.interrupted_commitments(index);
    assert(commitment.progress_preserved);
    assert(~commitment.restart_from_zero);
    assert(~commitment.machine_migration_allowed);
    record = interrupted([interrupted.job] == commitment.job & ...
        [interrupted.operation] == commitment.operation);
    assert(numel(record) == 1);
    assert(strcmp(record.status, 'interrupted_committed'));
    assert(abs(record.end - ...
        commitment.revised_completion_time) <= tolerance);
    assert(abs(record.processing_duration - ...
        commitment.original_duration) <= tolerance);
    assert(record.calendar_span > record.processing_duration);

    jobBoundary = frozen.job_boundaries(commitment.job);
    assert(jobBoundary.contains_interrupted_commitment);
    assert(jobBoundary.completed_prefix == commitment.operation);
    assert(jobBoundary.release_time + tolerance >= ...
        commitment.revised_completion_time);

    machineBoundary = frozen.machine_boundaries( ...
        commitment.machine_id);
    assert(machineBoundary.has_repair_constraint);
    assert(machineBoundary.has_interrupted_commitment);
    assert(machineBoundary.available_time + tolerance >= ...
        commitment.revised_completion_time);
end

for index = 1:numel(frozen.reschedulable_operations)
    operation = frozen.reschedulable_operations(index);
    assert(~isempty(operation.candidate_machines));
    assert(numel(operation.candidate_machines) == ...
        numel(operation.processing_times));
    assert(all(operation.processing_times > 0));
end

assert_transport_partition(frozen, scenario.baseline.AGVTable);
assert_agv_boundaries(frozen, scenario);

reversed = build_stage_c_simultaneous_frozen_problem( ...
    scenario.baseline, scenario.faults(end:-1:1), ...
    scenario.state, ...
    scenario.machine_right_shift.interrupted_commitments(end:-1:1));
assert(isequaln(frozen.frozen_operations, ...
    reversed.frozen_operations));
assert(isequaln(frozen.reschedulable_operations, ...
    reversed.reschedulable_operations));
assert(isequaln(frozen.job_boundaries, reversed.job_boundaries));
assert(isequaln(frozen.machine_boundaries, ...
    reversed.machine_boundaries));

fprintf('test_stage_c_simultaneous_frozen_problem passed\n');

function assert_transport_partition(frozen, AGVTable)
expected = count_job_transports(AGVTable);
actual = frozen.counts.frozen_completed_transports + ...
    frozen.counts.frozen_in_progress_transports + ...
    frozen.counts.released_baseline_transports;
assert(actual == expected);
end

function count = count_job_transports(AGVTable)
count = 0;
for agvId = 1:numel(AGVTable)
    for index = 1:numel(AGVTable{agvId})
        block = AGVTable{agvId}(index);
        if block.job > 0 && block.charge == 0 && ...
                any(block.load_status == [-1, -2]) && ...
                isfinite(block.end)
            count = count + 1;
        end
    end
end
end

function assert_agv_boundaries(frozen, scenario)
assert(numel(frozen.agv_boundaries) == ...
    scenario.baseline.agvData.AGVNum);
for agvId = 1:numel(frozen.agv_boundaries)
    boundary = frozen.agv_boundaries(agvId);
    assert(boundary.available_time + 1e-9 >= frozen.snapshot_time);
    assert(boundary.energy >= 0);
    assert(boundary.energy <= ...
        scenario.baseline.energyConfig.AGVEG_MAX + 1e-9);
    assert(boundary.consumed_energy >= 0);
end
end
