function scenario = run_stage_cseq2_restricted_search_contract(stage7)
%RUN_STAGE_CSEQ2_RESTRICTED_SEARCH_CONTRACT Build C-SEQ2 Step 10.
%   Run a 6-by-2 light search contract only, not a formal experiment.

if nargin < 1
    stage7 = run_stage_cseq2_frozen_problem();
end
if ~strcmp(stage7.step, 'C-SEQ2.7') || ~stage7.is_validated
    error('run_stage_cseq2_restricted_search_contract:InvalidInput', ...
        'A validated C-SEQ2 Step 7 scenario is required.');
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

currentView = stage7.next_fault_state.current_plan_view;
coreFrozen = cseq2_core_frozen(stage7.cseq2_frozen_problem);
rng(stage7.baseline.seed);
search = search_stage_c_simultaneous_complete_reschedule( ...
    currentView, coreFrozen, options);
search.stage = 'C-SEQ2';
search.cumulative_unavailability = ...
    stage7.cseq2_frozen_problem.cumulative_unavailability;
search.overlap_relationships = ...
    stage7.cseq2_frozen_problem.overlap_relationships;
search.active_previous_repairs = ...
    stage7.cseq2_frozen_problem.active_previous_repairs;
search.is_cseq2_search_contract = true;

scenario = stage7;
scenario.cseq2_restricted_search = search;
scenario.step = 'C-SEQ2.10';
scenario.substep = '10';
scenario.is_operator_contract_built = true;
scenario.is_fitness_evaluated = true;
scenario.is_search_executed_in_cseq2_step_10 = true;
scenario.is_full_experiment = false;
scenario.is_combination_evaluated = false;
scenario.is_validated = scenario.is_validated && search.is_validated;
end

function frozen = cseq2_core_frozen(frozen)
frozen.stage = 'C';
frozen.step = 9;
end
