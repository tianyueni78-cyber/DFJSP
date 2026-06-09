clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_a_frozen_problem();
frozen = scenario.frozen_problem;

assert(frozen.is_validated);
assert(~frozen.is_search_executed);
assert(~scenario.is_rescheduled);
assert(~frozen.baseline_modified);
assert(abs(frozen.snapshot_time - scenario.fault.start_time) <= 1e-9);

operationCount = frozen.counts.frozen_operations + ...
    frozen.counts.reschedulable_operations;
assert(operationCount == sum(scenario.baseline.problem.operaNumVec));
assert(frozen.counts.frozen_operations == ...
    scenario.state.counts.completed_operations + ...
    scenario.state.counts.in_progress_operations);
assert(frozen.counts.reschedulable_operations == ...
    scenario.state.counts.unstarted_operations);
assert(frozen.counts.released_baseline_transports == ...
    scenario.state.counts.unstarted_transports);

assert_frozen_operations_match_state(frozen, scenario.state);
assert_reschedulable_operations_match_source( ...
    frozen.reschedulable_operations, scenario);
assert_job_boundaries(frozen, scenario);
assert_machine_boundaries(frozen, scenario);
assert_agv_boundaries(frozen, scenario);

fprintf('test_stage_a_frozen_problem passed\n');

function assert_frozen_operations_match_state(frozen, state)
source = [state.completed_operations, state.in_progress_operations];
assert(numel(source) == numel(frozen.frozen_operations));
for index = 1:numel(source)
    match = find([frozen.frozen_operations.job] == source(index).job & ...
        [frozen.frozen_operations.operation] == source(index).operation);
    assert(numel(match) == 1);
    assert(frozen.frozen_operations(match).machine_id == ...
        source(index).machine_id);
    assert(abs(frozen.frozen_operations(match).start - ...
        source(index).start) <= 1e-9);
    assert(abs(frozen.frozen_operations(match).end - ...
        source(index).end) <= 1e-9);
end
end

function assert_reschedulable_operations_match_source(records, scenario)
for index = 1:numel(scenario.state.unstarted_operations)
    source = scenario.state.unstarted_operations(index);
    match = find([records.job] == source.job & ...
        [records.operation] == source.operation);
    assert(numel(match) == 1);
    assert(records(match).baseline_machine_id == source.machine_id);
    expectedMachines = scenario.baseline.problem.candidateMachine{ ...
        source.job, source.operation};
    assert(isequal(records(match).candidate_machines, ...
        expectedMachines(:).'));
    expectedTimes = scenario.baseline.problem.jobInfo{source.job}( ...
        source.operation, expectedMachines);
    assert(isequal(records(match).processing_times, expectedTimes));
end
end

function assert_job_boundaries(frozen, scenario)
for jobId = 1:scenario.baseline.problem.jobNum
    boundary = frozen.job_boundaries(jobId);
    assert(boundary.job == jobId);
    assert(boundary.release_time + 1e-9 >= frozen.snapshot_time);
    frozenJob = frozen.frozen_operations( ...
        [frozen.frozen_operations.job] == jobId);
    assert(boundary.completed_prefix == numel(frozenJob));
    if isempty(frozenJob)
        assert(boundary.source_machine == -1);
    else
        [~, last] = max([frozenJob.operation]);
        assert(boundary.source_machine == frozenJob(last).machine_id);
        assert(boundary.release_time + 1e-9 >= frozenJob(last).end);
    end
end
end

function assert_machine_boundaries(frozen, scenario)
assert(numel(frozen.machine_boundaries) == ...
    scenario.baseline.problem.machineNum);
for machineId = 1:numel(frozen.machine_boundaries)
    boundary = frozen.machine_boundaries(machineId);
    assert(boundary.machine_id == machineId);
    assert(boundary.available_time + 1e-9 >= frozen.snapshot_time);
    if machineId == scenario.fault.machine_id
        assert(boundary.has_repair_constraint);
        assert(boundary.available_time + 1e-9 >= ...
            scenario.fault.repair_end_time);
    end
end
end

function assert_agv_boundaries(frozen, scenario)
assert(numel(frozen.agv_boundaries) == scenario.baseline.agvData.AGVNum);
for agvId = 1:numel(frozen.agv_boundaries)
    boundary = frozen.agv_boundaries(agvId);
    assert(boundary.agv_id == agvId);
    assert(boundary.available_time + 1e-9 >= frozen.snapshot_time);
    assert(isfinite(boundary.energy));
    assert(boundary.energy >= 0);
    assert(boundary.energy <= ...
        scenario.baseline.energyConfig.AGVEG_MAX + 1e-9);
    assert(boundary.consumed_energy >= 0);
    assert(boundary.charge_count >= 0);
    assert(boundary.charge_count == floor(boundary.charge_count));
end
end
