function scenario = run_stage_c_sequential_agv_linked_right_shift(stage14)
%RUN_STAGE_C_SEQUENTIAL_AGV_LINKED_RIGHT_SHIFT Build Stage C Step 15.
%   The selected current plan is shifted for the next fault, then AGV
%   activities are adjusted by the existing Stage C coupling rules.

if nargin < 1
    stage14 = run_stage_c_sequential_impact_context();
end
if stage14.step ~= 14 || ~stage14.is_validated
    error('run_stage_c_sequential_agv_linked_right_shift:InvalidInput', ...
        'A validated Stage C Step 14 scenario is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'src', 'impact'));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

currentView = stage14.next_fault_state.current_plan_view;
nextFault = stage14.next_fault;
state = stage14.next_fault_state.state;
impact = stage14.sequential_impact_context.new_event_impact;
impact.affected_operations = ...
    stage14.sequential_impact_context.merged_affected_operations;
impact.unaffected_unstarted_operations = ...
    stage14.sequential_impact_context.unaffected_unstarted_operations;
impact.counts.affected_total = numel(impact.affected_operations);
impact.counts.unaffected_unstarted = ...
    numel(impact.unaffected_unstarted_operations);
impact.counts.multi_source_operations = ...
    sum([impact.affected_operations.source_count] > 1);

machineCandidate = build_stage_c_simultaneous_machine_right_shift( ...
    currentView, nextFault, state, impact);
agvImpact = analyze_stage_c_simultaneous_agv_impact( ...
    currentView, nextFault, machineCandidate);
linkedCandidate = build_stage_c_simultaneous_agv_linked_right_shift( ...
    currentView, nextFault, machineCandidate, agvImpact);

scenario = stage14;
scenario.sequential_machine_right_shift = machineCandidate;
scenario.sequential_agv_impact = agvImpact;
scenario.sequential_linked_right_shift = linkedCandidate;
scenario.step = 15;
scenario.is_machine_right_shift_built = true;
scenario.is_agv_impact_identified = true;
scenario.is_agv_rescheduled = true;
scenario.is_fully_validated = linkedCandidate.is_fully_validated;
scenario.is_search_executed_in_step_15 = false;
scenario.is_plan_version_appended_in_step_15 = false;
scenario.is_validated = scenario.is_validated && ...
    machineCandidate.is_machine_validated && ...
    agvImpact.is_validated && linkedCandidate.is_fully_validated;
end
