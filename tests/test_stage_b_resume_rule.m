clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_b_resume_rule();
fault = scenario.fault;
plan = scenario.resume_plan;
source = scenario.state.interrupted_operation;

assert(scenario.is_validated);
assert(scenario.step == 2);
assert(scenario.interruption_rule_resolved);
assert(~scenario.is_rescheduled);
assert(strcmp(fault.interruption_rule, 'unresolved'));
assert(strcmp(scenario.resolved_interruption_rule, ...
    'resume_on_original_machine'));
assert(strcmp(plan.rule, 'resume_on_original_machine'));
assert(plan.progress_preserved);
assert(~plan.restart_from_zero);
assert(~plan.machine_migration_allowed);
assert(plan.machine_id == fault.machine_id);
assert(plan.original_table_index == source.table_index);
assert(plan.completed_segment.machine_id == fault.machine_id);
assert(plan.resumed_segment.machine_id == fault.machine_id);
assert(abs(plan.completed_segment.end - fault.start_time) <= 1e-9);
assert(abs(plan.resumed_segment.start - ...
    fault.repair_end_time) <= 1e-9);
assert(abs(plan.completed_segment.processing_time - ...
    source.elapsed_processing_time) <= 1e-9);
assert(abs(plan.resumed_segment.processing_time - ...
    source.remaining_processing_time) <= 1e-9);
assert(abs(plan.total_processing_time - ...
    source.original_duration) <= 1e-9);
assert(abs(plan.completion_delay - ...
    fault.repair_duration) <= 1e-9);
assert(~plan.successor_propagation_executed);

fprintf('test_stage_b_resume_rule passed\n');
