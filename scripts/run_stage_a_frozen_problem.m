function scenario = run_stage_a_frozen_problem()
%RUN_STAGE_A_FROZEN_PROBLEM Build the complete-rescheduling boundary only.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));

addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

scenario = run_stage_a_state_snapshot();
scenario.frozen_problem = build_stage_a_frozen_problem( ...
    scenario.baseline, scenario.fault, scenario.state);
scenario.is_frozen_problem_built = true;
scenario.is_search_executed = false;
scenario.is_rescheduled = false;
end
