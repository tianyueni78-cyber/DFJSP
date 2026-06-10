clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_b_frozen_problem();
frozen = scenario.frozen_problem;
tolerance = 1e-9;

assert(scenario.is_validated);
assert(scenario.step == 7);
assert(scenario.is_frozen_problem_built);
assert(~scenario.is_search_executed);
assert(frozen.is_validated);
assert(~frozen.baseline_modified);
assert(~frozen.is_search_executed);
assert(~frozen.stage_a_decoder_compatible);
assert(strcmp(frozen.decoder_requirement, ...
    'stage_b_split_operation_decoder'));

operationCount = frozen.counts.frozen_operations + ...
    frozen.counts.reschedulable_operations;
assert(operationCount == sum(scenario.baseline.problem.operaNumVec));
assert(frozen.counts.reschedulable_operations == ...
    scenario.state.counts.unstarted_operations);
assert(frozen.counts.frozen_operations == ...
    scenario.state.counts.completed_operations + ...
    scenario.state.counts.in_progress_operations);

interrupted = frozen.frozen_operations( ...
    [frozen.frozen_operations.is_interrupted]);
assert(numel(interrupted) == 1);
assert(interrupted.machine_id == scenario.resume_plan.machine_id);
assert(interrupted.job == scenario.resume_plan.job);
assert(interrupted.operation == scenario.resume_plan.operation);
assert(strcmp(interrupted.status, 'interrupted_committed'));
assert(abs(interrupted.end - ...
    scenario.resume_plan.revised_completion_time) <= tolerance);
assert(abs(interrupted.processing_duration - ...
    scenario.resume_plan.original_duration) <= tolerance);
assert(interrupted.calendar_span > interrupted.processing_duration);

commitment = frozen.interrupted_commitment;
assert(commitment.progress_preserved);
assert(~commitment.restart_from_zero);
assert(~commitment.machine_migration_allowed);
assert(abs(commitment.completed_segment.end - ...
    scenario.fault.start_time) <= tolerance);
assert(abs(commitment.resumed_segment.start - ...
    scenario.fault.repair_end_time) <= tolerance);

jobBoundary = frozen.job_boundaries(commitment.job);
assert(jobBoundary.contains_interrupted_commitment);
assert(jobBoundary.completed_prefix == commitment.operation);
assert(abs(jobBoundary.release_time - ...
    commitment.revised_completion_time) <= tolerance);
assert(jobBoundary.source_machine == commitment.machine_id);

machineBoundary = frozen.machine_boundaries(commitment.machine_id);
assert(machineBoundary.has_repair_constraint);
assert(machineBoundary.has_interrupted_commitment);
assert(machineBoundary.available_time + tolerance >= ...
    commitment.revised_completion_time);

assert_transport_partition(frozen, scenario.baseline.AGVTable);
assert_agv_boundaries(frozen, scenario);

fprintf('test_stage_b_frozen_problem passed\n');

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
