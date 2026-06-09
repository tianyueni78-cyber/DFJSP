function scenario = run_stage_a_impact_analysis()
%RUN_STAGE_A_IMPACT_ANALYSIS Identify Stage A affected operations.
%   This entry creates an unavailable interval and an impact set only. It
%   does not write projected times back to the baseline or reschedule.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'impact'));

scenario = run_stage_a_state_snapshot();
scenario.impact = identify_stage_a_affected_operations( ...
    scenario.baseline, scenario.fault, scenario.state);
scenario.is_impact_identified = true;
scenario.is_rescheduled = false;
end
