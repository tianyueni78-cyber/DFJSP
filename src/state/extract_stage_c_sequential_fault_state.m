function result = extract_stage_c_sequential_fault_state( ...
        baseline, history, previousFaults, nextFault)
%EXTRACT_STAGE_C_SEQUENTIAL_FAULT_STATE Extract Step 13 from active version.

if nargin < 4
    error('extract_stage_c_sequential_fault_state:MissingInput', ...
        'baseline, history, previousFaults, and nextFault are required.');
end
activeVersion = resolve_stage_c_active_plan( ...
    history, nextFault.start_time);
currentView = build_stage_c_current_plan_view(baseline, activeVersion);
state = extract_stage_c_event_group_state( ...
    currentView, nextFault, nextFault.event_group);
activePreviousRepairs = previousFaults( ...
    [previousFaults.repair_end_time] > nextFault.start_time + 1e-9);

result = struct();
result.stage = 'C';
result.step = 13;
result.input_version_id = activeVersion.version_id;
result.current_plan_view = currentView;
result.next_fault = nextFault;
result.state = state;
result.active_previous_repairs = activePreviousRepairs;
result.active_previous_repair_count = numel(activePreviousRepairs);
result.history_unchanged = true;
result.is_impact_propagated = false;
result.is_plan_modified = false;
result.is_validated = state.is_validated && ...
    state.counts.fault_in_progress_operations == 1 && ...
    abs(state.snapshot_time - nextFault.start_time) <= 1e-9 && ...
    currentView.source_version_id == activeVersion.version_id;
end
