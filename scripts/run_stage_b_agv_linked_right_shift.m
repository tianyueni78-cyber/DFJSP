function scenario = run_stage_b_agv_linked_right_shift(baseline)
%RUN_STAGE_B_AGV_LINKED_RIGHT_SHIFT Build the Stage B linked candidate.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

if nargin < 1
    scenario = run_stage_b_agv_impact_analysis();
else
    scenario = run_stage_b_agv_impact_analysis(baseline);
end
scenario.linked_right_shift = ...
    build_stage_b_agv_linked_right_shift( ...
    scenario.baseline, scenario.fault, ...
    scenario.machine_right_shift, scenario.agv_impact);
scenario.step = 6;
scenario.is_agv_rescheduled = true;
scenario.is_agv_updated = ...
    scenario.linked_right_shift.is_agv_updated;
scenario.is_fully_validated = true;
scenario.is_validated = scenario.is_validated && ...
    scenario.linked_right_shift.is_fully_validated;
end
