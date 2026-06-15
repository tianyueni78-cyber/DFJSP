function scenario = run_stage_c_simultaneous_frozen_problem(baseline)
%RUN_STAGE_C_SIMULTANEOUS_FROZEN_PROBLEM Build Stage C Step 9.
%   This entry defines the complete-rescheduling boundary only.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

if nargin < 1
    scenario = run_stage_c_simultaneous_agv_linked_right_shift();
else
    scenario = run_stage_c_simultaneous_agv_linked_right_shift(baseline);
end
scenario.frozen_problem = build_stage_c_simultaneous_frozen_problem( ...
    scenario.baseline, scenario.faults, scenario.state, ...
    scenario.machine_right_shift.interrupted_commitments);
scenario.step = 9;
scenario.is_frozen_problem_built = true;
scenario.is_search_executed = false;
scenario.is_validated = scenario.is_validated && ...
    scenario.frozen_problem.is_validated;
end
