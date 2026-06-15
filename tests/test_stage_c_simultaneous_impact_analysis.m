clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'impact'));

scenario = run_stage_c_simultaneous_impact_analysis();
impact = scenario.impact;

assert(scenario.is_validated);
assert(scenario.step == 5);
assert(scenario.impact_propagated);
assert(scenario.successor_propagation_executed);
assert(~scenario.is_rescheduled);
assert(scenario.source_machine_table_unchanged);
assert(scenario.source_agv_table_unchanged);
assert(impact.is_validated);
assert(~impact.baseline_modified);
assert(~impact.is_rescheduled);
assert(impact.counts.root_count == 2);
assert(numel(impact.root_impacts) == 2);
assert(all([impact.root_impacts.is_validated]));
assert(all([impact.root_impacts.completion_delay] > 0));
assert(impact.counts.affected_total + ...
    impact.counts.unaffected_unstarted == ...
    numel(scenario.state.unstarted_operations));

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
    assert(all(ismember(operation.source_event_ids, ...
        [scenario.faults.event_id])));
    expectedSources = [];
    for rootIndex = 1:numel(impact.root_impacts)
        root = impact.root_impacts(rootIndex);
        records = root.affected_operations;
        if any([records.job] == operation.job & ...
                [records.operation] == operation.operation)
            expectedSources(end + 1) = root.event_id; %#ok<SAGROW>
        end
    end
    assert(isequal(operation.source_event_ids, ...
        unique(expectedSources)));
end
assert(impact.counts.multi_source_operations == ...
    sum([impact.affected_operations.source_count] > 1));

reversedImpact = identify_stage_c_simultaneous_affected_operations( ...
    scenario.baseline, scenario.state, scenario.faults(end:-1:1));
assert(isequaln(impact.affected_operations, ...
    reversedImpact.affected_operations));
assert(isequal(impact.counts.per_root_affected, ...
    reversedImpact.counts.per_root_affected(end:-1:1)));

fprintf('test_stage_c_simultaneous_impact_analysis passed\n');
