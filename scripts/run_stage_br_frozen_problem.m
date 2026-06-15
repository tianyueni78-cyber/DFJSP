function scenario = run_stage_br_frozen_problem(baseline)
%RUN_STAGE_BR_FROZEN_PROBLEM Build the Stage B-R complete-search boundary.
%   This entry does not decode candidates or run a search.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

if nargin < 1
    scenario = run_stage_br_agv_linked_right_shift();
else
    scenario = run_stage_br_agv_linked_right_shift(baseline);
end
scenario.frozen_problem = build_stage_br_frozen_problem( ...
    scenario.baseline, scenario.fault, scenario.state, ...
    scenario.restart_plan);
scenario.step = 6;
scenario.is_frozen_problem_built = true;
scenario.is_search_executed = false;
scenario.is_validated = scenario.is_validated && ...
    scenario.frozen_problem.is_validated;
end

