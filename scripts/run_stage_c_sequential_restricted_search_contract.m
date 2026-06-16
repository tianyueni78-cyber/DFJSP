function scenario = run_stage_c_sequential_restricted_search_contract( ...
        stage16)
%RUN_STAGE_C_SEQUENTIAL_RESTRICTED_SEARCH_CONTRACT Build Stage C Step 16.3b.
%   Run a 6-by-2 light search contract only, not a formal experiment.

if nargin < 1
    stage16 = run_stage_c_sequential_frozen_problem();
end
if stage16.step ~= 16 || ~strcmp(stage16.substep, '16.1') || ...
        ~stage16.is_validated
    error('run_stage_c_sequential_restricted_search_contract:InvalidInput', ...
        'A validated Stage C Step 16.1 scenario is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

options = struct();
options.population_size = 6;
options.generations = 2;
options.crossover_probability = 0.8;
options.mutation_probability = 0.2;
options.tournament_size = 2;

currentView = stage16.next_fault_state.current_plan_view;
rng(stage16.baseline.seed);
search = search_stage_c_simultaneous_complete_reschedule( ...
    currentView, stage16.sequential_frozen_problem, options);

scenario = stage16;
scenario.sequential_restricted_search = search;
scenario.step = 16;
scenario.substep = '16.3b';
scenario.is_operator_contract_built = true;
scenario.is_fitness_evaluated = true;
scenario.is_search_executed_in_step_16 = true;
scenario.is_full_experiment = false;
scenario.is_combination_evaluated = false;
scenario.is_validated = scenario.is_validated && search.is_validated;
end
