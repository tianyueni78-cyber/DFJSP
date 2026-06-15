clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));

scenario = run_stage_br_impact_analysis();
resumeScenario = run_stage_b_impact_analysis(scenario.baseline);
impact = scenario.impact;
machineTableBefore = scenario.baseline.machineTable;

assert(scenario.is_validated);
assert(strcmp(scenario.stage, 'B-R'));
assert(scenario.step == 2);
assert(scenario.is_impact_identified);
assert(scenario.successor_propagation_executed);
assert(~scenario.is_rescheduled);
assert(impact.is_validated);
assert(strcmp(impact.stage, 'B-R'));
assert(impact.step == 2);
assert(strcmp(impact.rule, 'restart_on_original_machine'));
assert(~impact.baseline_modified);
assert(~impact.is_rescheduled);
assert(isequaln(machineTableBefore, scenario.baseline.machineTable));
assert(impact.root_operation.restart_from_zero);
assert(~impact.root_operation.progress_preserved);
assert(abs(impact.root_operation.lost_processing_time - ...
    scenario.restart_plan.lost_processing_time) <= 1e-9);
assert(abs(impact.root_operation.revised_end - ...
    scenario.restart_plan.revised_completion_time) <= 1e-9);
assert(abs(impact.root_operation.completion_delay - ...
    scenario.restart_plan.completion_delay) <= 1e-9);
assert(impact.root_operation.completion_delay > ...
    resumeScenario.impact.root_operation.completion_delay);
assert(impact.counts.affected_total >= ...
    resumeScenario.impact.counts.affected_total);
assert(impact.counts.affected_total > 0);
assert(impact.counts.affected_total + ...
    impact.counts.unaffected_unstarted == ...
    numel(scenario.state.unstarted_operations));

for index = 1:numel(impact.affected_operations)
    operation = impact.affected_operations(index);
    assert(operation.projected_delay > 0);
    assert(operation.projected_start >= operation.original_start);
    assert(operation.projected_end >= operation.original_end);
end

fprintf('test_stage_br_impact_analysis passed\n');
