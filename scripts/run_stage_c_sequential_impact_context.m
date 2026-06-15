function scenario = run_stage_c_sequential_impact_context(stage13)
%RUN_STAGE_C_SEQUENTIAL_IMPACT_CONTEXT Build Stage C Step 14.
%   This entry merges repair history and impact records only.

if nargin < 1
    stage13 = run_stage_c_next_fault_state();
end
if stage13.step ~= 13 || ~stage13.is_validated
    error('run_stage_c_sequential_impact_context:InvalidInput', ...
        'A validated Stage C Step 13 scenario is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'src', 'fault'));
addpath(fullfile(projectRoot, 'src', 'impact'));

context = build_stage_c_sequential_impact_context(stage13);
scenario = stage13;
scenario.sequential_impact_context = context;
scenario.step = 14;
scenario.is_impact_propagated = true;
scenario.is_cumulative_unavailability_built = true;
scenario.is_plan_modified_in_step_14 = false;
scenario.is_rescheduled_in_step_14 = false;
scenario.is_validated = scenario.is_validated && context.is_validated;
end
