function config = stage_a_confirmation_search_config(projectRoot)
%STAGE_A_CONFIRMATION_SEARCH_CONFIG Configure the 10-by-20 confirmation run.

if nargin < 1
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end

config = struct();
config.population_size = 10;
config.generations = 20;
config.crossover_probability = 0.8;
config.mutation_probability = 0.2;
config.tournament_size = 2;
config.no_improvement_generations = 10;
config.max_runtime_seconds = 30;
config.improvement_tolerance = 1e-9;
config.seed = 42;
config.output_root = fullfile(projectRoot, 'outputs', ...
    'stage_a_complete_reschedule_confirmation');
end
