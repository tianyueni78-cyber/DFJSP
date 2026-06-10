clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'configs'));

contractResult = run_stage_a_step_13_contract();
search = contractResult.complete_reschedule_search;
selection = contractResult.combined_selection;

assert(contractResult.is_validated);
assert(contractResult.step == 13);
assert(contractResult.is_search_executed);
assert(contractResult.is_combination_evaluated);
assert(contractResult.is_contract_run);
assert(~contractResult.is_formal_run);
assert(search.is_validated);
assert(search.pareto_front_is_deduplicated);
assert(numel(search.population) == 6);
assert(search.completed_generations == 2);
assert(selection.is_validated);
assert(numel(selection.evaluations) == ...
    1 + numel(search.pareto_front));
assert(selection.right_shift_metrics.SD == 0);
assert(selection.selected_metrics.Y <= ...
    min([selection.evaluations.Y]) + 1e-9);
assert(~isfield(contractResult, 'output_directory'));

stage13Config = stage_a_step_13_config(projectRoot);
normalConfig = normal_baseline_search_config(projectRoot);
budgetFields = {'population_size', 'generations', ...
    'crossover_probability', 'mutation_probability', ...
    'tournament_size', 'no_improvement_generations', ...
    'max_runtime_seconds', 'improvement_tolerance', 'seed'};
for index = 1:numel(budgetFields)
    field = budgetFields{index};
    assert(isequal(stage13Config.(field), normalConfig.(field)));
end

fprintf('test_stage_a_step_13_contract passed\n');

clear contractResult search selection stage13Config normalConfig
