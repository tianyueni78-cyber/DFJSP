function scenario = run_stage_b_complete_reschedule_decode(baseline)
%RUN_STAGE_B_COMPLETE_RESCHEDULE_DECODE Decode one Stage B source seed.
%   This entry performs no population search and writes no output files.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

if nargin < 1
    scenario = run_stage_b_frozen_problem();
else
    scenario = run_stage_b_frozen_problem(baseline);
end
scenario.complete_reschedule_seed = ...
    build_stage_a_baseline_seed_decision( ...
    scenario.baseline, scenario.frozen_problem);
scenario.complete_reschedule_candidate = ...
    decode_stage_b_complete_reschedule( ...
    scenario.baseline, scenario.frozen_problem, ...
    scenario.complete_reschedule_seed);
scenario.step = 8;
scenario.is_search_executed = false;
scenario.is_complete_reschedule_decoded = true;
scenario.is_rescheduled = true;
scenario.is_validated = scenario.is_validated && ...
    scenario.complete_reschedule_candidate.is_validated;
end
