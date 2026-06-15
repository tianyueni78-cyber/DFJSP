clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_c_sequential_impact_context();
context = scenario.sequential_impact_context;
state = scenario.next_fault_state.state;

assert(scenario.is_validated);
assert(scenario.step == 14);
assert(scenario.is_impact_propagated);
assert(scenario.is_cumulative_unavailability_built);
assert(~scenario.is_plan_modified_in_step_14);
assert(~scenario.is_rescheduled_in_step_14);
assert(context.is_validated);
assert(context.history_unchanged);
assert(~context.is_plan_modified);
assert(~context.is_rescheduled);

assert(context.counts.cumulative_faults == ...
    numel(scenario.faults) + 1);
assert(context.cumulative_unavailability.fault_count == ...
    context.counts.cumulative_faults);
covered = [];
for index = 1:numel(context.cumulative_unavailability.intervals)
    covered = [covered, ...
        context.cumulative_unavailability.intervals(index). ...
        source_event_ids]; %#ok<AGROW>
end
assert(isequal(sort(covered), ...
    sort([context.cumulative_faults.event_id])));

assert(context.counts.active_historical_affected == 0);
assert(context.counts.new_event_affected > 0);
assert(context.counts.merged_affected == ...
    context.counts.new_event_affected);
assert(context.counts.merged_affected + ...
    context.counts.unaffected_unstarted == ...
    numel(state.unstarted_operations));

keys = [[context.merged_affected_operations.job].', ...
    [context.merged_affected_operations.operation].'];
assert(size(unique(keys, 'rows'), 1) == size(keys, 1));
for index = 1:numel(context.merged_affected_operations)
    operation = context.merged_affected_operations(index);
    assert(operation.projected_delay > 0);
    assert(operation.source_count == ...
        numel(operation.source_event_ids));
    assert(all(ismember(operation.source_event_ids, ...
        [context.cumulative_faults.event_id])));
end
assert(all(ismember( ...
    [context.new_event_impact.affected_operations.source_event_ids], ...
    scenario.next_fault.event_id)));
assert(scenario.plan_version_history.version_count == 2);

fprintf('test_stage_c_sequential_impact_context passed\n');
