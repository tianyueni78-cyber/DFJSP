clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));

normalScenario = struct();
normalScenario.optimized_baseline = run_normal_schedule_baseline();
normalScenario.normal_search = struct('is_validated', true);
normalScenario.is_source_data_only = true;
normalScenario.is_fault_free = true;

result = run_stage_a_optimized_baseline_fault_screening(normalScenario);

assert(result.is_validated);
assert(result.step == 11);
assert(strcmp(result.baseline_source, ...
    'stage_a_step_10_optimized_normal_baseline'));
assert(result.selected_impact.counts.directly_affected > 0);
assert(result.screening.candidate_count > 0);
assert(~result.config_modified);
assert(~result.additional_problem_data_generated);

if result.configured_trigger_is_effective
    assert(strcmp(result.selection_reason, ...
        'configured_trigger_remains_effective'));
    assert(result.selected_candidate.trigger_job == ...
        result.original_fault_config.trigger_job);
    assert(result.selected_candidate.trigger_operation == ...
        result.original_fault_config.trigger_operation);
else
    assert(strcmp(result.selection_reason, ...
        'configured_trigger_ineffective_use_rank_1'));
    assert(result.selected_candidate_rank == 1);
end

fprintf(['test_stage_a_optimized_baseline_fault_screening ', ...
    'passed\n']);
