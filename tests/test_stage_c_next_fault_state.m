clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'state'));

scenario = run_stage_c_next_fault_state();
result = scenario.next_fault_state;
state = result.state;
nextFault = scenario.next_fault;

assert(scenario.is_validated);
assert(scenario.step == 13);
assert(scenario.is_next_fault_processed);
assert(~scenario.is_impact_propagated);
assert(~scenario.is_plan_modified_in_step_13);
assert(~scenario.is_search_executed_in_step_13);
assert(result.is_validated);
assert(result.input_version_id == 1);
assert(result.current_plan_view.isCurrentPlanView);
assert(~result.current_plan_view.isFaultFreeBaseline);
assert(result.history_unchanged);
assert(~result.is_impact_propagated);
assert(~result.is_plan_modified);

assert(nextFault.event_id == max([scenario.faults.event_id]) + 1);
assert(nextFault.event_group == max([scenario.faults.event_group]) + 1);
assert(nextFault.start_time > max([scenario.faults.repair_end_time]));
assert(abs(state.snapshot_time - nextFault.start_time) <= 1e-9);
assert(state.counts.fault_in_progress_operations == 1);
assert(state.fault_in_progress_operations.machine_id == ...
    nextFault.machine_id);
assert(state.fault_in_progress_operations.elapsed_processing_time > 0);
assert(state.fault_in_progress_operations.remaining_processing_time > 0);

operationCount = state.counts.completed_operations + ...
    state.counts.normal_in_progress_operations + ...
    state.counts.fault_in_progress_operations + ...
    state.counts.unstarted_operations;
assert(operationCount == sum(scenario.baseline.problem.operaNumVec));
assert(result.active_previous_repair_count == 0);
assert(isequaln(scenario.plan_version_history.versions(1).plan, ...
    scenario.baseline));
assert(scenario.plan_version_history.version_count == 2);

fprintf('test_stage_c_next_fault_state passed\n');
