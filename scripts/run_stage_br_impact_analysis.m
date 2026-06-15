function scenario = run_stage_br_impact_analysis(baseline)
%RUN_STAGE_BR_IMPACT_ANALYSIS Build the restart-rule impact set.
%   This entry calculates projected delays only. It does not write times
%   back to machine tables, adjust AGVs, or run a search.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'impact'));

if nargin < 1
    scenario = run_stage_br_restart_rule();
else
    scenario = run_stage_br_restart_rule(baseline);
end
scenario.impact = identify_stage_br_affected_operations( ...
    scenario.baseline, scenario.state, scenario.restart_plan);
scenario.step = 2;
scenario.is_impact_identified = true;
scenario.successor_propagation_executed = true;
scenario.is_rescheduled = false;
scenario.is_validated = scenario.is_validated && ...
    scenario.impact.is_validated;
end
