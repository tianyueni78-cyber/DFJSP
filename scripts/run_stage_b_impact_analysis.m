function scenario = run_stage_b_impact_analysis(baseline)
%RUN_STAGE_B_IMPACT_ANALYSIS Build the Stage B local impact set.
%   This entry calculates projected delays only. It does not write times
%   back to the machine table, adjust AGVs, or run search.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'impact'));

if nargin < 1
    scenario = run_stage_b_resume_rule();
else
    scenario = run_stage_b_resume_rule(baseline);
end
scenario.impact = identify_stage_b_affected_operations( ...
    scenario.baseline, scenario.state, scenario.resume_plan);
scenario.step = 3;
scenario.is_impact_identified = true;
scenario.successor_propagation_executed = true;
scenario.is_rescheduled = false;
scenario.is_validated = scenario.is_validated && ...
    scenario.impact.is_validated;
end
