function config = stage_cs2_complete_search_config(projectRoot)
%STAGE_CS2_COMPLETE_SEARCH_CONFIG Configure the C-S2 formal run.

if nargin < 1
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end

config = struct();
config.population_size = 10;
config.generations = 100;
config.crossover_probability = 0.8;
config.mutation_probability = 0.2;
config.tournament_size = 2;
config.no_improvement_generations = 10;
config.max_runtime_seconds = 30;
config.improvement_tolerance = 1e-9;
config.seed = 42;
config.run_type = 'single_seed_formal_search';
config.output_root = fullfile(projectRoot, 'outputs', ...
    'stage_cs2_complete_reschedule_search');
end
