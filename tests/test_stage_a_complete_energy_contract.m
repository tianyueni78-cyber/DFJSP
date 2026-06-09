clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_a_complete_energy_contract();
candidate = scenario.complete_energy_candidate;
baseline = scenario.baseline;
frozen = scenario.frozen_problem;

assert(candidate.is_validated);
assert(~candidate.is_search_executed);
assert(scenario.is_full_energy_evaluated);
assert(numel(candidate.job_complete_unload) == baseline.problem.jobNum);
assert(all(candidate.job_complete_unload > 0));
assert(candidate.makespan == max(candidate.job_complete_unload));
assert(candidate.makespan >= candidate.machine_makespan);

assert(isfinite(candidate.machine_energy));
assert(isfinite(candidate.agv_energy));
assert(isfinite(candidate.total_energy));
assert(candidate.machine_energy >= 0);
assert(candidate.agv_energy >= 0);
assert(abs(candidate.total_energy - ...
    candidate.machine_energy - candidate.agv_energy) <= 1e-9);

assert(numel(candidate.final_agv_energy) == baseline.agvData.AGVNum);
assert(numel(candidate.agv_charge_count) == baseline.agvData.AGVNum);
assert(all(isfinite(candidate.final_agv_energy)));
assert(all(candidate.agv_charge_count >= ...
    [frozen.agv_boundaries.charge_count]));

assert_final_unloads(candidate, baseline.problem.operaNumVec);
assert_agv_activity_energy(candidate.agv_activity_records);
assert_boundary_energy_matches_source(frozen, baseline);

fprintf('test_stage_a_complete_energy_contract passed\n');

function assert_final_unloads(candidate, operaNumVec)
activities = candidate.transport_records;
for jobId = 1:numel(operaNumVec)
    match = find([activities.job] == jobId & ...
        [activities.operation] == -1 & ...
        [activities.load_status] == -2);
    if isempty(match)
        continue
    end
    assert(numel(match) == 1);
    unload = activities(match);
    assert(unload.to_machine == -2);
    assert(abs(unload.end - ...
        candidate.job_complete_unload(jobId)) <= 1e-9);
    jobOperations = candidate.operation_records( ...
        [candidate.operation_records.job] == jobId);
    [~, last] = max([jobOperations.operation]);
    assert(unload.start + 1e-9 >= jobOperations(last).end);
end
end

function assert_agv_activity_energy(activities)
for index = 1:numel(activities)
    assert(isfinite(activities(index).energy_use));
    assert(activities(index).energy_use >= 0);
    if activities(index).charge == 1
        assert(strcmp(activities(index).activity_type, 'charging'));
        assert(activities(index).energy_use == 0);
    end
end
end

function assert_boundary_energy_matches_source(frozen, baseline)
for agvId = 1:numel(frozen.agv_boundaries)
    boundary = frozen.agv_boundaries(agvId);
    records = baseline.agvEGRecord{agvId};
    eligible = find(records(:, 1) <= ...
        boundary.available_time + 1e-9);
    if isempty(eligible)
        expected = baseline.energyConfig.AGVEG_MAX;
    else
        expected = records(eligible(end), 2);
    end
    assert(abs(boundary.energy - expected) <= 1e-9);
end
end
