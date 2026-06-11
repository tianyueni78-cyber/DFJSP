clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'scripts'));

config = stage_b_complete_search_config(projectRoot);

assert(config.population_size == 10);
assert(config.generations == 100);
assert(config.crossover_probability == 0.8);
assert(config.mutation_probability == 0.2);
assert(config.tournament_size == 2);
assert(config.no_improvement_generations == 10);
assert(config.max_runtime_seconds == 30);
assert(config.improvement_tolerance == 1e-9);
assert(config.seed == 42);
assert(strcmp(config.run_type, 'single_seed_formal_search'));
assert(strcmp(config.output_root, fullfile(projectRoot, ...
    'outputs', 'stage_b_complete_reschedule_search')));
assert(exist('run_stage_b_complete_search', 'file') == 2);
assert(~exist(config.output_root, 'dir') || ...
    isfolder(config.output_root));

fprintf('test_stage_b_complete_search_config passed\n');
