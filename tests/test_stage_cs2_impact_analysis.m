clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'impact'));

scenario = run_stage_cs2_impact_analysis();
impact = scenario.cs2_impact;

assert(scenario.is_validated);
assert(strcmp(scenario.extension, 'C-S2'));
assert(strcmp(scenario.step, 'C-S2.2'));
assert(scenario.impact_propagated);
assert(scenario.successor_propagation_executed);
assert(~scenario.is_rescheduled);
assert(scenario.source_machine_table_unchanged);
assert(scenario.source_agv_table_unchanged);
assert(impact.is_validated);
assert(strcmp(impact.stage, 'C-S2'));
assert(impact.step == 2);
assert(strcmp(impact.rule, 'restart_from_zero'));
assert(~impact.baseline_modified);
assert(~impact.is_rescheduled);
assert(impact.counts.root_count == ...
    numel(scenario.cs2_restart_commitments));
assert(numel(impact.root_impacts) == ...
    numel(scenario.cs2_restart_commitments));
assert(all([impact.root_impacts.is_validated]));
assert(all([impact.root_impacts.completion_delay] > 0));
assert(impact.counts.affected_total + ...
    impact.counts.unaffected_unstarted == ...
    numel(scenario.state.unstarted_operations));

for index = 1:numel(impact.root_impacts)
    root = impact.root_impacts(index);
    commitment = scenario.cs2_restart_commitments(index);
    assert(abs(root.revised_end - ...
        commitment.revised_completion_time) <= 1e-9);
    assert(abs(root.lost_processing_time - ...
        commitment.lost_processing_time) <= 1e-9);
    assert(abs(root.restart_processing_time - ...
        commitment.effective_completion_processing_time) <= 1e-9);
end

keys = [[impact.affected_operations.job].', ...
    [impact.affected_operations.operation].'];
assert(size(unique(keys, 'rows'), 1) == size(keys, 1));
for index = 1:numel(impact.affected_operations)
    operation = impact.affected_operations(index);
    assert(operation.projected_delay > 0);
    assert(operation.projected_start >= operation.original_start);
    assert(operation.projected_end >= operation.original_end);
    assert(operation.source_count == ...
        numel(operation.source_event_ids));
    expectedSources = [];
    for rootIndex = 1:numel(impact.root_impacts)
        root = impact.root_impacts(rootIndex);
        records = root.affected_operations;
        if any([records.job] == operation.job & ...
                [records.operation] == operation.operation)
            expectedSources = unique([expectedSources, ...
                root.event_ids]); %#ok<AGROW>
        end
    end
    assert(isequal(operation.source_event_ids, expectedSources));
end

reversed = identify_stage_cs2_restart_affected_operations( ...
    scenario.baseline, scenario.state, ...
    scenario.cs2_restart_commitments(end:-1:1));
assert(isequaln(impact.affected_operations, ...
    reversed.affected_operations));
assert(isequal(impact.counts.per_root_affected, ...
    reversed.counts.per_root_affected(end:-1:1)));

fprintf('test_stage_cs2_impact_analysis passed\n');
