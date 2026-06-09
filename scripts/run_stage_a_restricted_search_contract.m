function scenario = run_stage_a_restricted_search_contract()
%RUN_STAGE_A_RESTRICTED_SEARCH_CONTRACT Run a tiny deterministic search.
%   This is a contract test configuration, not a full experiment.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

scenario = run_stage_a_frozen_problem();
options = struct();
options.population_size = 6;
options.generations = 2;
options.crossover_probability = 0.8;
options.mutation_probability = 0.2;
options.tournament_size = 2;

rng(scenario.baseline.seed);
scenario.restricted_search = search_stage_a_complete_reschedule( ...
    scenario.baseline, scenario.frozen_problem, options);
scenario.is_search_executed = true;
scenario.is_full_experiment = false;
scenario.is_rescheduled = true;
end
