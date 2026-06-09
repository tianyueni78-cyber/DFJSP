clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

first = run_stage_a_restricted_search_contract();
second = run_stage_a_restricted_search_contract();
result = first.restricted_search;

assert(result.is_validated);
assert(result.is_search_executed);
assert(~result.is_full_experiment);
assert(result.is_energy_evaluated);
assert(result.is_final_unload_evaluated);
assert(numel(result.population) == result.options.population_size);
assert(numel(result.history) == result.completed_generations + 1);
assert(result.completed_generations <= result.options.generations);
assert(result.pareto_front_is_deduplicated);
assert(~isempty(result.pareto_front));
assert(all([result.population.is_validated]));
assert(all([result.pareto_front.rank] == 1));
assert(isequal(result.objective_names, { ...
    'final_unload_makespan', 'total_energy'}));
frontObjectives = reshape([result.pareto_front.objectives], 2, []).';
assert(size(frontObjectives, 1) == ...
    size(unique(frontObjectives, 'rows'), 1));

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

adaptiveOptions = struct();
adaptiveOptions.population_size = 6;
adaptiveOptions.generations = 10;
adaptiveOptions.crossover_probability = 0;
adaptiveOptions.mutation_probability = 0;
adaptiveOptions.tournament_size = 2;
adaptiveOptions.no_improvement_generations = 1;
adaptiveOptions.max_runtime_seconds = Inf;
adaptiveOptions.improvement_tolerance = 1e-9;
rng(first.baseline.seed);
adaptive = search_stage_a_complete_reschedule( ...
    first.baseline, first.frozen_problem, adaptiveOptions);
assert(strcmp(adaptive.stop_reason, 'no_pareto_improvement'));
assert(adaptive.completed_generations == 1);
assert(numel(adaptive.history) == 2);

timeOptions = adaptiveOptions;
timeOptions.no_improvement_generations = Inf;
timeOptions.max_runtime_seconds = eps;
rng(first.baseline.seed);
timeLimited = search_stage_a_complete_reschedule( ...
    first.baseline, first.frozen_problem, timeOptions);
assert(strcmp(timeLimited.stop_reason, 'time_limit'));
assert(timeLimited.completed_generations == 1);
assert(numel(timeLimited.history) == 2);

fprintf('test_stage_a_restricted_search_contract passed\n');
