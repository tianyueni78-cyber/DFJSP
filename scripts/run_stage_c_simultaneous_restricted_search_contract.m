function scenario = run_stage_c_simultaneous_restricted_search_contract( ...
        baseline)
%RUN_STAGE_C_SIMULTANEOUS_RESTRICTED_SEARCH_CONTRACT Run Stage C Step 10.3.
%   The 6-by-2 configuration validates the search contract only.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

if nargin < 1
    scenario = run_stage_c_simultaneous_frozen_problem();
else
    scenario = run_stage_c_simultaneous_frozen_problem(baseline);
end
options = struct();
options.population_size = 6;
options.generations = 2;
options.crossover_probability = 0.8;
options.mutation_probability = 0.2;
options.tournament_size = 2;

rng(scenario.baseline.seed);
scenario.restricted_search = ...
    search_stage_c_simultaneous_complete_reschedule( ...
    scenario.baseline, scenario.frozen_problem, options);
scenario.step = 10;
scenario.substep = '10.3';
scenario.is_search_executed = true;
scenario.is_full_experiment = false;
scenario.is_rescheduled = true;
scenario.is_validated = scenario.is_validated && ...
    scenario.restricted_search.is_validated;
end
