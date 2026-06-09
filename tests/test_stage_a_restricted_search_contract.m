clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));

first = run_stage_a_restricted_search_contract();
second = run_stage_a_restricted_search_contract();
result = first.restricted_search;

assert(result.is_validated);
assert(result.is_search_executed);
assert(~result.is_full_experiment);
assert(result.is_energy_evaluated);
assert(result.is_final_unload_evaluated);
assert(numel(result.population) == result.options.population_size);
assert(numel(result.history) == result.options.generations + 1);
assert(~isempty(result.pareto_front));
assert(all([result.population.is_validated]));
assert(all([result.pareto_front.rank] == 1));
assert(isequal(result.objective_names, { ...
    'final_unload_makespan', 'total_energy'}));

firstObjectives = reshape( ...
    [first.restricted_search.population.objectives], 2, []).';
secondObjectives = reshape( ...
    [second.restricted_search.population.objectives], 2, []).';
assert(isequal(firstObjectives, secondObjectives), ...
    'Lightweight search must be reproducible under the baseline seed.');

for index = 1:numel(result.population)
    evaluation = result.population(index);
    assert(numel(evaluation.objectives) == 2);
    assert(all(isfinite(evaluation.objectives)));
    assert(evaluation.objectives(1) >= ...
        first.frozen_problem.snapshot_time);
    assert(evaluation.objectives(2) >= 0);
    assert(evaluation.candidate.makespan == evaluation.objectives(1));
    assert(evaluation.candidate.total_energy == evaluation.objectives(2));
end

fprintf('test_stage_a_restricted_search_contract passed\n');
