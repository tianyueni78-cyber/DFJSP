function scenario = run_stage_a_complete_energy_contract()
%RUN_STAGE_A_COMPLETE_ENERGY_CONTRACT Decode one fully evaluated seed.
%   This entry does not run the search loop.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

scenario = run_stage_a_frozen_problem();
decision = build_stage_a_baseline_seed_decision( ...
    scenario.baseline, scenario.frozen_problem);
scenario.complete_energy_candidate = ...
    decode_stage_a_complete_reschedule( ...
    scenario.baseline, scenario.frozen_problem, decision);
scenario.is_search_executed = false;
scenario.is_full_energy_evaluated = true;
scenario.is_rescheduled = true;
end
