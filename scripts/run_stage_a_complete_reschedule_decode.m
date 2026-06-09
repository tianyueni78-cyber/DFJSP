function scenario = run_stage_a_complete_reschedule_decode()
%RUN_STAGE_A_COMPLETE_RESCHEDULE_DECODE Decode one source-data seed.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

scenario = run_stage_a_frozen_problem();
scenario.complete_reschedule_seed = ...
    build_stage_a_baseline_seed_decision( ...
    scenario.baseline, scenario.frozen_problem);
scenario.complete_reschedule_candidate = ...
    decode_stage_a_complete_reschedule( ...
    scenario.baseline, scenario.frozen_problem, ...
    scenario.complete_reschedule_seed);
scenario.is_search_executed = false;
scenario.is_complete_reschedule_decoded = true;
scenario.is_rescheduled = true;
end
