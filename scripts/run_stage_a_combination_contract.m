function scenario = run_stage_a_combination_contract()
%RUN_STAGE_A_COMBINATION_CONTRACT Build and compare both Stage A strategies.
%   This uses the lightweight 6-by-2 search, not the adaptive experiment.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

scenario = run_stage_a_agv_linked_right_shift();
frozen = build_stage_a_frozen_problem( ...
    scenario.baseline, scenario.fault, scenario.state);

options = struct();
options.population_size = 6;
options.generations = 2;
options.crossover_probability = 0.8;
options.mutation_probability = 0.2;
options.tournament_size = 2;

rng(scenario.baseline.seed);
scenario.complete_reschedule_search = ...
    search_stage_a_complete_reschedule( ...
    scenario.baseline, frozen, options);
scenario.combination_config = stage_a_combination_config();
scenario.combined_selection = select_stage_a_combined_strategy( ...
    scenario.baseline, scenario.state, ...
    scenario.linked_right_shift, ...
    scenario.complete_reschedule_search, ...
    scenario.combination_config);
scenario.is_combination_evaluated = true;
end
