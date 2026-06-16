function scenario = run_stage_cs2_reschedule_operators(baseline)
%run_stage_cs2_reschedule_operators Build C-S2 Step 8.
%   This entry initializes one restricted population and applies one
%   crossover/mutation pass. It does not evaluate fitness or run search.

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

% Block 1: extract the source-data seed and fix the light-test RNG.
seedDecision = build_stage_a_baseline_seed_decision( ...
    scenario.baseline, scenario.cs2_frozen_problem);
rng(scenario.baseline.seed);
scenario.operator_config = struct( ...
    'population_size', 6, ...
    'crossover_probability', 0.8, ...
    'mutation_probability', 0.2, ...
    'random_seed', scenario.baseline.seed);

% Block 2: vary only released OS, MS, AS, and SS decisions.
scenario.operator_population = ...
    initialize_stage_a_reschedule_population( ...
    scenario.baseline, scenario.cs2_frozen_problem, ...
    scenario.operator_config.population_size, seedDecision);
scenario.operator_offspring = ...
    vary_stage_a_reschedule_population( ...
    scenario.operator_population, scenario.baseline, ...
    scenario.cs2_frozen_problem, ...
    scenario.operator_config.crossover_probability, ...
    scenario.operator_config.mutation_probability);

scenario.step = 'C-S2.8';
scenario.substep = '8';
scenario.is_operator_contract_built = true;
scenario.is_fitness_evaluated = false;
scenario.is_search_executed = false;
scenario.is_rescheduled = false;
end
