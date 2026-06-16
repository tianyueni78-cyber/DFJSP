function scenario = run_stage_c_sequential_frozen_problem(stage15)
%RUN_STAGE_C_SEQUENTIAL_FROZEN_PROBLEM Build Stage C Step 16.1.
%   This entry defines the complete-rescheduling boundary for the
%   sequential next fault only. It does not decode or search candidates.

if nargin < 1
    stage15 = run_stage_c_sequential_agv_linked_right_shift();
end
if stage15.step ~= 15 || ~stage15.is_validated
    error('run_stage_c_sequential_frozen_problem:InvalidInput', ...
        'A validated Stage C Step 15 scenario is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

currentView = stage15.next_fault_state.current_plan_view;
frozen = build_stage_c_simultaneous_frozen_problem( ...
    currentView, stage15.next_fault, ...
    stage15.next_fault_state.state, ...
    stage15.sequential_machine_right_shift.interrupted_commitments);

scenario = stage15;
scenario.sequential_frozen_problem = frozen;
scenario.step = 16;
scenario.substep = '16.1';
scenario.is_frozen_problem_built = true;
scenario.is_complete_reschedule_decoded = false;
scenario.is_search_executed_in_step_16 = false;
scenario.is_combination_evaluated = false;
scenario.is_validated = scenario.is_validated && frozen.is_validated;
end
