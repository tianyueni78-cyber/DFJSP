function scenario = run_stage_a_step_13_contract()
%RUN_STAGE_A_STEP_13_CONTRACT Run a lightweight search and selection.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'configs'));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));
require_scheduling_dependency();

normalScenario = contract_normal_scenario();
stage12 = run_stage_a_rebuilt_rescheduling_chain(normalScenario);
options = struct();
options.population_size = 6;
options.generations = 2;
options.crossover_probability = 0.8;
options.mutation_probability = 0.2;
options.tournament_size = 2;
options.no_improvement_generations = Inf;
options.max_runtime_seconds = Inf;
options.improvement_tolerance = 1e-9;

rng(stage12.baseline.seed);
search = search_stage_a_complete_reschedule( ...
    stage12.baseline, stage12.frozen_problem, options);
combination = select_stage_a_combined_strategy( ...
    stage12.baseline, stage12.state, ...
    stage12.linked_right_shift, search, ...
    stage_a_combination_config());

scenario = stage12;
scenario.step = 13;
scenario.complete_reschedule_search = search;
scenario.combined_selection = combination;
scenario.is_search_executed = true;
scenario.is_combination_evaluated = true;
scenario.is_contract_run = true;
scenario.is_formal_run = false;
scenario.is_validated = stage12.is_validated && ...
    search.is_validated && ...
    combination.is_validated;
end

function require_scheduling_dependency()
if exist('spare_transfer_time_compute', 'file') ~= 2
    error('run_stage_a_step_13_contract:SchedulingDependency', ...
        'spare_transfer_time_compute must be available during search.');
end
end

function scenario = contract_normal_scenario()
baseline = run_normal_schedule_baseline();
scenario = struct();
scenario.optimized_baseline = baseline;
scenario.normal_search = struct('is_validated', true);
scenario.is_source_data_only = true;
scenario.is_fault_free = true;
end
