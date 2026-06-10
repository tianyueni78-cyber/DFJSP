function result = run_normal_baseline_search_contract()
%RUN_NORMAL_BASELINE_SEARCH_CONTRACT Run a tiny source-data search.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));
addpath(fullfile(projectRoot, 'src', 'search'));

sourceBaseline = run_normal_schedule_baseline();
options = struct();
options.population_size = 6;
options.generations = 2;
options.crossover_probability = 0.8;
options.mutation_probability = 0.2;
options.tournament_size = 2;

rng(sourceBaseline.seed);
result = search_normal_schedule(sourceBaseline, options);
end
