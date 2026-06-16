clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_c_sequential_frozen_problem();
frozen = scenario.sequential_frozen_problem;
state = scenario.next_fault_state.state;
tolerance = 1e-9;

assert(scenario.is_validated);
assert(scenario.step == 16);
assert(strcmp(scenario.substep, '16.1'));
assert(scenario.is_frozen_problem_built);
assert(~scenario.is_complete_reschedule_decoded);
assert(~scenario.is_search_executed_in_step_16);
assert(~scenario.is_combination_evaluated);
assert(frozen.is_validated);
assert(~frozen.baseline_modified);
assert(~frozen.is_search_executed);
assert(~frozen.stage_a_decoder_compatible);

assert(frozen.counts.frozen_operations + ...
    frozen.counts.reschedulable_operations == ...
    sum(scenario.baseline.problem.operaNumVec));
assert(frozen.counts.reschedulable_operations == ...
    state.counts.unstarted_operations);
assert(frozen.counts.frozen_operations == ...
    state.counts.completed_operations + ...
    state.counts.normal_in_progress_operations + ...
    state.counts.fault_in_progress_operations);
assert(numel(frozen.repair_intervals) == 1);
assert(numel(frozen.interrupted_commitments) == 1);

commitment = frozen.interrupted_commitments;
assert(commitment.progress_preserved);
assert(~commitment.restart_from_zero);
assert(~commitment.machine_migration_allowed);
interrupted = frozen.frozen_operations( ...
    [frozen.frozen_operations.is_interrupted]);
assert(numel(interrupted) == 1);
assert(interrupted.job == commitment.job);
assert(interrupted.operation == commitment.operation);
assert(abs(interrupted.end - ...
    commitment.revised_completion_time) <= tolerance);

jobBoundary = frozen.job_boundaries(commitment.job);
assert(jobBoundary.contains_interrupted_commitment);
assert(jobBoundary.completed_prefix == commitment.operation);
assert(jobBoundary.release_time + tolerance >= ...
    commitment.revised_completion_time);
machineBoundary = frozen.machine_boundaries(commitment.machine_id);
assert(machineBoundary.has_repair_constraint);
assert(machineBoundary.has_interrupted_commitment);
assert(machineBoundary.available_time + tolerance >= ...
    commitment.revised_completion_time);

assert_transport_partition(frozen, ...
    scenario.next_fault_state.current_plan_view.AGVTable);
for agvId = 1:numel(frozen.agv_boundaries)
    boundary = frozen.agv_boundaries(agvId);
    assert(boundary.available_time + tolerance >= ...
        frozen.snapshot_time);
    assert(boundary.energy >= 0);
    assert(boundary.consumed_energy >= 0);
end

fprintf('test_stage_c_sequential_frozen_problem passed\n');

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
