clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'configs'));

normal = normal_baseline_search_config(projectRoot);
fault = stage_a_confirmation_search_config(projectRoot);
fields = {'population_size', 'generations', ...
    'crossover_probability', 'mutation_probability', ...
    'tournament_size', 'no_improvement_generations', ...
    'max_runtime_seconds', 'improvement_tolerance', 'seed'};
for index = 1:numel(fields)
    assert(isequal(normal.(fields{index}), fault.(fields{index})));
end
assert(strcmp(normal.baseline_selection_rule, ...
    'minimum_makespan_then_minimum_energy'));
assert(contains(normal.output_root, ...
    fullfile('outputs', 'normal_baseline_search')));

fprintf('test_normal_baseline_search_config passed\n');
