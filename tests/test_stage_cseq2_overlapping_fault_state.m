clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_cseq2_overlapping_fault_state();
state = scenario.next_fault_state;
nextFault = scenario.next_fault;
screening = scenario.cseq2_overlapping_fault_screening;
previousRepairStart = min([scenario.faults.start_time]);
previousRepairEnd = max([scenario.faults.repair_end_time]);

assert(scenario.is_validated);
assert(strcmp(scenario.step, 'C-SEQ2.1'));
assert(strcmp(scenario.substep, '1'));
assert(scenario.is_next_fault_processed);
assert(scenario.is_overlapping_repair_scenario);
assert(~scenario.is_impact_propagated);
assert(~scenario.is_plan_modified_in_cseq2_step_1);
assert(~scenario.is_search_executed_in_cseq2_step_1);
assert(screening.is_validated);
assert(strcmp(screening.stage, 'C-SEQ2'));
assert(screening.candidate_count > 0);
assert(~screening.additional_problem_data_generated);
assert(screening.requires_active_previous_repair);

assert(nextFault.event_id == max([scenario.faults.event_id]) + 1);
assert(nextFault.event_group == max([scenario.faults.event_group]) + 1);
assert(nextFault.start_time > previousRepairStart);
assert(nextFault.start_time < previousRepairEnd);
assert(nextFault.repair_end_time > previousRepairEnd);
assert(abs(state.state.snapshot_time - nextFault.start_time) <= 1e-9);
assert(state.active_previous_repair_count > 0);
assert(all([state.active_previous_repairs.repair_end_time] > ...
    nextFault.start_time));
assert(state.state.counts.fault_in_progress_operations == 1);
assert(state.state.fault_in_progress_operations.machine_id == ...
    nextFault.machine_id);
assert(state.history_unchanged);
assert(~state.is_impact_propagated);
assert(~state.is_plan_modified);
assert(scenario.plan_version_history.version_count == 2);

fprintf('test_stage_cseq2_overlapping_fault_state passed\n');
