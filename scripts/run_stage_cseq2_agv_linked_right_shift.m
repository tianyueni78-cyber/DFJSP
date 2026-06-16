function scenario = run_stage_cseq2_agv_linked_right_shift(stage5)
%RUN_STAGE_CSEQ2_AGV_LINKED_RIGHT_SHIFT Build C-SEQ2 Step 6.
%   AGV activities are adjusted for the new overlapping fault while the
%   cumulative historical repair context is retained for later audits.

if nargin < 1
    stage5 = run_stage_cseq2_agv_impact_analysis();
end
if ~strcmp(stage5.step, 'C-SEQ2.5') || ~stage5.is_validated
    error('run_stage_cseq2_agv_linked_right_shift:InvalidInput', ...
        'A validated C-SEQ2 Step 5 scenario is required.');
end

projectRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, 'src', 'rescheduling'));

coreMachine = stage5.cseq2_machine_right_shift;
coreMachine.stage = 'C';
coreMachine.step = 6;
coreImpact = stage5.cseq2_agv_impact;
coreImpact.stage = 'C';
coreImpact.step = 7;
linkedCandidate = build_stage_c_simultaneous_agv_linked_right_shift( ...
    stage5.next_fault_state.current_plan_view, ...
    stage5.next_fault, coreMachine, coreImpact);
linkedCandidate.stage = 'C-SEQ2';
linkedCandidate.step = '6';
linkedCandidate.cumulative_unavailability = ...
    stage5.cseq2_impact_context.cumulative_unavailability;
linkedCandidate.overlap_relationships = ...
    stage5.cseq2_impact_context.overlap_relationships;
linkedCandidate.history_unchanged = true;
linkedCandidate.is_plan_modified = false;
linkedCandidate.is_rescheduled = true;
linkedCandidate.is_validated = linkedCandidate.is_fully_validated && ...
    validate_candidate(linkedCandidate, stage5);

scenario = stage5;
scenario.cseq2_linked_right_shift = linkedCandidate;
scenario.step = 'C-SEQ2.6';
scenario.substep = '6';
scenario.is_agv_rescheduled = true;
scenario.is_fully_validated = linkedCandidate.is_fully_validated;
scenario.is_search_executed_in_cseq2_step_6 = false;
scenario.is_plan_version_appended_in_cseq2_step_6 = false;
scenario.is_validated = scenario.is_validated && ...
    linkedCandidate.is_validated;
end

function result = validate_candidate(candidate, stage5)
result = candidate.is_machine_validated && candidate.is_agv_validated && ...
    candidate.is_fully_validated && candidate.history_unchanged && ...
    ~candidate.is_plan_modified && candidate.is_rescheduled && ...
    candidate.cumulative_unavailability.is_validated && ...
    numel(candidate.overlap_relationships) == ...
    stage5.cseq2_impact_context.counts.overlap_relationships && ...
    candidate.agv_impact_required_adjustment == ...
    stage5.cseq2_agv_impact.requires_agv_adjustment;
if ~result
    error('run_stage_cseq2_agv_linked_right_shift:InvalidCandidate', ...
        'C-SEQ2 AGV-linked right-shift candidate failed validation.');
end
end
