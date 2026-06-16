function scenario = run_stage_cs2_frozen_problem(baseline)
%RUN_STAGE_CS2_FROZEN_PROBLEM Build C-S2 Step 6.
%   This entry defines the complete-rescheduling boundary only.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

if nargin < 1
    scenario = run_stage_cs2_agv_linked_right_shift();
else
    scenario = run_stage_cs2_agv_linked_right_shift(baseline);
end
scenario.cs2_frozen_problem = build_stage_cs2_frozen_problem( ...
    scenario.baseline, scenario.faults, scenario.state, ...
    scenario.cs2_restart_commitments);
scenario.step = 'C-S2.6';
scenario.is_frozen_problem_built = true;
scenario.is_search_executed = false;
scenario.is_validated = scenario.is_validated && ...
    scenario.cs2_frozen_problem.is_validated;
if ~scenario.is_validated
    error('run_stage_cs2_frozen_problem:InvalidScenario', ...
        'C-S2 frozen problem is inconsistent.');
end
end
