function scenario = run_stage_c_sequential_reschedule_operators(stage16)
%RUN_STAGE_C_SEQUENTIAL_RESCHEDULE_OPERATORS Build Stage C Step 16.3a.
%   Initialize and vary one restricted population. This entry does not
%   evaluate fitness or run iterative search.

if nargin < 1
    stage16 = run_stage_c_sequential_frozen_problem();
end
if stage16.step ~= 16 || ~strcmp(stage16.substep, '16.1') || ...
        ~stage16.is_validated
    error('run_stage_c_sequential_reschedule_operators:InvalidInput', ...
        'A validated Stage C Step 16.1 scenario is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

currentView = stage16.next_fault_state.current_plan_view;
frozen = stage16.sequential_frozen_problem;
seedDecision = build_stage_a_baseline_seed_decision( ...
    currentView, frozen);
rng(stage16.baseline.seed);

config = struct( ...
    'population_size', 6, ...
    'crossover_probability', 0.8, ...
    'mutation_probability', 0.2, ...
    'random_seed', stage16.baseline.seed);
population = initialize_stage_a_reschedule_population( ...
    currentView, frozen, config.population_size, seedDecision);
offspring = vary_stage_a_reschedule_population( ...
    population, currentView, frozen, ...
    config.crossover_probability, config.mutation_probability);

scenario = stage16;
scenario.sequential_operator_config = config;
scenario.sequential_operator_population = population;
scenario.sequential_operator_offspring = offspring;
scenario.step = 16;
scenario.substep = '16.3a';
scenario.is_operator_contract_built = true;
scenario.is_fitness_evaluated = false;
scenario.is_search_executed_in_step_16 = false;
scenario.is_combination_evaluated = false;
end
