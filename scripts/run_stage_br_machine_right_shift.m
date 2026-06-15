function scenario = run_stage_br_machine_right_shift(baseline)
%RUN_STAGE_BR_MACHINE_RIGHT_SHIFT Build the machine-only restart candidate.
%   This entry writes Stage B-R Step 2 projected times into a copied
%   machine schedule. It does not adjust AGV tasks or run a search.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

if nargin < 1
    scenario = run_stage_br_impact_analysis();
else
    scenario = run_stage_br_impact_analysis(baseline);
end
scenario.machine_right_shift = build_stage_br_machine_right_shift( ...
    scenario.baseline, scenario.fault, scenario.state, ...
    scenario.restart_plan, scenario.impact);
scenario.step = 3;
scenario.is_machine_right_shift_built = true;
scenario.is_rescheduled = true;
scenario.is_agv_updated = false;
scenario.is_fully_validated = false;
scenario.is_validated = scenario.is_validated && ...
    scenario.machine_right_shift.is_machine_validated;
end
