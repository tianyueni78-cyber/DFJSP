function scenario = run_stage_c_simultaneous_agv_linked_right_shift(baseline)
%RUN_STAGE_C_SIMULTANEOUS_AGV_LINKED_RIGHT_SHIFT Build Stage C Step 8.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

if nargin < 1
    scenario = run_stage_c_simultaneous_agv_impact_analysis();
else
    scenario = run_stage_c_simultaneous_agv_impact_analysis(baseline);
end
scenario.linked_right_shift = ...
    build_stage_c_simultaneous_agv_linked_right_shift( ...
    scenario.baseline, scenario.faults, ...
    scenario.machine_right_shift, scenario.agv_impact);
scenario.step = 8;
scenario.is_agv_rescheduled = true;
scenario.is_agv_updated = ...
    scenario.linked_right_shift.is_agv_updated;
scenario.is_fully_validated = true;
scenario.is_validated = scenario.is_validated && ...
    scenario.linked_right_shift.is_fully_validated;
end
