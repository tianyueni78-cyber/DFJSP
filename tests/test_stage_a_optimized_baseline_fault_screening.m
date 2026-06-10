clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));

contractScenario = struct();
contractScenario.optimized_baseline = run_normal_schedule_baseline();
contractScenario.normal_search = struct('is_validated', true);
contractScenario.is_source_data_only = true;
contractScenario.is_fault_free = true;

contractResult = run_stage_a_optimized_baseline_fault_screening( ...
    contractScenario);

assert(contractResult.is_validated);
assert(contractResult.step == 11);
assert(strcmp(contractResult.baseline_source, ...
    'stage_a_step_10_optimized_normal_baseline'));
assert(contractResult.selected_impact.counts.directly_affected > 0);
assert(contractResult.screening.candidate_count > 0);
assert(~contractResult.config_modified);
assert(~contractResult.additional_problem_data_generated);

if contractResult.configured_trigger_is_effective
    assert(strcmp(contractResult.selection_reason, ...
        'configured_trigger_remains_effective'));
    assert(contractResult.selected_candidate.trigger_job == ...
        contractResult.original_fault_config.trigger_job);
    assert(contractResult.selected_candidate.trigger_operation == ...
        contractResult.original_fault_config.trigger_operation);
else
    assert(strcmp(contractResult.selection_reason, ...
        'configured_trigger_ineffective_use_rank_1'));
    assert(contractResult.selected_candidate_rank == 1);
end

fprintf(['test_stage_a_optimized_baseline_fault_screening ', ...
    'passed\n']);

clear contractScenario contractResult
