clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'configs'));

config = stage_a_confirmation_search_config(projectRoot);

assert(config.population_size == 10);
assert(config.generations == 20);
assert(config.crossover_probability == 0.8);
assert(config.mutation_probability == 0.2);
assert(config.tournament_size == 2);
assert(config.seed == 42);
assert(strcmp(config.output_root, fullfile(projectRoot, ...
    'outputs', 'stage_a_complete_reschedule_confirmation')));

fprintf('test_stage_a_confirmation_search_config passed\n');
