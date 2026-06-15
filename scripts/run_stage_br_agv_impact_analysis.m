function scenario = run_stage_br_agv_impact_analysis(baseline)
%RUN_STAGE_BR_AGV_IMPACT_ANALYSIS Identify transports needing adjustment.
%   This entry analyzes the restart-rule machine candidate without
%   modifying AGV times, routes, assignments, charging, or energy.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'impact'));

if nargin < 1
    scenario = run_stage_br_machine_right_shift();
else
    scenario = run_stage_br_machine_right_shift(baseline);
end
scenario.agv_impact = analyze_stage_br_agv_impact( ...
    scenario.baseline, scenario.fault, ...
    scenario.machine_right_shift);
scenario.step = 4;
scenario.is_agv_impact_identified = true;
scenario.is_agv_updated = false;
scenario.is_fully_validated = false;
scenario.is_validated = scenario.is_validated && ...
    scenario.agv_impact.is_validated;
end
