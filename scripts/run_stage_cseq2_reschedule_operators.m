function scenario = run_stage_cseq2_reschedule_operators(stage7)
%RUN_STAGE_CSEQ2_RESCHEDULE_OPERATORS Build C-SEQ2 Step 9.
%   Initialize and vary one restricted population. This entry does not
%   evaluate fitness or run iterative search.

if nargin < 1
    stage7 = run_stage_cseq2_frozen_problem();
end
if ~strcmp(stage7.step, 'C-SEQ2.7') || ~stage7.is_validated
    error('run_stage_cseq2_reschedule_operators:InvalidInput', ...
        'A validated C-SEQ2 Step 7 scenario is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

currentView = stage7.next_fault_state.current_plan_view;
frozen = stage7.cseq2_frozen_problem;
seedDecision = build_stage_a_baseline_seed_decision(currentView, frozen);
rng(stage7.baseline.seed);

config = struct( ...
    'population_size', 6, ...
    'crossover_probability', 0.8, ...
    'mutation_probability', 0.2, ...
    'random_seed', stage7.baseline.seed);
population = initialize_stage_a_reschedule_population( ...
    currentView, frozen, config.population_size, seedDecision);
offspring = vary_stage_a_reschedule_population( ...
    population, currentView, frozen, ...
    config.crossover_probability, config.mutation_probability);

scenario = stage7;
scenario.cseq2_operator_config = config;
scenario.cseq2_operator_population = population;
scenario.cseq2_operator_offspring = offspring;
scenario.step = 'C-SEQ2.9';
scenario.substep = '9';
scenario.is_operator_contract_built = true;
scenario.is_fitness_evaluated = false;
scenario.is_search_executed_in_cseq2_step_9 = false;
scenario.is_combination_evaluated = false;
end
