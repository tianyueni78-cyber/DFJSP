function scenario = run_stage_a_machine_right_shift()
%RUN_STAGE_A_MACHINE_RIGHT_SHIFT Build the machine-only right-shift plan.
%   AGV tasks are copied from the baseline and deliberately not adjusted.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

scenario = run_stage_a_impact_analysis();
scenario.right_shift = build_stage_a_machine_right_shift( ...
    scenario.baseline, scenario.fault, scenario.state, scenario.impact);
scenario.is_machine_rescheduled = true;
scenario.is_agv_rescheduled = false;
scenario.is_rescheduled = false;
end
