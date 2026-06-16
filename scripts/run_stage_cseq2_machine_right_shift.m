function scenario = run_stage_cseq2_machine_right_shift(stage3)
%RUN_STAGE_CSEQ2_MACHINE_RIGHT_SHIFT Build C-SEQ2 Step 4.
%   A machine-only partial right-shift candidate is generated with both
%   historical and new repair intervals retained.

if nargin < 1
    stage3 = run_stage_cseq2_impact_context();
end
if ~strcmp(stage3.step, 'C-SEQ2.3') || ~stage3.is_validated
    error('run_stage_cseq2_machine_right_shift:InvalidInput', ...
        'A validated C-SEQ2 Step 3 scenario is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

currentView = stage3.next_fault_state.current_plan_view;
state = stage3.next_fault_state.state;
impact = stage3.cseq2_impact_context.new_event_impact;
impact.affected_operations = ...
    stage3.cseq2_impact_context.merged_affected_operations;
impact.unaffected_unstarted_operations = ...
    stage3.cseq2_impact_context.unaffected_unstarted_operations;
impact.counts.affected_total = numel(impact.affected_operations);
impact.counts.unaffected_unstarted = ...
    numel(impact.unaffected_unstarted_operations);
impact.counts.multi_source_operations = ...
    sum([impact.affected_operations.source_count] > 1);
impact.stage = 'C';
impact.step = 5;
impact.baseline_modified = false;
impact.is_rescheduled = false;
impact.is_validated = true;

machineCandidate = build_stage_c_simultaneous_machine_right_shift( ...
    currentView, stage3.next_fault, state, impact);
machineCandidate.stage = 'C-SEQ2';
machineCandidate.step = '4';
machineCandidate.cumulative_unavailability = ...
    stage3.cseq2_impact_context.cumulative_unavailability;
machineCandidate.overlap_relationships = ...
    stage3.cseq2_impact_context.overlap_relationships;
machineCandidate.history_unchanged = true;
machineCandidate.is_plan_modified = false;
machineCandidate.is_rescheduled = false;
machineCandidate.is_validated = machineCandidate.is_machine_validated && ...
    validate_candidate(machineCandidate, stage3);

scenario = stage3;
scenario.cseq2_machine_right_shift = machineCandidate;
scenario.step = 'C-SEQ2.4';
scenario.substep = '4';
scenario.is_machine_right_shift_built = true;
scenario.is_agv_impact_identified = false;
scenario.is_agv_rescheduled = false;
scenario.is_search_executed_in_cseq2_step_4 = false;
scenario.is_validated = scenario.is_validated && ...
    machineCandidate.is_validated;
end

function result = validate_candidate(candidate, stage3)
result = candidate.is_machine_validated && ...
    ~candidate.is_agv_updated && ~candidate.is_agv_validated && ...
    ~candidate.is_fully_validated && candidate.history_unchanged && ...
    ~candidate.is_plan_modified && ~candidate.is_rescheduled && ...
    numel(candidate.unavailable_intervals) == 1 && ...
    candidate.cumulative_unavailability.is_validated && ...
    candidate.cumulative_unavailability.fault_count == ...
    stage3.cseq2_impact_context.counts.cumulative_faults;
if ~result
    error('run_stage_cseq2_machine_right_shift:InvalidCandidate', ...
        'C-SEQ2 machine right-shift candidate failed validation.');
end
end
