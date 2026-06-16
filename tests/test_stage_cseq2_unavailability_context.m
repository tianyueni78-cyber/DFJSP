clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_cseq2_unavailability_context();
context = scenario.cseq2_unavailability_context;
unavailability = context.cumulative_unavailability;
relationships = context.overlap_relationships;
nextFault = scenario.next_fault;

assert(scenario.is_validated);
assert(strcmp(scenario.step, 'C-SEQ2.2'));
assert(strcmp(scenario.substep, '2'));
assert(scenario.is_cumulative_unavailability_built);
assert(~scenario.is_impact_propagated);
assert(~scenario.is_plan_modified_in_cseq2_step_2);
assert(~scenario.is_search_executed_in_cseq2_step_2);
assert(context.is_validated);
assert(strcmp(context.stage, 'C-SEQ2'));
assert(strcmp(context.step, '2'));
assert(context.active_previous_repair_count > 0);
assert(context.overlap_count > 0);
assert(numel(context.cumulative_faults) == numel(scenario.faults) + 1);
assert(unavailability.is_validated);
assert(unavailability.fault_count == numel(context.cumulative_faults));

assert(all([relationships.next_event_id] == nextFault.event_id));
assert(all([relationships.overlap_duration] > 0));
assert(all([relationships.is_active_at_next_fault]));
assert(all([context.active_previous_repairs.repair_end_time] > ...
    nextFault.start_time));

covered = [];
for index = 1:numel(unavailability.intervals)
    covered = [covered, unavailability.intervals(index).source_event_ids];
end
assert(isequal(sort(covered), sort([context.cumulative_faults.event_id])));

for machineId = 1:numel(unavailability.by_machine)
    intervals = unavailability.by_machine{machineId};
    for index = 2:numel(intervals)
        assert(intervals(index - 1).end_time < ...
            intervals(index).start_time - 1e-9);
    end
end

assert(context.history_unchanged);
assert(~context.is_impact_propagated);
assert(~context.is_plan_modified);
assert(~context.is_rescheduled);

fprintf('test_stage_cseq2_unavailability_context passed\n');
