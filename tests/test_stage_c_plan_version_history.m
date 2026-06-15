clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'state'));

scenario = run_stage_c_plan_version_history();
history = scenario.plan_version_history;
faultTime = scenario.faults(1).start_time;

assert(scenario.is_validated);
assert(scenario.step == 12);
assert(scenario.is_event_replay_initialized);
assert(~scenario.is_next_fault_processed);
assert(~scenario.is_search_executed_in_step_12);
assert(history.is_validated);
assert(history.history_is_immutable);
assert(history.version_count == 2);
assert(history.event_group_count == 1);
assert(history.current_version_id == 1);

baselineVersion = history.versions(1);
eventVersion = history.versions(2);
assert(baselineVersion.version_id == 0);
assert(baselineVersion.predecessor_version_id == -1);
assert(baselineVersion.effective_time == 0);
assert(baselineVersion.is_baseline);
assert(eventVersion.version_id == 1);
assert(eventVersion.predecessor_version_id == 0);
assert(abs(eventVersion.effective_time - faultTime) <= 1e-9);
assert(isequal(eventVersion.source_event_ids, ...
    [scenario.faults.event_id]));
assert(strcmp(eventVersion.strategy, ...
    scenario.combined_selection.selected_strategy));
assert(isequaln(eventVersion.plan, ...
    scenario.combined_selection.selected_candidate));

assert(faultTime > 0);
before = resolve_stage_c_active_plan(history, faultTime / 2);
atEvent = resolve_stage_c_active_plan(history, faultTime);
after = resolve_stage_c_active_plan(history, faultTime + 1);
assert(before.version_id == 0);
assert(atEvent.version_id == 1);
assert(after.version_id == 1);
assert(isequaln(history.versions(1).plan, scenario.baseline));

record = history.event_records(1);
assert(record.input_version_id == 0);
assert(record.output_version_id == 1);
assert(abs(record.event_time - faultTime) <= 1e-9);
assert(isequal(record.event_ids, [scenario.faults.event_id]));

fprintf('test_stage_c_plan_version_history passed\n');
