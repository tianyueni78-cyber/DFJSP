clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_br_restart_rule();
fault = scenario.fault;
plan = scenario.restart_plan;
source = scenario.state.interrupted_operation;

assert(scenario.is_validated);
assert(strcmp(scenario.stage, 'B-R'));
assert(scenario.step == 1);
assert(scenario.interruption_rule_resolved);
assert(~scenario.is_rescheduled);
assert(strcmp(fault.interruption_rule, 'unresolved'));
assert(strcmp(scenario.resolved_interruption_rule, ...
    'restart_on_original_machine'));
assert(strcmp(plan.rule, 'restart_on_original_machine'));
assert(~plan.progress_preserved);
assert(plan.restart_from_zero);
assert(~plan.machine_migration_allowed);
assert(plan.machine_id == fault.machine_id);
assert(plan.original_table_index == source.table_index);
assert(~plan.lost_processing_segment.contributes_to_completion);
assert(plan.restart_segment.contributes_to_completion);
assert(abs(plan.lost_processing_segment.end - ...
    fault.start_time) <= 1e-9);
assert(abs(plan.restart_segment.start - ...
    fault.repair_end_time) <= 1e-9);
assert(abs(plan.lost_processing_time - ...
    source.elapsed_processing_time) <= 1e-9);
assert(abs(plan.restart_segment.processing_time - ...
    source.original_duration) <= 1e-9);
assert(abs(plan.effective_completion_processing_time - ...
    source.original_duration) <= 1e-9);
assert(abs(plan.total_machine_processing_time - ...
    source.elapsed_processing_time - ...
    source.original_duration) <= 1e-9);
assert(plan.completion_delay > fault.repair_end_time - ...
    fault.start_time);
assert(~plan.successor_propagation_executed);

fprintf('test_stage_br_restart_rule passed\n');
