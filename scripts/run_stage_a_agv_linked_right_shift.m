function scenario = run_stage_a_agv_linked_right_shift()
%RUN_STAGE_A_AGV_LINKED_RIGHT_SHIFT Build the AGV-linked right-shift plan.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

scenario = run_stage_a_agv_impact_analysis();
scenario.linked_right_shift = build_stage_a_agv_linked_right_shift( ...
    scenario.baseline, scenario.fault, scenario.right_shift, ...
    scenario.agv_impact);
scenario.is_agv_rescheduled = true;
scenario.is_rescheduled = true;
end
