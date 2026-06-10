function scenario = run_stage_b_machine_right_shift(baseline)
%RUN_STAGE_B_MACHINE_RIGHT_SHIFT Build the Stage B machine-only candidate.
%   This entry writes the Step 3 projected delays into a copied machine
%   schedule. It does not adjust AGV tasks or run any search.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

if nargin < 1
    scenario = run_stage_b_impact_analysis();
else
    scenario = run_stage_b_impact_analysis(baseline);
end
scenario.machine_right_shift = build_stage_b_machine_right_shift( ...
    scenario.baseline, scenario.fault, scenario.state, ...
    scenario.resume_plan, scenario.impact);
scenario.step = 4;
scenario.is_machine_right_shift_built = true;
scenario.is_rescheduled = true;
scenario.is_agv_updated = false;
scenario.is_fully_validated = false;
scenario.is_validated = scenario.is_validated && ...
    scenario.machine_right_shift.is_machine_validated;
end
