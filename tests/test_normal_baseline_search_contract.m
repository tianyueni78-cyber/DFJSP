clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));

first = run_normal_baseline_search_contract();
second = run_normal_baseline_search_contract();

assert(first.is_validated);
assert(first.is_search_executed);
assert(first.pareto_front_is_deduplicated);
assert(numel(first.population) == first.options.population_size);
assert(numel(first.history) == first.completed_generations + 1);
assert(first.selected_baseline.isFaultFreeBaseline);
assert(strcmp(first.selection_rule, ...
    'minimum_makespan_then_minimum_energy'));

firstObjectives = reshape([first.population.objectives], 2, []).';
secondObjectives = reshape([second.population.objectives], 2, []).';
assert(isequal(firstObjectives, secondObjectives));

frontObjectives = reshape([first.pareto_front.objectives], 2, []).';
assert(size(frontObjectives, 1) == ...
    size(unique(frontObjectives, 'rows'), 1));
selected = first.selected_baseline;
assert(selected.makespan == min(frontObjectives(:, 1)));

fprintf('test_normal_baseline_search_contract passed\n');
