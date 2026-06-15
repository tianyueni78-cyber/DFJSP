function scenario = run_stage_c_plan_version_history(stage11)
%RUN_STAGE_C_PLAN_VERSION_HISTORY Build Stage C Step 12 version chain.
%   This entry records the selected simultaneous-fault result as V1.
%   It does not create or process a second fault event.

if nargin < 1
    stage11 = run_stage_c_combination_contract();
end
if ~isfield(stage11, 'combined_selection') || ...
        stage11.step ~= 11 || ~stage11.is_validated
    error('run_stage_c_plan_version_history:InvalidInput', ...
        'A validated Stage C Step 11 result is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'src', 'state'));

history = initialize_stage_c_plan_history(stage11.baseline);
history = append_stage_c_plan_version( ...
    history, stage11.combined_selection.selected_candidate, ...
    stage11.faults, stage11.combined_selection.selected_strategy);

scenario = stage11;
scenario.plan_version_history = history;
scenario.active_plan_version = resolve_stage_c_active_plan( ...
    history, stage11.faults(1).start_time);
scenario.step = 12;
scenario.is_event_replay_initialized = true;
scenario.is_next_fault_processed = false;
scenario.is_search_executed_in_step_12 = false;
scenario.is_validated = scenario.is_validated && ...
    history.is_validated && ...
    scenario.active_plan_version.version_id == ...
    history.current_version_id;
end
