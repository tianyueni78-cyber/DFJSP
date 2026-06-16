function scenario = run_stage_c_sequential_complete_reschedule_decode( ...
        stage16)
%RUN_STAGE_C_SEQUENTIAL_COMPLETE_RESCHEDULE_DECODE Build Stage C Step 16.2.
%   Decode one baseline-seed candidate only. This entry does not run
%   population search or combination selection.

if nargin < 1
    stage16 = run_stage_c_sequential_frozen_problem();
end
if stage16.step ~= 16 || ~strcmp(stage16.substep, '16.1') || ...
        ~stage16.is_validated
    error('run_stage_c_sequential_complete_reschedule_decode:InvalidInput', ...
        'A validated Stage C Step 16.1 scenario is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));
addpath(fullfile(projectRoot, 'src', 'scheduling'));

currentView = stage16.next_fault_state.current_plan_view;
decision = build_stage_a_baseline_seed_decision( ...
    currentView, stage16.sequential_frozen_problem);
candidate = decode_stage_c_simultaneous_complete_reschedule( ...
    currentView, stage16.sequential_frozen_problem, decision);

scenario = stage16;
scenario.sequential_complete_reschedule_decision = decision;
scenario.sequential_complete_reschedule_candidate = candidate;
scenario.step = 16;
scenario.substep = '16.2';
scenario.is_complete_reschedule_decoded = true;
scenario.is_search_executed_in_step_16 = false;
scenario.is_combination_evaluated = false;
scenario.is_validated = scenario.is_validated && candidate.is_validated;
end
