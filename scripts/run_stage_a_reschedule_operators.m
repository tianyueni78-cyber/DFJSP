function scenario = run_stage_a_reschedule_operators()
%RUN_STAGE_A_RESCHEDULE_OPERATORS Build and vary a small population.
%   This entry tests operators only. It does not evaluate fitness or run
%   NSGA-II generations.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

scenario = run_stage_a_frozen_problem();
seedDecision = build_stage_a_baseline_seed_decision( ...
    scenario.baseline, scenario.frozen_problem);

rng(scenario.baseline.seed);
scenario.operator_population = ...
    initialize_stage_a_reschedule_population( ...
    scenario.baseline, scenario.frozen_problem, 6, seedDecision);
scenario.operator_offspring = ...
    vary_stage_a_reschedule_population( ...
    scenario.operator_population, scenario.baseline, ...
    scenario.frozen_problem, 0.8, 0.2);
scenario.is_search_executed = false;
scenario.is_operator_contract_built = true;
scenario.is_rescheduled = false;
end
