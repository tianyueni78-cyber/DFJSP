function scenario = run_stage_cs2_restricted_search_contract( ...
        baseline)
%run_stage_cs2_restricted_search_contract Run C-S2 Step 9.
%   The 6-by-2 configuration validates the search contract only.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

if nargin < 1
    scenario = run_stage_cs2_frozen_problem();
else
    scenario = run_stage_cs2_frozen_problem(baseline);
end
options = struct();
options.population_size = 6;
options.generations = 2;
options.crossover_probability = 0.8;
options.mutation_probability = 0.2;
options.tournament_size = 2;

rng(scenario.baseline.seed);
scenario.restricted_search = ...
    search_stage_cs2_complete_reschedule( ...
    scenario.baseline, scenario.cs2_frozen_problem, options);
scenario.step = 'C-S2.9';
scenario.substep = '9';
scenario.is_search_executed = true;
scenario.is_full_experiment = false;
scenario.is_rescheduled = true;
scenario.is_validated = scenario.is_validated && ...
    scenario.restricted_search.is_validated;
end
