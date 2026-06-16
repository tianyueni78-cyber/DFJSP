function scenario = run_stage_cs2_complete_reschedule_decode( ...
        baseline)
%run_stage_cs2_complete_reschedule_decode Build C-S2 Step 7.
%   This entry decodes one source-data seed only. It does not run search.

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
decision = build_stage_a_baseline_seed_decision( ...
    scenario.baseline, scenario.cs2_frozen_problem);
scenario.complete_reschedule_decision = decision;
scenario.complete_reschedule_candidate = ...
    decode_stage_cs2_complete_reschedule( ...
    scenario.baseline, scenario.cs2_frozen_problem, decision);
scenario.step = 'C-S2.7';
scenario.substep = '7';
scenario.is_complete_reschedule_decoded = true;
scenario.is_search_executed = false;
scenario.is_validated = scenario.is_validated && ...
    scenario.complete_reschedule_candidate.is_validated;
end

