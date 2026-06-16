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
addpath(fullfile(projectRoot, 'src', 'state'));

stage13 = ensure_effective_next_fault(stage13);
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

function stage13 = ensure_effective_next_fault(stage13)
currentImpact = identify_stage_c_simultaneous_affected_operations( ...
    stage13.next_fault_state.current_plan_view, ...
    stage13.next_fault_state.state, stage13.next_fault);
if currentImpact.counts.affected_total > 0
    stage13.next_fault_screening.step_14_selection_reason = ...
        'stage_13_selected_fault_has_propagated_impact';
    stage13.next_fault_screening.step_14_selected_candidate_rank = 1;
    return
end

candidates = stage13.next_fault_screening.candidates;
impactCounts = zeros(1, numel(candidates));
for index = 1:numel(candidates)
    [candidateFault, candidateState] = build_candidate_state( ...
        stage13, candidates(index));
    candidateImpact = identify_stage_c_simultaneous_affected_operations( ...
        candidateState.current_plan_view, candidateState.state, ...
        candidateFault);
    impactCounts(index) = candidateImpact.counts.affected_total;
    if impactCounts(index) > 0
        stage13.next_fault = candidateFault;
        stage13.next_fault_state = candidateState;
        stage13.next_fault_screening.selected_candidate = ...
            candidates(index);
        stage13.next_fault_screening.step_14_selection_reason = ...
            'stage_13_selected_fault_zero_impact_use_first_effective';
        stage13.next_fault_screening.step_14_selected_candidate_rank = ...
            index;
        stage13.next_fault_screening.step_14_candidate_impact_counts = ...
            impactCounts;
        stage13.is_validated = stage13.is_validated && ...
            candidateState.is_validated;
        return
    end
end

stage13.next_fault_screening.step_14_candidate_impact_counts = ...
    impactCounts;
error('run_stage_c_sequential_impact_context:NoEffectiveNextFault', ...
    'No later fault candidate produces propagated impact on the current plan.');
end

function [fault, state] = build_candidate_state(stage13, candidate)
raw = struct();
raw.event_id = max([stage13.faults.event_id]) + 1;
raw.machine_id = candidate.machine_id;
raw.start_time = candidate.fault_time;
raw.repair_duration = candidate.repair_duration;
raw.interruption_rule = stage13.next_fault.interruption_rule;
fault = normalize_stage_c_fault_events( ...
    raw, stage13.baseline.problem.machineNum);
fault.event_group = max([stage13.faults.event_group]) + 1;
state = extract_stage_c_sequential_fault_state( ...
    stage13.baseline, stage13.plan_version_history, ...
    stage13.faults, fault);
end
